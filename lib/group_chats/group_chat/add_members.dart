import 'package:chatify/group_chats/group_chat/create_group.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddMembersInGroup extends StatefulWidget {
  const AddMembersInGroup({Key? key}) : super(key: key);

  @override
  State<AddMembersInGroup> createState() => _AddMembersInGroupState();
}

class _AddMembersInGroupState extends State<AddMembersInGroup> {
  final TextEditingController _search = TextEditingController();
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> membersList = [];
  bool isLoading = false;
  Map<String, dynamic>? userMap;

  @override
  void initState() {
    super.initState();
    getCurrentUserDetails();
  }

  void getCurrentUserDetails() async {
    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .get()
        .then((map) {
      setState(() {
        membersList.add({
          "name": map['name'],
          "email": map['email'],
          "uid": map['uid'],
          "isAdmin": true,
        });
      });
    });
  }

  void onSearch() async {
    setState(() {
      isLoading = true;
    });

    await _firestore
        .collection('users')
        .where("email", isEqualTo: _search.text)
        .get()
        .then((value) {
      if (value.docs.isNotEmpty) {
        setState(() {
          userMap = value.docs[0].data();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          userMap = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No user found with this email")),
        );
      }
    });
  }

  void onResultTap() {
    bool isAlreadyExist = false;

    for (int i = 0; i < membersList.length; i++) {
      if (membersList[i]['uid'] == userMap!['uid']) {
        isAlreadyExist = true;
      }
    }

    if (!isAlreadyExist) {
      setState(() {
        membersList.add({
          "name": userMap!['name'],
          "email": userMap!['email'],
          "uid": userMap!['uid'],
          "isAdmin": false,
        });

        userMap = null;
      });
    }
  }

  void onRemoveMembers(int index) {
    if (membersList[index]['uid'] != _auth.currentUser!.uid) {
      setState(() {
        membersList.removeAt(index);
      });
    }
  }

  String getInitials(String name) {
    return name.isNotEmpty
        ? name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : '';
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Color(0xFF0A1233),
      appBar: AppBar(
        title: Text(
          "Add Members",
          style: TextStyle(fontFamily: 'JosefinSans'),
        ),
        backgroundColor: Color(0xFF0A1233),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ListView.builder(
                itemCount: membersList.length,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: () => onRemoveMembers(index),
                    leading: CircleAvatar(
                      backgroundColor: Colors.red,
                      child: Text(
                        getInitials(membersList[index]['name']),
                        style: TextStyle(
                          fontFamily: 'JosefinSans',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      membersList[index]['name'],
                      style: TextStyle(
                          fontFamily: 'JosefinSans',
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                    subtitle: Text(
                      membersList[index]['email'],
                      style: TextStyle(
                        fontFamily: 'JosefinSans',
                        color: Color(0xFF718096),
                      ),
                    ),
                    trailing: Icon(Icons.close, color: Colors.red),
                  );
                },
              ),
            ),
            SizedBox(
              height: size.height / 20,
            ),
            Container(
              height: size.height / 14,
              width: size.width,
              alignment: Alignment.center,
              child: Container(
                height: size.height / 14,
                width: size.width / 1.15,
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: "Search by Email",
                    hintStyle: TextStyle(
                      fontFamily: 'JosefinSans',
                      color: Color(0xFF718096),
                      fontSize: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.red), // Set outline color here
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.red), // Set focused outline color
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.white), // Set enabled outline color
                    ),
                  ),
                  style: TextStyle(
                    fontFamily: 'JosefinSans',
                    color: Colors.white, // Set the color of the input text here
                    fontSize:
                        16, // Optional: adjust the font size of the input text
                  ),
                ),
              ),
            ),
            SizedBox(
              height: size.height / 50,
            ),
            isLoading
                ? Container(
                    height: size.height / 12,
                    width: size.height / 12,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(),
                  )
                : ElevatedButton(
                    onPressed: onSearch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                    ),
                    child: Text(
                      "Search",
                      style: TextStyle(
                          fontFamily: 'JosefinSans',
                          fontSize: 16,
                          color: Colors.white),
                    ),
                  ),
            userMap != null
                ? ListTile(
                    onTap: onResultTap,
                    leading: CircleAvatar(
                      backgroundColor: Colors.red,
                      child: Text(
                        getInitials(userMap!['name']),
                        style: TextStyle(
                          fontFamily: 'JosefinSans',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      userMap!['name'],
                      style: TextStyle(
                          fontFamily: 'JosefinSans', color: Colors.white),
                    ),
                    subtitle: Text(
                      userMap!['email'],
                      style: TextStyle(
                          fontFamily: 'JosefinSans', color: Color(0xFF718096)),
                    ),
                    trailing: Icon(Icons.add, color: Colors.green),
                  )
                : SizedBox(),
          ],
        ),
      ),
      floatingActionButton: membersList.length >= 2
          ? FloatingActionButton(
              backgroundColor: Colors.red,
              child: Icon(Icons.forward, color: Colors.white),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CreateGroup(
                    membersList: membersList,
                  ),
                ),
              ),
            )
          : SizedBox(),
    );
  }
}
