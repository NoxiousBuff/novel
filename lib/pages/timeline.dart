import 'package:flutter/material.dart';
import 'package:novel/widgets/header.dart';
import 'package:novel/widgets/progress.dart';

class Timeline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context: context, headline: 'Timeline'),
      body: circularProgress(),
    );
  }
}
