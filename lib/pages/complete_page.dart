import 'dart:developer';
import 'dart:io';

import 'package:chat_app/models/ui_helper.dart';
import 'package:chat_app/models/users_model.dart';
import 'package:chat_app/pages/home-page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class CompletePage extends StatefulWidget {
  final UserModel userModel;
  final User firebaseUser;
  const CompletePage(
      {Key? key, required this.userModel, required this.firebaseUser})
      : super(key: key);

  @override
  State<CompletePage> createState() => _CompletePageState();
}

class _CompletePageState extends State<CompletePage> {
  File? imageFile;
  TextEditingController fullNameController = TextEditingController();

  void selectImage(ImageSource source) async {
    XFile? pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile != null) {
      File? pickFile = File(pickedFile.path);
      cropImage(pickFile);
    }
  }

  void cropImage(File file) async {
    CroppedFile? croppedImage = await ImageCropper().cropImage(
      sourcePath: file.path,
      compressQuality: 20,
      aspectRatioPresets: Platform.isAndroid
          ? [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ]
          : [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio5x3,
              CropAspectRatioPreset.ratio5x4,
              CropAspectRatioPreset.ratio7x5,
              CropAspectRatioPreset.ratio16x9
            ],
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.white,
            toolbarWidgetColor: Colors.deepPurple,
            initAspectRatio: CropAspectRatioPreset
                .ratio3x2, //CropAspectRatioPreset.original,
            lockAspectRatio: false),
        IOSUiSettings(
          title: 'Crop Image',
        ),
      ],
    );
    if (croppedImage != null) {
      setState(() {
        imageFile = File(croppedImage.path);
      });
    }
  }

  void showPhotoOptione() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Upload Profile Picture"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  onTap: () {
                    Navigator.pop(context);
                    selectImage(ImageSource.gallery);
                  },
                  leading: Icon(Icons.photo_library_outlined),
                  title: Text('Select from Gallery'),
                ),
                ListTile(
                  onTap: () {
                    Navigator.pop(context);

                    selectImage(ImageSource.camera);
                  },
                  leading: Icon(Icons.camera_alt_outlined),
                  title: Text('Tack a photo'),
                ),
              ],
            ),
          );
        });
  }

  void checkValue() {
    String fullname = fullNameController.text.trim();

    if (fullname == "" || imageFile == null) {
      log("Please fill all the fields");
      print("Please fill all the fields");
      UIHelper.showAlertDialog(context, 'Incomplete data',
          "Please fill all the fileds and a upload a profile pictures");  
    } else {
      uploadData();
    }
  }

  void uploadData() async {
    UIHelper.showLoadingDialog(context, "Uploading Image...");
    UploadTask uploadTask = FirebaseStorage.instance
        .ref("profilepitures")
        .child(widget.userModel.uid.toString())
        .putFile(imageFile!);

    TaskSnapshot snapshot = await uploadTask;
    String imageUrl = await snapshot.ref.getDownloadURL();
    String fullname = fullNameController.text.trim();

    widget.userModel.fullname = fullname;
    widget.userModel.profilepic = imageUrl;

    await FirebaseFirestore.instance
        .collection("user")
        .doc(widget.userModel.uid)
        .set(widget.userModel.toMap())
        .then((value) {
      log("DataUploaded !");
      // print("DataUploaded !");
      Navigator.popUntil(context, (route) => route.isFirst);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) {
          return Homepage(
            userModel: widget.userModel,
            firebaseUser: widget.firebaseUser,
          );
        }),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.deepPurple.shade200,
        title: Text(
          'Complete Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.deepPurple,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Container(
          child: ListView(
            children: [
              CupertinoButton(
                child: CircleAvatar(
                  backgroundColor: Colors.deepPurple.shade200,
                  backgroundImage:
                      imageFile != null ? FileImage(imageFile!) : null,
                  radius: 60,
                  child: imageFile == null
                      ? Icon(
                          Icons.person,
                          color: Colors.deepPurple,
                          size: 60,
                        )
                      : null,
                ),
                onPressed: () {
                  showPhotoOptione();
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: fullNameController,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.deepPurple, width: 1),
                  ),
                  fillColor: Colors.white,
                  filled: true,
                  hintText: 'Full Name',
                ),
              ),
              SizedBox(height: 20),
              CupertinoButton(
                child: Text(
                  "Submit",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                onPressed: () {
                  checkValue();
                },
                color: Colors.deepPurple.shade200,
              ),
            ],
          ),
        ),
      )),
    );
  }
}
