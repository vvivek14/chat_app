import 'dart:convert';
import 'dart:developer';

import 'package:chat_app/main.dart';
import 'package:chat_app/models/chat_room.dart';
import 'package:chat_app/models/message_model.dart';
import 'package:chat_app/models/users_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class ChatRoomPage extends StatefulWidget {
  // var userNameNotification = widget.userModel.
  final UserModel targetUser;
  final ChatRoomModel chatRoom;
  final UserModel userModel;
  final User firebaseUser;

  const ChatRoomPage(
      {Key? key,
      required this.userModel,
      required this.firebaseUser,
      required this.targetUser,
      required this.chatRoom})
      : super(key: key);

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  TextEditingController messageController = TextEditingController();

  void sendMessage() async {
    String msg = messageController.text.trim();
    messageController.clear();

    MessageModel newMessage = MessageModel(
      messageId: uuid.v1(),
      sender: widget.userModel.uid,
      createdon: DateTime.now(),
      text: msg,
      seen: false,
    );

    var targetUserId = widget.targetUser.uid.toString();
    print(targetUserId);
    // log(widget.targetUser.uid.toString());
    FirebaseFirestore.instance
        .collection("Chatrooms")
        .doc(widget.chatRoom.chatroomid)
        .collection("messages")
        .doc(newMessage.messageId)
        .set(newMessage.toMap());

    widget.chatRoom.lastMessage = msg;
    FirebaseFirestore.instance
        .collection("Chatrooms")
        .doc(widget.chatRoom.chatroomid)
        .set(widget.chatRoom.toMap());

    DocumentSnapshot<Map<String, dynamic>> data = await FirebaseFirestore
        .instance
        .collection('user')
        .doc(targetUserId)
        .get();

    final targetObject = data.data();
    final notificationToken = targetObject!['fcm_token'];
    print("--------------------receiver token----------------------------");
    print(notificationToken);
    print("--------------------receiver token----------------------------");

    log(notificationToken);
    log("Message Sent!");

    Future<http.Response?> sendNotification(String message) async {
      final data = {
        "to": notificationToken,
        "notification": {
          "body": message,
          // "title": username,
          "android_channel_id": "pushnotificationapp",
          "image":
              "https://cdn2.vectorstock.com/i/1000x1000/23/91/small-size-emoticon-vector-9852391.jpg",
          "sound": true
        }
      };

      final sendData = jsonEncode(data);
  
  
      try {
        http.Response response = await http.post(
          Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization':
                'key=AAAAUnTav6c:APA91bHSKG6-tL3eyscq2p2fl8ikTwBEWjKO4jnzNNa3R_aDd231-8O1DYavlOGspJo_3cLn5MWclqTchO2Yzrp0q1Fvqu2w8DRfmLUkYbxamcdqn-RclpeHxgjpqCgDyDUsZML7R6r5'
            //  AAAAIGLSWxg:APA91bEKSYsFnG6-mQbuTxKdabis20uNzCPSa_GInVE9Fg61wb9K6Xh1zXaX2CAeCGl5FhlGWfWsFeD16gUZGTLRJfjJF-Kqd6KTuD1ViwclQPe9znZ_a1BpXGlV0MDBEi8wSWQSadaQ'
          },
          body: sendData,
        );

        if (response.statusCode == 200) {
          log('notification sent');
          print(response.body);
        } else {
          print('error occured');
        }
      } catch (error) {
        print(error);
      }
      return null;
    }

    sendNotification(msg);
  }

  @override
  Widget build(BuildContext context) {
    var userFullName = widget.targetUser.fullname;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple.shade200,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              backgroundImage:
                  NetworkImage(widget.targetUser.profilepic.toString()),
            ),
            const SizedBox(width: 10),
            Text(userFullName.toString()),
          ],
        ),
      ),
      body: SafeArea(
          child: Column(
        children: [
          Expanded(
              child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection("Chatrooms")
                    .doc(widget.chatRoom.chatroomid)
                    .collection("messages")
                    .orderBy("createdon", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.active) {
                    if (snapshot.hasData) {
                      QuerySnapshot dataSnapshot =
                          snapshot.data as QuerySnapshot;

                      return ListView.builder(
                        reverse: true,
                        itemCount: dataSnapshot.docs.length,
                        itemBuilder: (context, index) {
                          MessageModel currentMessage = MessageModel.forMap(
                              dataSnapshot.docs[index].data()
                                  as Map<String, dynamic>);
                          return Row(
                            mainAxisAlignment:
                                (currentMessage.sender == widget.userModel.uid)
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                            children: [
                              currentMessage.sender != widget.userModel.uid
                                  ? CircleAvatar(
                                      backgroundImage: NetworkImage(widget
                                          .targetUser.profilepic
                                          .toString()),
                                      radius: 14,
                                    )
                                  : const SizedBox(),
                              const SizedBox(width: 5),
                              Container(
                                margin: const EdgeInsets.symmetric(vertical: 3),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: (currentMessage.sender ==
                                          widget.userModel.uid)
                                      ? Colors.deepPurple.shade100
                                      : Colors.deepPurple.shade300,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.6,
                                  ),
                                  child: Text(
                                    currentMessage.text.toString(),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    } else if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                            "An error occured! Please check your internet connection."),
                      );
                    } else {
                      return const Center(
                        child: Text("Say hi to your new friend"),
                      );
                    }
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                }),
          )),
          Container(
            color: Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 5,
            ),
            child: Row(
              children: [
                Flexible(
                  child: TextFormField(
                    controller: messageController,
                    maxLines: null,
                    decoration: const InputDecoration(
                        border: InputBorder.none, hintText: "Enter message"),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (messageController.text.isNotEmpty) {
                      sendMessage();
                    }
                  },
                  icon: const Icon(Icons.send),
                  color: Colors.deepPurple,
                )
              ],
            ),
          )
        ],
      )),
    );
  }
}
