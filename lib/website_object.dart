//////////////
// Author: Arya Jafari, Universiy of Toronto Mississauga
// Description: <Post> objects store gathered information and <Website> objects
//              store information about where/how to get said information
//////////////

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class Post {
  /// <Post> objects hold 3 bits of information which are used for displaying
  ///  as well as opening the post in a browser
  /// - the url to the image thumbnail (string)
  /// - the title of the post (string)
  /// - the link referenced by the post (string)

  final String imageUrl;
  // url to image
  final String title;
  // title of post
  final String linkUrl;
  // where the embedded url of the post references

  const Post({required this.title, required this.linkUrl, imageUrl})
      : imageUrl = imageUrl ?? "";

  factory Post.fromJson(Map j) {
    String titlef = j["title"];
    String linkUrlf = j["linkUrl"];
    String imageUrlf = j["imageUrl"];
    return Post(title: titlef, linkUrl: linkUrlf, imageUrl: imageUrlf);
  }

  Map<String, String> dump() {
    /// Return a map in json format that can be used to create the object
    /// Used when writing object to file
    return {"title": title, "linkUrl": linkUrl, "imageUrl": imageUrl};
  }

  @override
  bool operator ==(Object other) => other is Post && linkUrl == other.linkUrl;

  @override
  int get hashCode => linkUrl.hashCode;

  Future<void> urlLaunch() async {
    /// Launches <linkUrl> in the browser
    final Uri url = Uri.parse(linkUrl);
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw 'Could not launch $url';
    }
  }
}

abstract class Website {
  /// Handles API calls and information about the desired website
  /// object hold 4 bits of information:
  /// - the url of the website (string)
  /// - the name of the website (string)
  /// - previously shown posts (list<Post>)
  /// - whether the website should be getted for posts (bool)
  /// Since APIs differ depending on website, <Website> must be an abstract
  /// class with differing implementation depending on the host

  final String path;
  // url to website being searched
  final String name;
  // name of website
  bool load;
  // whether the results of the website will be displayed or not
  List<Post> prevPosts;

  Website(
      {required this.path,
      required this.name,
      required this.prevPosts,
      required this.load});

  Future<List<Post>> getPosts();

  List<Post> removeDuplicates(List<Post> posts) {
    /// remove elements from <posts> that occur in <prevPosts>
    /// redefine <prevPosts> to be equal ot <posts>

    // posts removed were shown before,
    final temp = List<Post>.from(posts);
    posts.removeWhere((element) => (prevPosts.contains(element)));

    // posts that were just displayed, might want to consider putting this in
    // .drop(), but we'll see
    prevPosts = temp;
    return posts;
  }

  Map<String, dynamic> dump() {
    /// Return a map in json format that can be used to create the object
    /// Used when writing object to file
    return {
      "name": name,
      "path": path,
      "previousPosts": _pPtoList(prevPosts),
      "load": load
    };
  }

  @override
  String toString() {
    /// Return a string representation of the object
    return {
      "name": name,
      "path": path,
      "previousPosts": _pPtoList(prevPosts),
      "load": load
    }.toString();
  }

  List<Map> _pPtoList(List<Post> prevPosts) {
    /// Returns <prevPosts> as a list of map objects. Map objects correspond
    /// to Posts.dump()
    List<Map> s = [];
    for (Post p in prevPosts) {
      s.add(p.dump());
    }
    return s;
  }
}

class RedditWebsite extends Website {
  /// Concrete implementation of <Website> which works for reddit.com

  // Reddit API calls require a header with a user-agent
  static const header = {'user-agent': 'Made by /u/IncendiaryLobotomy'};

  RedditWebsite(
      {required super.path,
      required super.name,
      required super.prevPosts,
      required super.load});
  // e.g of path in this context is: pcgiveaways/new.json?f=flair_name%3A"Gleam"
  // the ".json" is not automatically inserted because i didnt feel like it

  @override
  Future<List<Post>> getPosts() async {
    try {
      var posts = await http.get(Uri.parse("https://reddit.com/r/$path"),
          headers: header);
      if (posts.statusCode == 200) {
        var data = jsonDecode(posts.body)["data"];
        List<Post> postList = [];

        for (int i = 0; i < data["dist"]; i++) {
          var p = data["children"][i]["data"];
          if ((p["thumbnail"] ?? "default") == "default") {
            p["thumbnail"] = "";
          }
          postList.add(Post(
              title: p["title"], linkUrl: p["url"], imageUrl: p["thumbnail"]));
        }
        return removeDuplicates(postList);
      }
      // status code =! 200
      debugPrint("Failed to get posts from reddit/r/$path");
      debugPrint("Status code: ${posts.statusCode}");
      return const [];
    } catch (e) {
      debugPrint("Failed to get Posts from reddit/r/$path");
      debugPrint('Error(may be null): $e');
      return const [];
    }
  }
}

class GamerPowerWebsite extends Website {
  /// Concrete implementation of <Website> which works for gamerpower.com

  GamerPowerWebsite(
      {required super.path,
      required super.name,
      required super.prevPosts,
      required super.load});
  // path will always be https://www.gamerpower.com/giveaways,

  @override
  Future<List<Post>> getPosts() async {
    try {
      final siteHtml =
          await http.get(Uri.parse("https://www.gamerpower.com/giveaways"));

      if (siteHtml.statusCode == 200) {
        final posts = parse(siteHtml.body)
            .getElementsByClassName("card box-shadow shadow grow");
        List<Post> postList = [];

        for (int i = 0; i < posts.length; i++) {
          var p = posts[i].getElementsByTagName("a")[0];
          String url = """https://gamerpower.com${p.attributes["href"]}""";

          Map temp = p.getElementsByTagName("img")[0].attributes;
          String thumbnail = """https://gamerpower.com${temp["src"]}""";
          String title = temp["alt"]!;

          postList.add(Post(imageUrl: thumbnail, title: title, linkUrl: url));
        }
        return removeDuplicates(postList);
      }
    } catch (e) {
      // status code =! 200
      debugPrint("Failed to get posts from gamerpower");
    }
    return const [];
  }
}
