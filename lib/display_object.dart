//////////////
// Author: Arya Jafari, Universiy of Toronto Mississauga
// Description: Objects handling the UI of the website aggregator app.
//              Communicate heavily with the <WebsiteFolder> object
//////////////

import 'package:flutter/material.dart';
import 'package:website_fetcher/website_folder_object.dart';
import 'website_object.dart';

class PostTabView extends StatelessWidget {
  /// A class for both the new posts tab and all posts tab
  /// makes a ListView object of the given list of Post objects
  final List<Post> posts;
  final bool loadingPosts;

  const PostTabView({Key? key, required this.posts, required this.loadingPosts})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (loadingPosts) {
      // currently in the process of gettting posts from the internet
      // display loading animation
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
  /// open all the displayed Post.url in the browser
  /// opened list differs depending on current tab

  // current tab index, 0 is new posts, 1 is all posts
  final int index;
  // list of displayed posts objects in new posts tab
  final List<Post> posts;
  // list of displayed posts in all posts tab
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
    // either new posts tab ot all posts tab
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
  /// A class specifically for the website manager tab
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
      // header card marks division of website types
      websiteCards.add(_makeHeaderCard(WebsiteFolder.websiteTypes[i]));
      // list of websites under hostType = websiteTypes[i]
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
                  // pop up form for adding new website
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return _FormView(
                          websiteTabStatefulObject: this,
                          hostType: hostType,
                        );
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
    /// Builds the all websites of given <websites> list
    return Center(
      child: Column(
        children: <Widget>[
          ...websites.map((e) => _buildWebsite(context, e)).toList()
        ],
      ),
    );
  }

  Widget _buildWebsite(BuildContext context, Website w) {
    /// Builds the ListTile of Website object <w>.
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
    /// Rebuilds website manager tab after adding a new website
    /// A very hacky work around to keep <Form> and <WebsiteManagerTab> objects
    /// separate from each other
    setState(() {
      widget.websiteFolder.addWebsite(hostType, path, name);
    });
  }
}

class _FormView extends StatefulWidget {
  /// Class which creates the form for creating new website objects
  final String hostType;
  final _WebsiteManagerTabStateful websiteTabStatefulObject;

  const _FormView(
      {Key? key,
      required this.hostType,
      required this.websiteTabStatefulObject})
      : super(key: key);

  @override
  State<_FormView> createState() => _FormStateful();
}

class _FormStateful extends State<_FormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  // stored the values inputted by the user
  static final List<String> inputParams = <String>['', ''];
  // [0] : name
  // [1] : url/path
  // necessary to extract the inputs taken from _textInputBox-es

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
  /// Class which builds the given post as a listview tile widget
  final Post post;

  const BuildPost({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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

    Image.network(
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
