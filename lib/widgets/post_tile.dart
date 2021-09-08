import 'package:flutter/material.dart';
import 'package:novel/widgets/custom_image.dart';
import 'package:novel/widgets/post.dart';

class PostTile extends StatelessWidget {
  final Post post;
  PostTile({this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: cachedNetworkImage(context, post.mediaUrl),
    );
  }
}
