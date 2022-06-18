//////////////
// Author: Arya Jafari, Universiy of Toronto Mississauga
// Date of Last Update: June 8th, 2022 (08/06/22)
// Description: Objects handling the UI of the website aggregator app.
//              Communicate heavily with <WebsiteFolder> objects
//////////////

import 'package:flutter/material.dart';
import 'package:website_fetcher/website_folder_object.dart';
import 'website_object.dart';

class PostTabView extends StatelessWidget {
  // A class for both the new posts tab and all posts tabs
  final List<Post> posts;
  final bool loadingPosts;

  const PostTabView({Key? key, required this.posts, required this.loadingPosts})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (loadingPosts) {
      // currently in the process of gettting posts from the internet
      return const SizedBox(
          height: 60.0,
          width: 60.0,
          child: Center(child: CircularProgressIndicator()));
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: posts.length,
        itemBuilder: (BuildContext context, int index) {
          return BuildPost(post: posts[index]);
        },
      );
    }
  }
}

class LaunchButtonView extends StatelessWidget {
  final int index;
  final List<Post> posts;
  final List<Post> allPosts;

  const LaunchButtonView(
      {Key? key,
      required this.index,
      required this.posts,
      required this.allPosts})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // index either 0 or 1
    if (index == 0) {
      return ElevatedButton(
          onPressed: () {
            for (Post post in posts) {
              post.urlLaunch();
            }
          },
          child: const Text("Launch All New Posts"));
    } else {
      return ElevatedButton(
          onPressed: () {
            for (Post post in allPosts) {
              post.urlLaunch();
            }
          },
          child: const Text("Launch All Posts"));
    }
  }
}

class WebsiteManagerTabView extends StatefulWidget {
  // A class specifically for the website manager tab
  final WebsiteFolder websiteFolder;

  const WebsiteManagerTabView({Key? key, required this.websiteFolder})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _WebsiteManagerTabStateful();
}

class _WebsiteManagerTabStateful extends State<WebsiteManagerTabView> {
  @override
  Widget build(BuildContext context) {
    return _displayWebsiteManagerFrame(context);
  }

  Widget _displayWebsiteManagerFrame(BuildContext context) {
    List<Widget> websiteCards = [];
    for (int i = 0; i < WebsiteFolder.websiteTypes.length; i++) {
      websiteCards.add(_makeHeaderCard(WebsiteFolder.websiteTypes[i]));
      try {
        websiteCards.add(_displayWebsiteType(
          context,
          widget.websiteFolder.websiteList[i],
        ));
      } catch (e) {
        debugPrint("Failed to display website, $i");
        debugPrint("error (may be null): $e");
        websiteCards.add(
          Card(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const <Widget>[],
            ),
          ),
        );
      }
    }
    return Center(
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: websiteCards,
      ),
    );
  }

  Widget _makeHeaderCard(String hostType) {
    return Center(
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: Text(hostType),
              trailing: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return _FormView(
                            websiteTabStatefulObject: this, hostType: hostType);
                      });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _displayWebsiteType(BuildContext context, List<dynamic> websites) {
    return Center(
      child: Column(
        children: <Widget>[
          ...websites.map((e) => _buildWebsite(context, e)).toList()
        ],
      ),
    );
  }

  Widget _buildWebsite(BuildContext context, Website w) {
    return ListTile(
      title: Text(w.name),
      subtitle: Text(w.path),
      leading: IconButton(
        icon: const Icon(
          Icons.remove,
          color: Colors.red,
        ),
        onPressed: () => setState(() {
          widget.websiteFolder.removeWebsite(w);
        }),
      ),
      trailing: Checkbox(
          value: w.load,
          onChanged: (bool? v) => setState(() {
                w.load = v ?? !w.load;
              })),
    );
  }

  void _updateWebsiteList(String hostType, String path, String name) {
    setState(() {
      widget.websiteFolder.addWebsite(hostType, path, name);
    });
  }
}

class _FormView extends StatefulWidget {
  final String hostType;
  final _WebsiteManagerTabStateful websiteTabStatefulObject;

  const _FormView(
      {Key? key,
      //required this.websiteFolder,
      required this.hostType,
      required this.websiteTabStatefulObject})
      : super(key: key);

  @override
  State<_FormView> createState() => _FormStateful();
}

class _FormStateful extends State<_FormView> {
  //with State<WebsiteManagerTabView>{
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  static final List<String> inputParams = <String>['', ''];
  // [0] : name
  // [1] : url/path

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Stack(
        children: <Widget>[
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _textInputBox("Website Name", "Please enter a valid name", 0),
                _textInputBox("Website Url", "Please enter a valid url", 1),
                _submitButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _submitButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(210, 16, 0, 0),
      child: ElevatedButton(
        child: const Text('Submit'),
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            _formKey.currentState!.save();
            widget.websiteTabStatefulObject._updateWebsiteList(
                widget.hostType, inputParams[1], inputParams[0]);

            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _textInputBox(String textHint, String errMessage, int i) {
    return SizedBox(
      width: 500.0,
      child: TextFormField(
        decoration: InputDecoration(
          hintText: textHint,
        ),
        validator: (String? value) {
          if (value == null || value.isEmpty) {
            return errMessage;
          }
          return null;
        },
        onSaved: (String? value) =>
            setState(() => inputParams[i] = value ?? ''),
      ),
    );
  }
}

class BuildPost extends StatelessWidget {
  final Post post;

  const BuildPost({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Below gives errors when not connected to the internet
    // or when url fails to resolve
    final Widget img = Image.network(
      post.imageUrl,
      errorBuilder: (context, error, stackTrace) {
        if (post.imageUrl != "") {
          debugPrint("Failed to load image at url: ${post.imageUrl}");
          debugPrint("error (may be null): $error \n");
        }
        return const Icon(Icons.link_off);
      },
    );

    return Center(
      child: Card(
        child: InkWell(
          splashColor: Colors.blue.withAlpha(30),
          onTap: () => {post.urlLaunch()},
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: img,
                title: Text(post.title),
                subtitle: Text(post.linkUrl),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
