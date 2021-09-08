import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:novel/models/user_model.dart';
import 'package:novel/widgets/progress.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as Im;
import 'package:uuid/uuid.dart';

class Upload extends StatefulWidget {
  final FireUser fireUser;

  Upload({this.fireUser});

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  File _image;
  final picker = ImagePicker();
  bool isUploading = false;
  String postId = Uuid().v4();
  final storageRef = FirebaseStorage.instance.ref();
  final postsRef = FirebaseFirestore.instance.collection('posts');
  TextEditingController captionController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  final DateTime timestamp = DateTime.now();

  Future getImage() async {
    Navigator.pop(context);
    final pickedFile = await picker.getImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future getGallery() async {
    Navigator.pop(context);
    final pickedFileGallery =
        await picker.getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFileGallery != null) {
        _image = File(pickedFileGallery.path);
      } else {
        print('No image from Gallery is selected.');
      }
    });
  }

  Container buildViewContent(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Icon(
              Icons.cloud_upload_outlined,
              size: 128.0,
              color: CupertinoColors.inactiveGray,
            ),
          ),
          InkWell(
            onTap: () {
              showCupertinoModalPopup(
                  context: context, builder: (context) => createPostDialog());
            },
            borderRadius: BorderRadius.circular(100.0),
            child: Container(
              decoration: BoxDecoration(
                color: CupertinoColors.activeBlue,
                borderRadius: BorderRadius.circular(100.0),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
              child: Text(
                'Create Moments',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  createPostDialog() {
    return Container(
      child: CupertinoActionSheet(
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Create Post',
            style: TextStyle(
                fontSize: 32.0,
                color: Colors.black,
                fontWeight: FontWeight.w700),
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            child: Text(
              'Photo from Camera',
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
            onPressed: getImage,
          ),
          CupertinoActionSheetAction(
            child: Text(
              'Image From Gallery',
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
            onPressed: getGallery,
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text(
            'Cancel',
          ),
          onPressed: () {
            Navigator.pop(context);
          },
          isDestructiveAction: true,
        ),
      ),
    );
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image imageFile = Im.decodeImage(_image.readAsBytesSync());
    final compressedImageFile = File('$path/img_$postId.jpg')
      ..writeAsBytesSync(Im.encodeJpg(imageFile, quality: 85));
    setState(() {
      _image = compressedImageFile;
    });
  }

  Future<String> uploadImage(fileImage) async {
    await storageRef
        .child('post_$postId.jpg')
        .putFile(fileImage)
        .catchError((err) {
      print('Error in uploading image = $err');
    });
    String downloadUrl =
        await storageRef.child('post_$postId.jpg').getDownloadURL();
    return downloadUrl;
  }

  createPostInFirebase({String mediaUrl, String location, String description}) {
    postsRef.doc(widget.fireUser.id).collection('userPosts').doc(postId).set({
      'postId': postId,
      'ownerId': widget.fireUser.id,
      'username': widget.fireUser.username,
      'mediaUrl': mediaUrl,
      'location': location,
      'description': description,
      'timestamp': timestamp,
      'likes': {},
    });
  }

  handleSubmit() async {
    setState(() {
      isUploading = true;
    });
    await compressImage();
    final mediaUrl = await uploadImage(_image);
    createPostInFirebase(
      mediaUrl: mediaUrl,
      location: locationController.text,
      description: captionController.text,
    );
    captionController.clear();
    locationController.clear();
    setState(() {
      _image = null;
      isUploading = false;
      postId = Uuid().v4();
    });
  }

  getCurrentUserLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await GeocodingPlatform.instance
        .placemarkFromCoordinates(position.latitude, position.latitude)
        .catchError((err) {
      print('Error in catching place = $err');
    });
    final Placemark placemark = placemarks[0];
    String completeAddress = '${placemark.locality}, ${placemark.country}';
    locationController.text = completeAddress;
    print(completeAddress);
  }

  Scaffold buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        shape: Border(bottom: BorderSide(color: CupertinoColors.inactiveGray)),
        backgroundColor: CupertinoColors.lightBackgroundGray,
        elevation: 0.0,
        title: Text('Caption Post', style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_sharp,
          ),
          color: Colors.black,
          onPressed: () {
            setState(() {
              _image = null;
            });
          },
        ),
        actions: [
          TextButton(
            child: Text(
              'Publish',
              style: TextStyle(color: CupertinoColors.activeBlue),
            ),
            onPressed: isUploading ? null : () => handleSubmit(),
          )
        ],
      ),
      body: ListView(
        children: [
          isUploading ? linearProgress() : Text(''),
          Container(
            height: MediaQuery.of(context).size.width,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
                image: DecorationImage(
              image: FileImage(
                _image,
              ),
              fit: BoxFit.cover,
            )),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: CupertinoColors.systemGrey,
              backgroundImage: NetworkImage(widget.fireUser.photoUrl),
            ),
            title: TextField(
              controller: captionController,
              decoration: InputDecoration(
                hintText: 'What is this about...?',
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
            ),
          ),
          Divider(
            height: 2.0,
          ),
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.add_location_alt)),
            title: TextField(
              controller: locationController,
              decoration: InputDecoration(
                hintText: 'Where was the photo taken..?',
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
            ),
          ),
          Divider(
            height: 2.0,
          ),
          Container(
            padding: EdgeInsets.all(16.0),
            height: 64.0,
            width: 128.0,
            child: RaisedButton.icon(
              highlightElevation: 0.0,
              disabledElevation: 0.0,
              color: Colors.transparent,
              elevation: 0.0,
              shape: RoundedRectangleBorder(side: BorderSide()),
              onPressed: getCurrentUserLocation,
              icon: Icon(Icons.my_location_outlined),
              label: Text('Use my current location'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _image != null ? buildUploadForm() : buildViewContent(context),
    );
  }
}
