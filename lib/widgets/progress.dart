import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Container circularProgress() {
  return Container(
    alignment: Alignment.center,
    padding: EdgeInsets.only(top: 10.0),
    child: CupertinoActivityIndicator(
      radius: 12.0,
    ),
  );
}

Container linearProgress() {
  return Container(
    padding: EdgeInsets.only(bottom: 10.0),
    child: LinearProgressIndicator(
      valueColor: AlwaysStoppedAnimation(CupertinoColors.activeBlue),
      backgroundColor: Colors.transparent,
    ),
  );
}
