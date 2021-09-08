import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:novel/models/user_model.dart';
import 'package:novel/pages/profile.dart';
import 'package:novel/widgets/progress.dart';
import 'home.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final userRef = FirebaseFirestore.instance.collection('users');
  TextEditingController searchController = TextEditingController();

  Future<QuerySnapshot> searchResultsFuture;

  handleSearch(String query) {
    Future<QuerySnapshot> users =
        userRef.where('displayName', isGreaterThanOrEqualTo: query).get();
    setState(() {
      searchResultsFuture = users;
    });
  }

  clearSearch() {
    searchController.clear();
  }

  AppBar buildSearchHeader() {
    return AppBar(
      shape: Border(bottom: BorderSide(color: CupertinoColors.inactiveGray)),
      elevation: 0.0,
      titleSpacing: 8.0,
      backgroundColor: CupertinoColors.lightBackgroundGray,
      title: CupertinoSearchTextField(
        controller: searchController,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4.0),
        ),
        onChanged: handleSearch,
        onSuffixTap: clearSearch,
      ),
    );
  }

  Container buildNoContent() {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Icon(
              Icons.icecream,
              size: 128.0,
              color: CupertinoColors.inactiveGray,
            ),
          ),
          Text(
            'Sorry, nothing found.\nMay be we can interest you in \nIceCream.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w300,
                fontSize: 24.0),
          )
        ],
      ),
    );
  }

  Container buildViewContent() {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Icon(
              Icons.face_unlock_sharp,
              size: 128.0,
              color: CupertinoColors.inactiveGray,
            ),
          ),
          Text(
            'Need to search for someone...huh??',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w300,
                fontSize: 24.0),
          )
        ],
      ),
    );
  }

  buildSearchResults() {
    return FutureBuilder<QuerySnapshot>(
      future: searchResultsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        List<UserResult> searchResults = [];
        snapshot.data.docs.forEach((document) {
          FireUser fireUser = FireUser.fromDocument(document);
          UserResult userResult = UserResult(fireUser: fireUser);
          searchResults.add(userResult);
        });

        return searchResults.isNotEmpty
            ? ListView(
                children: searchResults,
              )
            : buildNoContent();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildSearchHeader(),
      body: searchResultsFuture != null
          ? buildSearchResults()
          : buildViewContent(),
    );
  }
}

class UserResult extends StatelessWidget {
  final FireUser fireUser;

  UserResult({this.fireUser});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return Profile(
                profileId: fireUser.id,
                liveUserId: liveUser.id,
              );
            }));
            print('Is it even working?');
          },
          leading: CircleAvatar(
            backgroundColor: CupertinoColors.systemGrey,
            backgroundImage: CachedNetworkImageProvider(fireUser.photoUrl),
          ),
          title: Text(
            fireUser.displayName,
            style: TextStyle(color: Colors.black, fontSize: 16.0),
          ),
          subtitle: Text(
            '@${fireUser.username}',
            style: TextStyle(color: Colors.black54, fontSize: 12.0),
          ),
        ),
        Divider(height: 2.0)
      ],
    );
  }
}
