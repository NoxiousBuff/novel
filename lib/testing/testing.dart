import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Testing extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Container(
          child: TextButton(
            child: Text('Upload Data'),
            onPressed: () {
              FirebaseFirestore.instance.collection('testing').add({
                'id': 'user.id',
                'username': 'usernameTech.text',
                'photoUrl': 'user.photoUrl',
                'email': 'user.email',
                'displayName': 'user.displayName',
                'bio': '',
                'timestamp': 'timestamp',
              }).catchError((e) {
                print('Error in uploading data = $e');
              });
            },
          ),
        ),
      ),
    );
  }
}
