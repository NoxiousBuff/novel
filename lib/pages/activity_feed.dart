import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:novel/pages/home.dart';
import 'package:novel/pages/post_screen.dart';
import 'package:novel/pages/profile.dart';
import 'package:novel/widgets/header.dart';
import 'package:novel/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeedState createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  final activityFeedRef = FirebaseFirestore.instance.collection('activityFeed');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: header(context: context, headline: 'Feed'),
        body: FutureBuilder<QuerySnapshot>(
          future: activityFeedRef
              .doc(liveUser.id)
              .collection('feedItems')
              .orderBy('timestamp', descending: true)
              .limit(50)
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return circularProgress();
            }
            List<ActivityFeedItem> feedItems = [];
            snapshot.data.docs.forEach((doc) {
              feedItems.add(ActivityFeedItem.fromDocument(doc));
            });
            return ListView(
              children: feedItems,
            );
          },
        ));
  }
}

Widget mediaPreview;
String activityItemText;

class ActivityFeedItem extends StatelessWidget {
  final String userId;
  final String username;
  final String type;
  final String mediaUrl;
  final String postId;
  final String userProfileImg;
  final String commentData;
  final Timestamp timestamp;

  ActivityFeedItem(
      {this.mediaUrl,
      this.postId,
      this.username,
      this.userId,
      this.commentData,
      this.type,
      this.userProfileImg,
      this.timestamp});

  factory ActivityFeedItem.fromDocument(DocumentSnapshot doc) {
    return ActivityFeedItem(
      mediaUrl: doc['mediaUrl'],
      postId: doc['postId'],
      userId: doc['userId'],
      username: doc['username'],
      commentData: doc['commentData'],
      type: doc['type'],
      userProfileImg: doc['userProfileImg'],
      timestamp: doc['timestamp'],
    );
  }

  configureMediaPreview(context) {
    if (type == 'like' || type == 'comment') {
      mediaPreview = GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PostScreen(
                        userId: userId,
                        postId: postId,
                      )));
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
            height: 50.0,
            width: 50.0,
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                    image: DecorationImage(
                  fit: BoxFit.cover,
                  image: CachedNetworkImageProvider(mediaUrl),
                )),
              ),
            ),
          ),
        ),
      );
    } else {
      mediaPreview = Text('');
    }

    if (type == 'like') {
      activityItemText = 'liked your post.';
    } else if (type == 'follow') {
      activityItemText = 'is following you.';
    } else if (type == 'comment') {
      activityItemText = 'replied. $commentData';
    } else {
      activityItemText = "Error: Unknown Type '$type'.";
    }
  }

  @override
  Widget build(BuildContext context) {
    configureMediaPreview(context);
    return Column(
      children: [
        ListTile(
          title: GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return Profile(
                  profileId: userId,
                  liveUserId: liveUser.id,
                );
              }));
            },
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.black87,
                ),
                children: [
                  TextSpan(
                    text: username,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: ' $activityItemText',
                  ),
                ],
              ),
            ),
          ),
          subtitle: Text(
            timeago.format(timestamp.toDate()),
            overflow: TextOverflow.ellipsis,
          ),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(userProfileImg),
          ),
          trailing: mediaPreview,
        ),
        Divider(),
      ],
    );
  }
}
