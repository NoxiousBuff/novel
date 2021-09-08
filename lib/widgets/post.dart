import 'dart:async';
import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:novel/models/app_user_data.dart';
import 'package:novel/models/user_model.dart';
import 'package:novel/pages/home.dart';
import 'package:novel/widgets/custom_image.dart';
import 'package:novel/widgets/header.dart';
import 'package:novel/widgets/progress.dart';

Timestamp timestamp = Timestamp.now();

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final dynamic likes;
  final String description;
  final String mediaUrl;

  Post(
      {this.description,
      this.mediaUrl,
      this.username,
      this.postId,
      this.likes,
      this.location,
      this.ownerId});

  factory Post.fromDocument(DocumentSnapshot documentSnapshot) {
    return Post(
      postId: documentSnapshot['postId'],
      ownerId: documentSnapshot['ownerId'],
      username: documentSnapshot['username'],
      location: documentSnapshot['location'],
      description: documentSnapshot['description'],
      mediaUrl: documentSnapshot['mediaUrl'],
      likes: documentSnapshot['likes'],
    );
  }

  int getLikeCount(likes) {
    //if no likes, return 0
    if (likes == 0) {
      return 0;
    }

    //if key is explicitly set to true, add a like
    int count = 0;
    likes.values.forEach((val) {
      if (val == true) {
        count += 1;
      }
    });
    return count;
  }

  @override
  _PostState createState() => _PostState(
        postId: this.postId,
        ownerId: this.ownerId,
        username: this.username,
        location: this.location,
        description: this.description,
        mediaUrl: this.mediaUrl,
        likes: this.likes,
        likeCount: getLikeCount(this.likes),
      );
}

class _PostState extends State<Post> {
  final String liveUserId = kAppUserId;
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  Map likes;
  int likeCount;
  final userRef = FirebaseFirestore.instance.collection('users');
  final commentsRef = FirebaseFirestore.instance.collection('comments');
  final postsRef = FirebaseFirestore.instance.collection('posts');
  final activityFeedRef = FirebaseFirestore.instance.collection('activityFeed');
  bool _isLiked;
  bool showHeart = false;
  TextEditingController commentController = TextEditingController();

  _PostState(
      {this.description,
      this.mediaUrl,
      this.username,
      this.postId,
      this.likes,
      this.location,
      this.ownerId,
      this.likeCount});

  buildPostHeader() {
    return FutureBuilder(
      future: userRef.doc(ownerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return linearProgress();
        }
        FireUser fireUser = FireUser.fromDocument(snapshot.data);
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(fireUser.photoUrl),
          ),
          title: GestureDetector(
            onTap: () {},
            child: Text(
              fireUser.displayName,
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
          subtitle: Text(
            location,
            style: TextStyle(color: Colors.black54),
          ),
          trailing: InkWell(
            child: Icon(Icons.more_vert),
            onTap: () => print("deleting posts"),
          ),
        );
      },
    );
  }

  buildPostContent() {
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: [
          cachedNetworkImage(context, mediaUrl),
          showHeart
              ? Animator(
                  duration: Duration(milliseconds: 300),
                  tween: Tween(begin: 0.8, end: 1.6),
                  curve: Curves.elasticIn,
                  cycles: 0,
                  builder: (BuildContext context, AnimatorState animatorState,
                      Widget child) {
                    return Icon(
                      Icons.favorite,
                      size: 256.0,
                      color: Colors.white54,
                    );
                  },
                )
              : Text(''),
        ],
      ),
    );
  }

  showCommentsDialog() {
    showCupertinoModalPopup(
        context: context, builder: (context) => showComments(context));
  }

  Scaffold showComments(BuildContext context) {
    return Scaffold(
      appBar: header(context: context, headline: 'Comments'),
      body: Column(
        children: [
          Expanded(child: buildComments()),
          Divider(height: 0.0),
          buildTextComposer(),
        ],
      ),
    );
  }

  buildTextComposer() {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        IconButton(
            icon: Icon(
              Icons.emoji_emotions,
              color: Colors.black54,
            ),
            onPressed: () {}),
        Expanded(
          child: CupertinoTextField.borderless(
            controller: commentController,
            placeholder: 'Write your mind .....',
          ),
        ),
        TextButton(
          child: Text('Send'),
          onPressed: addComment,
        ),
      ],
    );
  }

  addComment() {
    commentsRef.doc(postId).collection('postComments').add({
      'username': liveUser.username,
      'comment': commentController.text,
      'timestamp': timestamp,
      'avatarUrl': liveUser.photoUrl,
      'userId': liveUserId,
    }).catchError((err) => print('Error in submitting comment = $err'));
    setState(() {
      timestamp = Timestamp.now();
    });
    addCommentToActivityFeed();
    commentController.clear();
    print('This is the time: $timestamp');
  }

  addCommentToActivityFeed() {
    setState(() {
      timestamp = Timestamp.now();
    });
    bool isNotPostOwner = liveUserId != ownerId;
    if (isNotPostOwner) {
      activityFeedRef.doc(ownerId).collection("feedItems").add({
        'type': 'comment',
        'commentData': commentController.text,
        'username': liveUser.username,
        'userId': liveUserId,
        'userProfileImg': liveUser.photoUrl,
        'postId': postId,
        'mediaUrl': mediaUrl,
        'timestamp': timestamp,
      });
    }
  }

  buildComments() {
    return StreamBuilder<QuerySnapshot>(
      stream: commentsRef
          .doc(postId)
          .collection('postComments')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<Comment> comments = [];
        snapshot.data.docs.forEach((doc) {
          comments.add(Comment.fromDocument(doc));
        });
        return ListView(
          children: comments,
        );
      },
    );
    // return Container();
  }

  buildPostFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              icon: _isLiked
                  ? Icon(
                      Icons.favorite,
                      color: CupertinoColors.systemPink,
                    )
                  : Icon(Icons.favorite_border_sharp),
              onPressed: handleLikePost,
            ),
            IconButton(
              icon: Icon(Icons.gesture_rounded),
              onPressed: showCommentsDialog,
            ),
            IconButton(
              icon: Icon(Icons.near_me_outlined),
              onPressed: () {},
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '$likeCount likes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(
              top: 4.0, right: 16.0, bottom: 20.0, left: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '@$username - ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: Text('$description'),
              )
            ],
          ),
        ),
        Divider(height: 0.0)
      ],
    );
  }

  handleLikePost() async {
    _isLiked = likes[liveUserId] == true;
    DocumentSnapshot document =
        await postsRef.doc(ownerId).collection('userPosts').doc(postId).get();
    if (_isLiked) {
      if (!document.exists) {
        postsRef
            .doc(ownerId)
            .collection('userPosts')
            .doc(postId)
            .set({'likes.$liveUserId': false}).catchError((err) {
          print('Error in submitting like = $err');
        });
        setState(() {
          likeCount -= 1;
          _isLiked = false;
          likes[liveUserId] = false;
          removeLikeFromActivityFeed();
        });
      } else if (document.exists) {
        postsRef
            .doc(ownerId)
            .collection('userPosts')
            .doc(postId)
            .update({'likes.$liveUserId': false}).catchError((err) {
          print('Error in submitting like = $err');
        });
        setState(() {
          likeCount -= 1;
          _isLiked = false;
          likes[liveUserId] = false;
        });
        removeLikeFromActivityFeed();
      }
    } else if (!_isLiked) {
      if (!document.exists) {
        postsRef
            .doc(ownerId)
            .collection('userPosts')
            .doc(postId)
            .set({'likes.$liveUserId': true}).catchError((err) {
          print('Error in submitting like = $err');
        });
        setState(() {
          likeCount += 1;
          _isLiked = true;
          likes[liveUserId] = true;
          showHeart = true;
        });
        addLikeToActivityFeed();
        Timer(Duration(milliseconds: 500), () {
          setState(() {
            showHeart = false;
          });
        });
      } else if (document.exists) {
        postsRef
            .doc(ownerId)
            .collection('userPosts')
            .doc(postId)
            .update({'likes.$liveUserId': true}).catchError((err) {
          print('Error in submitting like = $err');
        });
        setState(() {
          likeCount += 1;
          _isLiked = true;
          likes[liveUserId] = true;
          showHeart = true;
        });
        addLikeToActivityFeed();
        Timer(Duration(milliseconds: 500), () {
          setState(() {
            showHeart = false;
          });
        });
      }
    }
  }

  addLikeToActivityFeed() {
    setState(() {
      timestamp = Timestamp.now();
    });
    bool isNotPostOwner = liveUserId != ownerId;
    if (isNotPostOwner) {
      activityFeedRef.doc(ownerId).collection("feedItems").doc(postId).set({
        'type': 'like',
        'username': liveUser.username,
        'userId': liveUserId,
        'userProfileImg': liveUser.photoUrl,
        'postId': postId,
        'mediaUrl': mediaUrl,
        'timestamp': timestamp,
        'commentData': null,
      });
    }
  }

  removeLikeFromActivityFeed() {
    bool isNotPostOwner = liveUserId != ownerId;
    if (isNotPostOwner) {
      activityFeedRef
          .doc(ownerId)
          .collection("feedItems")
          .doc(postId)
          .get()
          .then((doc) {
        doc.reference.delete();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _isLiked = likes[liveUserId] == true;

    return Column(
      children: [buildPostHeader(), buildPostContent(), buildPostFooter()],
    );
  }
}

class Comment extends StatelessWidget {
  final String username;
  final String userId;
  final String avatarUrl;
  final String comment;
  final Timestamp timestamp;

  Comment(
      {this.timestamp,
      this.username,
      this.avatarUrl,
      this.comment,
      this.userId});

  factory Comment.fromDocument(DocumentSnapshot doc) {
    return Comment(
      username: doc['username'],
      userId: doc['userId'],
      avatarUrl: doc['avatarUrl'],
      comment: doc['comment'],
      timestamp: doc['timestamp'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: Text(comment),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
          ),
          subtitle: Text(timeago.format(timestamp.toDate())),
        ),
        Divider(height: 0.0),
      ],
    );
  }
}
