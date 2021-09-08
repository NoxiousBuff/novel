import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:novel/widgets/progress.dart';

Widget cachedNetworkImage(BuildContext context, String mediaUrl) {
  return CachedNetworkImage(
    fit: BoxFit.cover,
    imageUrl: mediaUrl,
    height: MediaQuery.of(context).size.width,
    width: MediaQuery.of(context).size.width,
    errorWidget: (context, url, error) => Icon(Icons.error_outline),
    placeholder: (context, url) => Container(
      height: MediaQuery.of(context).size.width,
      width: MediaQuery.of(context).size.width,
      child: circularProgress(),
    ),
  );
}
