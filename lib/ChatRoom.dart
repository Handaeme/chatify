import 'dart:io';

import 'package:chatify/push_notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ChatRoom extends StatefulWidget {
  final Map<String, dynamic> userMap;
  final String chatRoomId;

  ChatRoom({required this.chatRoomId, required this.userMap});

  @override
  _ChatRoomState createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  final TextEditingController _message = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PushNotificationService _pushNotificationService =
      PushNotificationService();
  final ScrollController _scrollController = ScrollController();

  File? imageFile;
  bool isUploading = false;

  Future<void> getImage() async {
    ImagePicker _picker = ImagePicker();
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
        isUploading = true;
      });
      await uploadImage();
    }
  }

  Future<void> uploadImage() async {
    String fileName = Uuid().v1();
    try {
      var ref =
          FirebaseStorage.instance.ref().child('images').child("$fileName.jpg");
      var uploadTask = await ref.putFile(imageFile!);
      String imageUrl = await uploadTask.ref.getDownloadURL();

      Map<String, dynamic> imageMessage = {
        "sendby": _auth.currentUser!.uid,
        "message": imageUrl,
        "type": "img",
        "time": FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('chatRooms')
          .doc(widget.chatRoomId)
          .collection('chats')
          .doc(fileName)
          .set(imageMessage);
      await updateLastMessage('📷 Image');

      await _pushNotificationService.sendNotification(
          widget.userMap['fcmToken'], '📷 Image', 'Image sent');

      setState(() {
        isUploading = false;
      });
    } catch (error) {
      setState(() {
        isUploading = false;
      });
      print("Error uploading image: $error");
    }
  }

  Future<void> onSendMessage() async {
    if (_message.text.trim().isNotEmpty) {
      try {
        String messageText = _message.text.trim();
        Map<String, dynamic> messages = {
          "sendby": _auth.currentUser!.uid,
          "message": messageText,
          "type": "text",
          "time": FieldValue.serverTimestamp(),
        };

        _message.clear();

        await _firestore
            .collection('chatRooms')
            .doc(widget.chatRoomId)
            .collection('chats')
            .add(messages);

        await updateLastMessage(messageText);

        final fcmToken = widget.userMap['fcmToken'];
        if (fcmToken != null) {
          await _pushNotificationService.sendNotification(
              fcmToken, 'New Message', messageText);
        }
      } catch (e) {
        print("Error sending message: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send message")),
        );
      }
    }
  }

  Future<void> updateLastMessage(String messageText) async {
    final chatRoomRef =
        _firestore.collection('chatRooms').doc(widget.chatRoomId);

    await chatRoomRef.set({
      'lastMessage': messageText,
      'lastMessageSender': _auth.currentUser!.uid,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'users': [_auth.currentUser!.uid, widget.userMap['uid']],
    }, SetOptions(merge: true));
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final Color primaryColor = Color(0xFF0719B7);

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: StreamBuilder<DocumentSnapshot>(
          stream: _firestore
              .collection("users")
              .doc(widget.userMap['uid'])
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.exists) {
              var userData = snapshot.data!.data() as Map<String, dynamic>;
              String name = widget.userMap['name'] ?? 'Unknown User';
              String initials = name.isNotEmpty ? name[0].toUpperCase() : "U";

              return Row(
                children: [
                  CircleAvatar(
                    child: Text(initials,
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    backgroundColor: Colors.pink,
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20)),
                      Text(userData['status'] ?? 'Offline',
                          style:
                              TextStyle(fontSize: 14, color: Colors.white70)),
                    ],
                  ),
                ],
              );
            } else {
              return Text(widget.userMap['name'] ?? 'Unknown User',
                  style: TextStyle(color: Colors.white));
            }
          },
        ),
        backgroundColor: primaryColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chatRooms')
                  .doc(widget.chatRoomId)
                  .collection('chats')
                  .orderBy("time", descending: false)
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("No chat available"));
                  }
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _scrollToBottom());

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> map = snapshot.data!.docs[index]
                          .data() as Map<String, dynamic>;
                      return messages(size, map, context);
                    },
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          if (isUploading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _message,
                            decoration: InputDecoration(
                              hintText: "Send Message",
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 14),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.photo, color: primaryColor),
                          onPressed: getImage,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2)),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: onSendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget messages(Size size, Map<String, dynamic> map, BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Column(
        crossAxisAlignment: map['sendby'] == _auth.currentUser!.uid
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          map['type'] == "text"
              ? Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: map['sendby'] == _auth.currentUser!.uid
                        ? Color(0xFF0719B7)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    map['message'] ?? '',
                    style: TextStyle(
                      color: map['sendby'] == _auth.currentUser!.uid
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                )
              : Container(
                  padding: EdgeInsets.all(10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(map['message'] ?? '', width: 200),
                  ),
                ),
        ],
      ),
    );
  }
}
