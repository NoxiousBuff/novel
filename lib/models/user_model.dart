import 'package:cloud_firestore/cloud_firestore.dart';

class FireUser {
  final String id;
  final String displayName;
  final String email;
  final String photoUrl;
  final String bio;
  final String username;

  FireUser({
    this.id,
    this.displayName,
    this.email,
    this.photoUrl,
    this.bio,
    this.username,
  });

  //deserializing the user document

  factory FireUser.fromDocument(DocumentSnapshot doc) {
    return FireUser(
      id: doc['id'],
      email: doc['email'],
      displayName: doc['displayName'],
      photoUrl: doc['photoUrl'],
      bio: doc['bio'],
      username: doc['username'],
    );
  }
}
