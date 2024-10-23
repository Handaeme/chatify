import 'dart:io';

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

  File? imageFile;
  bool isUploading = false;

  // Fungsi untuk memilih gambar dari galeri
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

  // Fungsi untuk mengunggah gambar ke Firebase Storage dan menyimpannya ke Firestore
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

      await _firestore.collection('chatRooms').doc(widget.chatRoomId).update({
        'lastMessage': '📷 Image',
        'lastMessageSender': _auth.currentUser!.uid,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

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

  // Fungsi untuk mengirim pesan teks
  void onSendMessage() async {
    if (_message.text.trim().isNotEmpty) {
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

      await _firestore.collection('chatRooms').doc(widget.chatRoomId).update({
        'lastMessage': messageText,
        'lastMessageSender': _auth.currentUser!.uid,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final Color primaryColor = Color(0xFF0719B7); // Warna utama untuk styling

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
            color: Colors.white), // Menjadikan warna back icon putih
        title: StreamBuilder<DocumentSnapshot>(
          stream: _firestore
              .collection("users")
              .doc(widget.userMap['uid'])
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.exists) {
              var userData = snapshot.data!.data() as Map<String, dynamic>;
              String name = widget.userMap['name'];
              String initials = name.isNotEmpty
                  ? name[0].toUpperCase()
                  : "U"; // Inisial depan

              return Row(
                children: [
                  CircleAvatar(
                    child: Text(
                      initials,
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
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
                      Text(
                        userData['status'],
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              );
            } else {
              return Text(widget.userMap['name'],
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
                  return ListView.builder(
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
                      borderRadius: BorderRadius.circular(30), // Efek melayang
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
                          onPressed: getImage,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                    width: 8), // Small space between textfield and send button
                Container(
                  decoration: BoxDecoration(
                    color: primaryColor, // Background color
                    shape: BoxShape.circle, // Tombol bulat
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26, // Shadow effect
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

  // Fungsi untuk menampilkan pesan teks dan gambar
  Widget messages(Size size, Map<String, dynamic> map, BuildContext context) {
    bool isMe = map['sendby'] == _auth.currentUser!.uid;

    return Container(
      width: size.width,
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: map['type'] == "text"
          ? Container(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              margin: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: isMe ? Color(0xFF0719B7) : Colors.grey[300],
              ),
              child: Text(
                map['message'],
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
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ShowImage(imageUrl: map['message']),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    map['message'],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
    );
  }
}

// Class untuk menampilkan gambar dalam layar penuh
class ShowImage extends StatelessWidget {
  final String imageUrl;

  const ShowImage({required this.imageUrl, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0719B7),
        iconTheme: IconThemeData(
            color: Colors.white), // Ubah warna ikon back menjadi putih
      ),
      body: Container(
        height: size.height,
        width: size.width,
        color: Colors.black,
        child: Center(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }
}
