import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:novel/models/app_user_data.dart';
import 'package:novel/models/user_model.dart';
import 'package:novel/pages/activity_feed.dart';
import 'package:novel/pages/profile.dart';
import 'package:novel/pages/search.dart';
import 'package:novel/pages/timeline.dart';
import 'package:novel/pages/upload.dart';
import 'package:google_sign_in/google_sign_in.dart';

FireUser liveUser;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isAuth = false;
  TextEditingController usernameTech = TextEditingController();
  GoogleSignIn googleSignIn = GoogleSignIn();
  PageController _pageController;
  int pageIndex = 0;
  final userRef = FirebaseFirestore.instance.collection('users');
  final DateTime timestamp = DateTime.now();

  googleLogin() async {
    final GoogleSignInAccount googleUser = await googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final GoogleAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);

    // if (user != null) {
    //   Navigator.push(
    //       context, CupertinoPageRoute(builder: (context) => Profile()));
    // }
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onClickingTab(int pageIndex) {
    _pageController.jumpToPage(
      pageIndex,
    );
  }

  Scaffold buildSignUpScreen() {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                CupertinoColors.inactiveGray,
                CupertinoColors.black,
              ]),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
              child: Text(
                'Novel',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 48.0,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CupertinoTextField(
                placeholder: 'username',
                controller: usernameTech,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
              child: CupertinoButton(
                color: CupertinoColors.systemGrey,
                onPressed: googleLogin,
                child: Text('Sign Up'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Scaffold buildAuthScreen() {
    return Scaffold(
      body: PageView(
        children: [
          Timeline(),
          ActivityFeed(),
          Upload(fireUser: liveUser),
          Search(),
          Profile(
            profileId: liveUser?.id,
            liveUserId: liveUser?.id,
          ),
        ],
        controller: _pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: CupertinoColors.inactiveGray),
          ),
        ),
        child: BottomNavigationBar(
          elevation: 0.0,
          selectedFontSize: 12.0,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black54,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          currentIndex: pageIndex,
          onTap: onClickingTab,
          items: [
            BottomNavigationBarItem(
                icon: Icon(
                  Icons.whatshot_outlined,
                ),
                activeIcon: Icon(Icons.whatshot),
                label: 'Timeline'),
            BottomNavigationBarItem(
                icon: Icon(Icons.explore_outlined),
                label: 'Explore',
                activeIcon: Icon(Icons.explore_sharp)),
            BottomNavigationBarItem(
                icon: Icon(Icons.my_library_add_outlined),
                label: 'Moments',
                activeIcon: Icon(Icons.my_library_add_sharp)),
            BottomNavigationBarItem(
                icon: Icon(Icons.search_outlined),
                label: 'Find',
                activeIcon: Icon(Icons.search)),
            BottomNavigationBarItem(
                icon: Icon(Icons.account_circle_outlined),
                label: 'Profile',
                activeIcon: Icon(Icons.account_circle_sharp)),
          ],
        ),
      ),
    );
  }

  handleSignIn(account) {
    createUserInFirebase();
    if (account != null) {
      createUserInFirebase();
      setState(() {
        isAuth = true;
      });
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  createUserInFirebase() async {
    //checking if account already exist
    final GoogleSignInAccount user = googleSignIn.currentUser;
    DocumentSnapshot document = await userRef.doc(user.id).get();

    if (!document.exists) {
      userRef.doc(user.id).set({
        'id': user.id,
        'username': usernameTech.text,
        'photoUrl': user.photoUrl,
        'email': user.email,
        'displayName': user.displayName,
        'bio': '',
        'timestamp': timestamp,
      }).catchError((err) {
        print('Error in uploading user information = $err');
      });
      document = await userRef.doc(user.id).get();
    }
    setState(() {
      kAppUserId = user.id;
    });
    liveUser = FireUser.fromDocument(document);
  }

  @override
  void initState() {
    super.initState();

    //transparent the status bar
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));

    //listening to google user changed
    googleSignIn.onCurrentUserChanged.listen((account) {
      handleSignIn(account);
    }, onError: (e) {
      print('Error in listening to user changed! = $e');
    });

    //reauthorizing user to app
    googleSignIn
        .signInSilently(suppressErrors: false)
        .then((account) => handleSignIn(account));

    //pageController
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildSignUpScreen();
  }
}
