import 'package:chatify/HomeScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class CreateGroup extends StatefulWidget {
  final List<Map<String, dynamic>> membersList;

  const CreateGroup({required this.membersList, Key? key}) : super(key: key);

  @override
  State<CreateGroup> createState() => _CreateGroupState();
}

class _CreateGroupState extends State<CreateGroup> {
  final TextEditingController _groupName = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false;

  void createGroup() async {
    setState(() {
      isLoading = true;
    });

    String groupId = Uuid().v1();

    // Create the group document in 'groups' collection
    await _firestore.collection('groups').doc(groupId).set({
      "members": widget.membersList,
      "id": groupId,
      "groupName": _groupName.text,
    });

    // Loop through members list and ensure the 'uid' is not null
    for (int i = 0; i < widget.membersList.length; i++) {
      String? uid = widget.membersList[i]['uid'];

      if (uid != null) {
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('groups')
            .doc(groupId)
            .set({
          "name": _groupName.text,
          "id": groupId,
        });
      } else {
        print("Skipping member at index $i due to null UID");
      }
    }

    // Add an initial chat message notifying that the group is created
    await _firestore.collection('groups').doc(groupId).collection('chats').add({
      "message": "${_auth.currentUser!.displayName} Created This Group.",
      "type": "notify",
      "timestamp": FieldValue.serverTimestamp(),
    });

    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Color(0xFF0719B7), // Warna latar belakang utama
      appBar: AppBar(
        title: Text("Group Name"),
        backgroundColor: Color(0xFF0719B7),
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: size.width,
        height: size.height,
        decoration: ShapeDecoration(
          color: Colors.white, // Background dalam container menjadi putih
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
        ),
        child: isLoading
            ? Container(
                height: size.height,
                width: size.width,
                alignment: Alignment.center,
                child: CircularProgressIndicator(
                  color: Colors.white, // Warna indikator loading putih
                ),
              )
            : SingleChildScrollView(
                // Memastikan layout tidak terpotong pada layar kecil
                child: Column(
                  children: [
                    SizedBox(
                      height: size.height / 10,
                    ),
                    Container(
                      height: size.height / 14,
                      width: size.width,
                      alignment: Alignment.center,
                      child: Container(
                        height: size.height / 14,
                        width: size.width / 1.15,
                        child: TextField(
                          controller: _groupName,
                          decoration: InputDecoration(
                            hintText: "Enter Group Name",
                            hintStyle: TextStyle(
                                color: Colors
                                    .black), // Set hint text warna hitam agar terlihat di background putih
                            filled: true,
                            fillColor: Colors
                                .white, // Background putih untuk input box
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors
                                      .black), // Warna border hitam untuk kontras
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors
                                      .black), // Border ketika input tidak fokus
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Color(
                                      0xFF0719B7)), // Border biru saat fokus
                            ),
                          ),
                          style: TextStyle(
                              color: Colors
                                  .black), // Warna teks diubah menjadi hitam untuk input box
                        ),
                      ),
                    ),
                    SizedBox(
                      height: size.height / 50,
                    ),
                    ElevatedButton(
                      onPressed: createGroup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(
                            0xFF0719B7), // Warna biru untuk konsistensi dengan desain lainnya
                        padding: EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              10), // Rounded corner untuk tombol
                        ),
                      ),
                      child: Text(
                        "Create Group",
                        style: TextStyle(
                            color: Colors
                                .white), // Teks tombol putih agar terlihat jelas
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
