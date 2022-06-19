//////////////
// Author: Arya Jafari, Universiy of Toronto Mississauga
// Description: A personal project desgined to be a website aggregator.
//              The program gathers 'posts' from various websites, whether
//              through APIs or HTML scraping and displays them in one place.
//              Allows launching said posts in the browser
// See website_folder.WebsiteFolder for an overview of architechture
//////////////

import 'package:flutter/material.dart';
import 'package:website_fetcher/website_object.dart';
import 'website_folder_object.dart';
import 'display_object.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Post Aggregator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home:
          MyHomePage(title: 'Post Aggregator', websiteFolder: WebsiteFolder()),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  final WebsiteFolder websiteFolder;

  const MyHomePage({Key? key, required this.title, required this.websiteFolder})
      : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late List<Post> posts = [];
  late final TabController _tabController;
  bool loadingPosts = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshNewPosts() {
    /// Make the api calls in order to get posts from the internets
    // begin playing loading animation (see PostTabView in display_object.dart)
    setState(() {
      loadingPosts = true;
    });

    // get the posts
    widget.websiteFolder.getPosts().then(
      (value) {
        // update list of displayed posts
        setState(() {
          posts = value;
        });

        // save gotten posts to file (in order to filter form previously seen)
        widget.websiteFolder.saveWebsites();
        // stop playing loading animation
        loadingPosts = false;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.newspaper)),
            Tab(icon: Icon(Icons.history)),
            Tab(icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // tab with newly gotten posts (filtered)
          PostTabView(posts: posts, loadingPosts: loadingPosts),
          // tab of all posts (not filtered)
          PostTabView(
              posts: widget.websiteFolder.getAllPosts(),
              loadingPosts: loadingPosts),
          // tab for managing websites
          WebsiteManagerTabView(websiteFolder: widget.websiteFolder)
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.blue,
        child: IconTheme(
          data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
          child: Row(
            children: <Widget>[
              // gets posts from internet
              IconButton(
                tooltip: 'Get New Posts',
                icon: const Icon(Icons.refresh),
                onPressed: _refreshNewPosts,
              ),
              // opens currently displayed posts in webbrowser
              LaunchButtonView(
                  index: _tabController.index,
                  posts: posts,
                  allPosts: widget.websiteFolder.getAllPosts()),
            ],
          ),
        ),
      ),
    );
  }
}
