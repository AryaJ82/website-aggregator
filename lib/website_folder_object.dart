//////////////
// Author: Arya Jafari, Universiy of Toronto Mississauga
// Date of Last Update: June 8th, 2022 (08/06/22)
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
  static const websiteTypes = ['Reddit', 'GamerPower'];
  // If the above is modified, the following locations must be updated:
  // _makeWebsiteObject
  final websiteList =
      List<List<Website>>.generate(websiteTypes.length, (i) => []);

  WebsiteFolder() {
    _loadFileContents();
  }

  Future<List<Post>> getPosts() async {
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
    List<Post> allPosts = [];
    for (int i = 0; i < websiteList.length; i++) {
      for (Website w in websiteList[i]) {
        if (w.load) allPosts.addAll(w.prevPosts);
      }
    }
    return allPosts;
  }

  Website _makeWebsiteObject(Map<String, dynamic> w, String hostType) {
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
    // error with empty list
    websiteList[websiteTypes.indexOf(hostType)].add(_makeWebsiteObject(
        {"name": name, "path": path, "load": true, "previousPosts": []},
        hostType));
    saveWebsites();
  }

  void removeWebsite(Website website) {
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
