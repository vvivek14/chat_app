import 'package:chat_app/models/chat_room.dart';
import 'package:chat_app/models/users_model.dart';
import 'package:chat_app/notifiction/local_notofiction.dart';
import 'package:chat_app/pages/firebase_helper.dart';
import 'package:chat_app/pages/login_page.dart';
import 'package:chat_app/pages/search_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chatroom_page.dart';

class Homepage extends StatefulWidget {
  final UserModel userModel;
  final User firebaseUser;

  const Homepage(
      {Key? key, required this.userModel, required this.firebaseUser})
      : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  String deviceTokenToSendPushNotifiction = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    // method:-app close tyare:
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      print("----------------------------------------------------------------");

      print("FiarebaseMessaging.instance.getInitialMessage");
      if (message != null) {
        print("New  Notification");
      }
    });

    //method:-app open hoi tyare:-
    FirebaseMessaging.onMessage.listen((message) {
      print("FirebaseMessaging.onMessage.listen");
      if (message.notification != null) {
        print(
            "----------------------------------------------------------------");
        print(message.notification!.title);
        print(message.notification!.body);
        print("message.data11 ${message.data}");
        LocalNotifiction.createanddisplaynotification(message);
      }
    });

    // method 3:app background ma hoi tyare:-

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print("FirebaseMessaging.onMessageOpenedApp.listen");
      if (message.notification != null) {
        print(
            "----------------------------------------------------------------");

        print(message.notification!.title);
        print(message.notification!.body);
        print("message.data22 ${message.data['_id']}");
      }
    });
  }

  Future<void> getDeviceTokenToSendNotifiction() async {
    final FirebaseMessaging _fcm = FirebaseMessaging.instance;
    final token = await _fcm.getToken();
    deviceTokenToSendPushNotifiction = token.toString();
    final pref = await SharedPreferences.getInstance();
    await pref.setString("userToken", deviceTokenToSendPushNotifiction);
    print("Token Value $deviceTokenToSendPushNotifiction");
  }

  @override
  Widget build(BuildContext context) {
    getDeviceTokenToSendNotifiction();

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade200,
        title: Text('Chat App'),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.popUntil(context, (route) => route.isFirst);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return LoginPage();
                    },
                  ),
                );
              },
              icon: Icon(Icons.logout_outlined))
        ],
      ),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.only(top: 5),
          child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection("Chatrooms")
                .where("participants.${widget.userModel.uid}", isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                if (snapshot.hasData) {
                  QuerySnapshot chatRoomSnapshot =
                      snapshot.data as QuerySnapshot;

                  return ListView.builder(
                      itemCount: chatRoomSnapshot.docs.length,
                      itemBuilder: (context, index) {
                        ChatRoomModel chatRoomModel = ChatRoomModel.fromMap(
                            chatRoomSnapshot.docs[index].data()
                                as Map<String, dynamic>);

                        Map<String, dynamic> participants =
                            chatRoomModel.participants!;

                        List<String> participantKeys =
                            participants.keys.toList();

                        participantKeys.remove(widget.userModel.uid);

                        return FutureBuilder(
                            future: FirebaseHelper.getUserModelById(
                                participantKeys[0]),
                            builder: (context, userData) {
                              if (userData.connectionState ==
                                  ConnectionState.done) {
                                if (userData.data != null) {
                                  UserModel targetUser =
                                      userData.data as UserModel;
                                  return Column(
                                    children: [
                                      ListTile(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) {
                                              return ChatRoomPage(
                                                chatRoom: chatRoomModel,
                                                firebaseUser:
                                                    widget.firebaseUser,
                                                userModel: widget.userModel,
                                                targetUser: targetUser,
                                              );
                                            }),
                                          );
                                        },
                                        dense: true,
                                        visualDensity: VisualDensity.compact,
                                        leading: CircleAvatar(
                                          backgroundImage: NetworkImage(
                                            targetUser.profilepic.toString(),
                                          ),
                                        ),
                                        focusColor: Colors.white,
                                        title: Text(
                                            targetUser.fullname.toString()),
                                        subtitle: (chatRoomModel.lastMessage
                                                    .toString() !=
                                                "")
                                            ? Text(chatRoomModel.lastMessage
                                                .toString())
                                            : Text(
                                                "Say hi to your new friend!",
                                                style: TextStyle(
                                                    color: Colors
                                                        .deepPurple.shade200),
                                              ),
                                      ),
                                      Divider(
                                        thickness: 1,
                                        color:
                                            Colors.deepPurple.withOpacity(0.2),
                                        indent: 65,
                                        endIndent: 10,
                                      )
                                    ],
                                  );
                                } else {
                                  return Container();
                                }
                              } else {
                                return Container();
                              }
                            });
                      });
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(snapshot.error.toString()),
                  );
                } else {
                  return const Center(
                    child: Text("No chats"),
                  );
                }
              } else {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SearchPage(
                userModel: widget.userModel,
                firebaseUser: widget.firebaseUser,
              ),
            ),
          );
        },
        child: Icon(Icons.search),
      ),
    );
  }
}
