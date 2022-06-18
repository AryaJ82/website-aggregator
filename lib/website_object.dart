//////////////
// Author: Arya Jafari, Universiy of Toronto Mississauga
// Date of Last Update: June 8th, 2022 (08/06/22)
// Description: <Post> objects store gathered information and <Website> objects
//              store information about where/how to get said information
//////////////

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class Post {
  final String imageUrl;
  // url to image
  final String title;
  // title of post
  final String linkUrl;
  // where the post references

  const Post({required this.title, required this.linkUrl, imageUrl})
      : imageUrl = imageUrl ?? "";

  factory Post.fromJson(Map j) {
    String titlef = j["title"];
    String linkUrlf = j["linkUrl"];
    String imageUrlf = j["imageUrl"];
    return Post(title: titlef, linkUrl: linkUrlf, imageUrl: imageUrlf);
  }

  Map dump() {
    return {"title": title, "linkUrl": linkUrl, "imageUrl": imageUrl};
  }

  @override
  bool operator ==(Object other) => other is Post && linkUrl == other.linkUrl;

  @override
  int get hashCode => linkUrl.hashCode;

  Future<void> urlLaunch() async {
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
    // remove elements from <prevPosts> that are not in <posts> and elements
    // from <posts> that occur in <prevPosts>

    // posts removed were shown before,
    final temp = List<Post>.from(posts);
    posts.removeWhere((element) => (prevPosts.contains(element)));

    // posts that were just displayed, might want to consider putting this in
    // .drop(), but we'll see
    prevPosts = temp;
    return posts;
  }

  Map<String, dynamic> dump() {
    return {
      "name": name,
      "path": path,
      "previousPosts": _pPtoList(prevPosts),
      "load": load
    };
  }

  @override
  String toString() {
    return {
      "name": name,
      "path": path,
      "previousPosts": _pPtoList(prevPosts),
      "load": load
    }.toString();
  }

  List<Map> _pPtoList(List<Post> prevPosts) {
    List<Map> s = [];
    for (Post p in prevPosts) {
      s.add(p.dump());
    }
    return s;
  }
}

class RedditWebsite extends Website {
  //late Reddit reddit;
  static const header = {'user-agent': 'Made by /u/IncendiaryLobotomy'};

  RedditWebsite(
      {required super.path,
      required super.name,
      required super.prevPosts,
      required super.load});
  // e.g of path in this context is: pcgiveaways/new.json?f=flair_name%3A"Gleam"
  // the ".json" is not automatically inserted

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
      return [];
    } catch (e) {
      debugPrint("Failed to get Posts from reddit/r/$path");
      debugPrint('Error(may be null): $e');
      return [];
    }
  }
}

class GamerPowerWebsite extends Website {
  GamerPowerWebsite(
      {required super.path,
      required super.name,
      required super.prevPosts,
      required super.load});

  @override
  Future<List<Post>> getPosts() async {
    try {
      final siteHtml = await http.get(Uri.parse(path));
      // path will always be https://www.gamerpower.com/giveaways

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
