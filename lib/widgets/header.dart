import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:novel/testing/testing.dart';

logout() {
  GoogleSignIn().signOut();
}

logoutDialog(BuildContext context) {
  return CupertinoAlertDialog(
    title: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Icon(
        Icons.login_outlined,
        size: 84.0,
        color: CupertinoColors.tertiaryLabel,
      ),
    ),
    content: Text('Do you want to logout?'),
    actions: [
      CupertinoDialogAction(
        child: Text(
          'Logout',
          style: TextStyle(color: Colors.red),
        ),
        onPressed: logout(),
      ),
      CupertinoDialogAction(
        child: Text('Cancel'),
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop("Discard");
        },
      ),
    ],
  );
}

AppBar header({BuildContext context, String headline, bool isLeading = false}) {
  return AppBar(
    centerTitle: true,
    title: Text(
      headline ?? 'Chats',
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
          fontSize: 18.0,
          color: Colors.black,
          fontFamily: 'QuickSand',
          fontWeight: FontWeight.bold),
    ),
    actions: [
      IconButton(
        icon: Icon(Icons.style_outlined, color: Colors.black87),
        onPressed: () {
          Navigator.push(
              context, CupertinoPageRoute(builder: (context) => Testing()));
        },
      ),
      IconButton(
        icon: Icon(Icons.ios_share, color: Colors.black87),
        onPressed: () {
          showCupertinoModalPopup(
              context: context,
              builder: (context) {
                return logoutDialog(context);
              });
        },
      ),
    ],
    shape: Border(bottom: BorderSide(color: CupertinoColors.inactiveGray)),
    leading: isLeading
        ? IconButton(
            icon: Icon(CupertinoIcons.chevron_back, color: Colors.black87),
            onPressed: () {
              Navigator.pop(context);
            },
          )
        : null,
    toolbarHeight: 40.0,
    backgroundColor: Colors.white.withOpacity(0.2),
    elevation: 0.0,
    flexibleSpace: ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.3)),
        ),
      ),
    ),
  );
}
