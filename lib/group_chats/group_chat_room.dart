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

      await _firestore.collection('groups').doc(widget.groupChatId).update({
        'lastMessage': _message.text,
        'lastMessageSender': _auth.currentUser!.displayName,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }
  }

  Future pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        isUploading = true;
      });
      uploadImage();
    }
  }

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
          isUploading = false;
        });
      }
    }
  }

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
    final Color primaryColor = Color(0xFF0A1233);
    final Color secunderColor = Colors.white;

    return Scaffold(
      backgroundColor: Color(0xFF0A1233),
      appBar: AppBar(
        title:
            Text(widget.groupName, style: TextStyle(fontFamily: 'JosefinSans')),
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
                    return Center(
                        child: Text("No chats available",
                            style: TextStyle(fontFamily: 'JosefinSans')));
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
                      color: Color(0xFF718096),
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
                              hintStyle: TextStyle(
                                  fontFamily: 'JosefinSans',
                                  color:
                                      const Color.fromARGB(255, 188, 188, 188)),
                              border: InputBorder.none, // No border
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 14),
                            ),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.photo, color: Colors.white),
                          onPressed: pickImage,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
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
                color: isMe ? Colors.red : Colors.grey[300],
              ),
              child: Text(
                chatMap['message'],
                style: TextStyle(
                  fontFamily: 'JosefinSans',
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
