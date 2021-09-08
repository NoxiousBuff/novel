import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:novel/widgets/header.dart';
import 'package:novel/widgets/post.dart';
import 'package:novel/widgets/progress.dart';

class PostScreen extends StatelessWidget {
  final String postId;
  final String userId;
  final postsRef = FirebaseFirestore.instance.collection('posts');

  PostScreen({
    this.userId,
    this.postId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: postsRef.doc(userId).collection('userPosts').doc(postId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        Post post = Post.fromDocument(snapshot.data);
        return Center(
          child: Scaffold(
            appBar: header(
                context: context, headline: post.description, isLeading: true),
            body: Container(
              child: post,
            ),
          ),
        );
      },
    );
  }
}
