import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:novel/models/user_model.dart';
import 'package:novel/pages/edit_profile.dart';
import 'package:novel/pages/home.dart';
import 'package:novel/widgets/custom_image.dart';
import 'package:novel/widgets/header.dart';
import 'package:novel/widgets/post.dart';
import 'package:novel/widgets/progress.dart';

Timestamp timestamp = Timestamp.now();

class Profile extends StatefulWidget {
  final String profileId;
  final String liveUserId;
  Profile({this.profileId, this.liveUserId});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with SingleTickerProviderStateMixin {
  final userRef = FirebaseFirestore.instance.collection('users');
  final postsRef = FirebaseFirestore.instance.collection('posts');
  final followersRef = FirebaseFirestore.instance.collection('followers');
  final followingRef = FirebaseFirestore.instance.collection('following');
  final activityFeedRef = FirebaseFirestore.instance.collection('activityFeed');
  bool isLoading = false;
  int postCount = 0;
  int followersCount = 0;
  int followingCount = 0;
  List<Post> posts = [];
  TabController tabController;
  String postOrientation = 'grid';
  bool isFollowing = false;

  Column buildCountColumn({String label, int count}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28.0),
        ),
        SizedBox(height: 4.0),
        Text(
          label,
          style: TextStyle(fontSize: 12.0),
        ),
      ],
    );
  }

  buildButton(String buttonText, Function onTap) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      height: 64.0,
      width: MediaQuery.of(context).size.width,
      child: RaisedButton(
        padding: EdgeInsets.symmetric(
          horizontal: 16.0,
        ),
        highlightElevation: 0.0,
        disabledElevation: 0.0,
        color: isFollowing ? Colors.transparent : CupertinoColors.activeBlue,
        elevation: 0.0,
        shape: RoundedRectangleBorder(
            side: BorderSide(
                color:
                    isFollowing ? Colors.black54 : CupertinoColors.activeBlue)),
        onPressed: onTap,
        child: Text(
          buttonText,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isFollowing ? Colors.black : Colors.white),
        ),
      ),
    );
  }

  buildProfileButton() {
    bool isProfileOwner = widget.liveUserId == widget.profileId;
    if (isProfileOwner) {
      return buildButton('Edit Profile', editProfile);
    } else if (isFollowing) {
      return buildButton('Following', handleUnfollowUser);
    } else if (!isFollowing) {
      return buildButton(
        'Follow',
        handleFollowUser,
      );
    }
  }

  handleUnfollowUser() {
    setState(() {
      isFollowing = false;
    });
    //deleting ourselves to THAT user followers
    followersRef
        .doc(widget.profileId)
        .collection('userFollowers')
        .doc(widget.liveUserId)
        .delete();
    //deleting that user from our following
    followingRef
        .doc(widget.liveUserId)
        .collection('userFollowing')
        .doc(widget.profileId)
        .get()
        .then((doc) {
      doc.reference.delete();
    });
    //deleting notification to user activity
    setState(() {
      timestamp = Timestamp.now();
    });
    activityFeedRef
        .doc(widget.profileId)
        .collection('feedItems')
        .doc(widget.liveUserId)
        .delete();
  }

  handleFollowUser() {
    setState(() {
      isFollowing = true;
    });
    //adding ourselves to THAT user followers
    followersRef
        .doc(widget.profileId)
        .collection('userFollowers')
        .doc(widget.liveUserId)
        .set({});
    //adding that user to our following
    followingRef
        .doc(widget.liveUserId)
        .collection('userFollowing')
        .doc(widget.profileId)
        .set({});
    //adding notification to user activity
    setState(() {
      timestamp = Timestamp.now();
    });
    activityFeedRef
        .doc(widget.profileId)
        .collection('feedItems')
        .doc(widget.liveUserId)
        .set({
      'type': 'follow',
      'commentData': null,
      'username': liveUser.username,
      'userId': widget.liveUserId,
      'userProfileImg': liveUser.photoUrl,
      'postId': null,
      'mediaUrl': null,
      'timestamp': timestamp,
    });
  }

  checkIfFollowing() async {
    DocumentSnapshot doc = await followingRef
        .doc(widget.liveUserId)
        .collection('userFollowing')
        .doc(widget.profileId)
        .get();
    setState(() {
      isFollowing = doc.exists;
    });
  }

  getUserFollower() async {
    QuerySnapshot snapshot = await followersRef
        .doc(widget.profileId)
        .collection('userFollowers')
        .get();
    setState(() {
      followersCount = snapshot.docs.length;
    });
  }

  getUserFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .doc(widget.profileId)
        .collection('userFollowing')
        .get();
    setState(() {
      followingCount = snapshot.docs.length;
    });
  }

  editProfile() {
    Navigator.push(
        context,
        CupertinoPageRoute(
            builder: (context) => EditProfile(liveUserId: widget.liveUserId)));
  }

  buildProfileHeader() {
    return FutureBuilder(
        future: userRef.doc(widget.profileId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          FireUser fireUser = FireUser.fromDocument(snapshot.data);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 16.0, bottom: 0.0, left: 8.0, right: 16.0),
                        child: ClipOval(
                          child: Container(
                            height: 84.0,
                            width: 84.0,
                            child: AspectRatio(
                              aspectRatio: 1 / 1,
                            ),
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(fireUser.photoUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '@${fireUser.username}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          buildCountColumn(label: 'Posts', count: postCount),
                          buildCountColumn(
                              label: 'Followers', count: followersCount),
                          buildCountColumn(
                              label: 'Following', count: followingCount),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(fireUser.bio),
                  ),
                ],
              ),
              buildProfileButton(),
            ],
          );
        });
  }

  gridPostView() {
    List<GridTile> gridTiles = [];
    posts.forEach((post) {
      gridTiles.add(GridTile(
        child: cachedNetworkImage(context, post.mediaUrl),
      ));
    });
    return Container(
      child: GridView.count(
        crossAxisCount: 3,
        children: gridTiles,
        cacheExtent: 1.0,
        crossAxisSpacing: 1.5,
        mainAxisSpacing: 1.5,
        shrinkWrap: true,
        childAspectRatio: 1.0,
      ),
    );
  }

  listPostView() {
    return Column(children: posts);
  }

  buildProfilePosts() {
    if (isLoading) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(vertical: 60.0),
        //TODO: use a flexible widget instead of a container
        height: 500.0,
        child: Text(
          'No Uploads',
          style: TextStyle(color: Colors.black54),
        ),
      );
    } else if (postOrientation == 'grid') {
      return gridPostView();
    } else if (postOrientation == 'list') {
      return listPostView();
    }
  }

  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postsRef
        .doc(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .get();
    setState(() {
      isLoading = false;
      postCount = snapshot.docs.length;
      posts = snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  buildPostTabBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        IconButton(
          icon: Icon(
            Icons.grid_on_outlined,
            color: postOrientation == 'grid'
                ? CupertinoColors.black
                : Colors.black54,
          ),
          onPressed: () {
            setState(() {
              postOrientation = 'grid';
            });
          },
        ),
        IconButton(
          icon: Icon(
            Icons.list_outlined,
            color: postOrientation == 'list'
                ? CupertinoColors.black
                : Colors.black54,
          ),
          onPressed: () {
            setState(() {
              postOrientation = 'list';
            });
          },
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    getProfilePosts();
    checkIfFollowing();
    getUserFollower();
    getUserFollowing();
    tabController = TabController(length: 2, vsync: this, initialIndex: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: header(
          context: context,
          headline: 'Profile',
          isLeading: widget.profileId != widget.liveUserId),
      body: ListView(
        children: [
          buildProfileHeader(),
          Divider(height: 0.0),
          buildPostTabBar(),
          Divider(height: 0.0),
          buildProfilePosts(),
        ],
      ),
    );
  }
}
