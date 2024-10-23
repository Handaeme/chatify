import 'dart:io';

import 'package:chatify/group_chats/group_info.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class GroupChatRoom extends StatefulWidget {
  final String groupChatId, groupName;

  GroupChatRoom({required this.groupName, required this.groupChatId, Key? key})
      : super(key: key);

  @override
  _GroupChatRoomState createState() => _GroupChatRoomState();
}

class _GroupChatRoomState extends State<GroupChatRoom> {
  final TextEditingController _message = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  File? _imageFile;
  bool isUploading = false;
  final ImagePicker _picker = ImagePicker();

  // Function to send text messages
  void onSendMessage() async {
    if (_message.text.isNotEmpty) {
      Map<String, dynamic> chatData = {
        "sendBy": _auth.currentUser!.displayName,
        "message": _message.text,
        "type": "text",
        "time": FieldValue.serverTimestamp(),
      };

      _message.clear();

      await _firestore
          .collection('groups')
          .doc(widget.groupChatId)
          .collection('chats')
          .add(chatData);

      // Update last message
      await _firestore.collection('groups').doc(widget.groupChatId).update({
        'lastMessage': _message.text,
        'lastMessageSender': _auth.currentUser!.displayName,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }
  }

  // Function to select image from gallery
  Future pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        isUploading = true; // Show uploading indicator
      });
      uploadImage();
    }
  }

  // Function to upload image to Firebase Storage
  Future uploadImage() async {
    if (_imageFile != null) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference reference = _storage.ref().child('groupImages').child(fileName);

      try {
        UploadTask uploadTask = reference.putFile(_imageFile!);
        TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);

        String imageUrl = await snapshot.ref.getDownloadURL();

        sendImageMessage(imageUrl);
      } catch (error) {
        print("Error uploading image: $error");
      } finally {
        setState(() {
          isUploading = false; // Hide uploading indicator
        });
      }
    }
  }

  // Function to send image message
  void sendImageMessage(String imageUrl) async {
    Map<String, dynamic> chatData = {
      "sendBy": _auth.currentUser!.displayName,
      "message": imageUrl,
      "type": "img",
      "time": FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('groups')
        .doc(widget.groupChatId)
        .collection('chats')
        .add(chatData);

    // Update last message with image
    await _firestore.collection('groups').doc(widget.groupChatId).update({
      'lastMessage': '📷 Image',
      'lastMessageSender': _auth.currentUser!.displayName,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final Color primaryColor = Color(0xFF0719B7);
    final Color secunderColor = Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        backgroundColor: primaryColor,
        foregroundColor: secunderColor,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GroupInfo(
                  groupName: widget.groupName,
                  groupId: widget.groupChatId,
                ),
              ),
            ),
            icon: Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('groups')
                  .doc(widget.groupChatId)
                  .collection('chats')
                  .orderBy('time')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("No chats available"));
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> chatMap = snapshot.data!.docs[index]
                          .data() as Map<String, dynamic>;

                      return messageTile(size, chatMap);
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
                      borderRadius:
                          BorderRadius.circular(30), // Floating effect
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _message,
                            decoration: InputDecoration(
                              hintText: "Send Message",
                              border: InputBorder.none, // No border
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 14),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.photo, color: primaryColor),
                          onPressed: pickImage,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8), // Space between textfield and send button
                Container(
                  decoration: BoxDecoration(
                    color: primaryColor, // Background color
                    shape: BoxShape.circle, // Circular button
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26, // Shadow for floating effect
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
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

  Widget messageTile(Size size, Map<String, dynamic> chatMap) {
    bool isMe = chatMap['sendBy'] == _auth.currentUser!.displayName;

    return Container(
      width: size.width,
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: chatMap['type'] == "text"
          ? Container(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: isMe ? Color(0xFF0719B7) : Colors.grey[300],
              ),
              child: Text(
                chatMap['message'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isMe ? Colors.white : Colors.black,
                ),
              ),
            )
          : Container(
              height: size.height / 3,
              width: size.width / 2,
              margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.grey[300],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  chatMap['message'],
                  fit: BoxFit.cover,
                ),
              ),
            ),
    );
  }
}
