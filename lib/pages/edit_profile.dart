import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:novel/models/user_model.dart';
import 'package:novel/widgets/header.dart';
import 'package:novel/widgets/progress.dart';

class EditProfile extends StatefulWidget {
  final String liveUserId;
  EditProfile({this.liveUserId});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  // final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isLoading = false;
  final userRef = FirebaseFirestore.instance.collection('users');
  FireUser liveUser;
  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  bool _bioValid = true;
  bool _displayNameValid = true;

  getUser() async {
    setState(() {
      isLoading = true;
    });
    DocumentSnapshot document = await userRef.doc(widget.liveUserId).get();
    liveUser = FireUser.fromDocument(document);
    displayNameController.text = liveUser.displayName;
    bioController.text = liveUser.bio;
    setState(() {
      isLoading = false;
    });
  }

  updateProfileDate() {
    setState(() {
      displayNameController.text.trim().length < 3 ||
              displayNameController.text.isEmpty
          ? _displayNameValid = false
          : _displayNameValid = true;
      bioController.text.trim().length > 999
          ? _bioValid = false
          : _bioValid = true;
    });
    if (_displayNameValid && _bioValid) {
      userRef.doc(widget.liveUserId).update({
        'displayName': displayNameController.text,
        'bio': bioController.text,
      });
      // SnackBar snackBarProfile = SnackBar(
      //   content: Text('Profile Updated!'),
      //   key: _scaffoldKey,
      // );
      //TODO: do the Snack bar with the latest format
      // _scaffoldKey.currentState.showSnackBar(snackBarProfile);
    }
  }

  @override
  void initState() {
    getUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          header(context: context, headline: 'Edit Profile', isLeading: true),
      body: isLoading
          ? circularProgress()
          : Container(
              alignment: Alignment.center,
              child: ListView(
                children: [
                  SizedBox(height: 48.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipOval(
                        child: Container(
                          height: 156.0,
                          width: 156.0,
                          child: AspectRatio(
                            aspectRatio: 1 / 1,
                            child: Image(
                              image: NetworkImage(liveUser.photoUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.0),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: displayNameController,
                      decoration: InputDecoration(
                        labelText: 'Display Name',
                        errorText: _displayNameValid
                            ? null
                            : 'Display Name is too short',
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: bioController,
                      decoration: InputDecoration(
                        labelText: 'Bio',
                        errorText: _bioValid ? null : 'Bio is too long',
                      ),
                    ),
                  ),
                  SizedBox(height: 48.0),
                  RaisedButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0.0)),
                    elevation: 0.0,
                    disabledElevation: 0.0,
                    highlightElevation: 0.0,
                    hoverElevation: 0.0,
                    focusElevation: 0.0,
                    padding:
                        EdgeInsets.symmetric(horizontal: 64.0, vertical: 16.0),
                    child: Text(
                      'Update',
                      style: TextStyle(color: Colors.white),
                    ),
                    color: CupertinoColors.activeBlue,
                    onPressed: updateProfileDate,
                  )
                ],
              ),
            ),
    );
  }
}
