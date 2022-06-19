//////////////
// Author: Arya Jafari, Universiy of Toronto Mississauga
// Description: Object that handles the information gathered by webites. Stores
//              <Website> objects.
//////////////

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'website_object.dart';

class WebsiteFolder {
  /// This object handles the majority of data processing, inlcuding:
  /// - Reading/Writing to files
  /// - API calls
  ///
  /// A <WebsiteFolder> object will hold a 2d list of <Website> objects
  /// in the attribute <websiteList>.
  /// Index i of websiteList is a list of <Website> objects corresponding to
  /// the ones dictated by <websiteTypes> (index 0 is a list of <RedditWebsite>)
  static const websiteTypes = ['Reddit', 'GamerPower'];
  // If the above is modified, the following locations must be updated:
  // _makeWebsiteObject
  final websiteList =
      List<List<Website>>.generate(websiteTypes.length, (i) => []);

  WebsiteFolder() {
    _loadFileContents();
  }

  Future<List<Post>> getPosts() async {
    /// Returns a list of Posts gotten by calling Website.getPosts()
    /// Only runs said method if Website.load is true
    /// Returned list is filtered against itself to remove duplicate Post objects
    /// which reference the same Post.url

    final List<Future<List<Post>>> temp = [];
    final List<Post> posts = [];
    // temp holds the future objects which represent lists of posts gotten from
    // individual concrete implementations of Website held in the 2d list
    // <websiteList>
    for (int i = 0; i < websiteTypes.length; i++) {
      for (int k = 0; k < websiteList[i].length; k++) {
        if (websiteList[i][k].load) temp.add(websiteList[i][k].getPosts());
      }
    }
    // Wait for all Future objects returned by Website.getPosts() to return
    // their values
    final pmet = await Future.wait(temp);
    for (int i = 0; i < temp.length; i++) {
      posts.addAll(pmet[i]);
    }
    //remove duplicates from across website objects
    final ids = <String>{};
    posts.retainWhere((e) => (ids.add(e.linkUrl)));
    return posts;
  }

  void _loadFileContents() async {
    /// Load the json file at
    /// "_localPath/flutter_website_fetcher/stored_websites.json"
    /// _localPath is Documents directory on Linux/Windows
    /// json file contains stored <Website> objects
    try {
      final file = await File(
              "${await _localPath}/flutter_website_fetcher/stored_websites.json")
          .create(recursive: true);

      // Read the file
      final contents = jsonDecode(await file.readAsString());

      for (int i = 0; i < websiteTypes.length; i++) {
        websiteList[i] = <Website>[
          ...(contents[websiteTypes[i]] ?? [])
              .map((e) => (_makeWebsiteObject(e, websiteTypes[i])))
              .toList()
        ];
      }
    } catch (e) {
      // If encountering an error, keep website list empty
      debugPrint("Failed to load stored websites");
      debugPrint('(error may be null)$e');
    }
  }

  Future<File> saveWebsites() async {
    /// Save the contents of this.websiteList in json format at location:
    /// "_localPath/flutter_website_fetcher/stored_websites.json"
    /// _localPath is Documents directory on Linux/Windows
    /// json file contains new stored <Website> objects
    final file = File(
        "${await _localPath}/flutter_website_fetcher/stored_websites.json");
    final Map<String, dynamic> j = {};

    for (int i = 0; i < websiteTypes.length; i++) {
      final List temp = [];
      for (int k = 0; k < websiteList[i].length; k++) {
        temp.add(websiteList[i][k].dump());
      }
      j[websiteTypes[i]] = temp;
    }

    // Write the file
    return file.writeAsString(jsonEncode(j));
  }

  List<Post> getAllPosts() {
    /// return the concatenated list of Website.prevPosts of all <Website>s in
    /// <this.websiteList>
    List<Post> allPosts = [];
    for (int i = 0; i < websiteList.length; i++) {
      for (Website w in websiteList[i]) {
        if (w.load) allPosts.addAll(w.prevPosts);
      }
    }
    return allPosts;
  }

  Website _makeWebsiteObject(Map<String, dynamic> w, String hostType) {
    /// Makes a <Website> object of implementation flavour <hostType>
    /// E.g. hostType == 'Reddit' makes a <RedditWebsite> object
    /// w is a map with the following keys: path, name, load, previousPosts
    /// which correspond to the keys of the same name is <Website> objects
    switch (hostType) {
      case 'Reddit':
        {
          return RedditWebsite(
              path: w['path'],
              name: w['name'],
              load: w['load'],
              prevPosts: jToPost(w['previousPosts']));
        }
      case 'GamerPower':
        {
          return GamerPowerWebsite(
              path: w['path'],
              name: w['name'],
              load: w['load'],
              prevPosts: jToPost(w['previousPosts']));
        }
      default:
        {
          debugPrint("Case not in potential options of switch case: $hostType");
          return GamerPowerWebsite(
              path: "https://www.gamerpower.com/giveaways",
              name: 'Failed To Load, Defaulted to GamerPower',
              prevPosts: [],
              load: false);
        }
    }
  }

  void addWebsite(String hostType, String path, String name) {
    /// Make a <Website> object of hostType <hostType>, name <name> etc.
    /// and adds it to the correct index of this.websiteTypes
    websiteList[websiteTypes.indexOf(hostType)].add(_makeWebsiteObject(
        {"name": name, "path": path, "load": true, "previousPosts": []},
        hostType));
    saveWebsites();
  }

  void removeWebsite(Website website) {
    /// Removes <website> from this.websiteList
    for (var websitesOfHostType in websiteList) {
      if (websitesOfHostType.remove(website)) break;
    }
  }
}

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

List<Post> jToPost(List ls) {
  List<Post> sl = [];
  for (int i = 0; i < ls.length; i++) {
    sl.add(Post.fromJson(ls[i]));
  }
  return sl;
}
