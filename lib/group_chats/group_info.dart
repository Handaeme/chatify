import 'package:chatify/HomeScreen.dart';
import 'package:chatify/group_chats/add_members.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GroupInfo extends StatefulWidget {
  final String groupId, groupName;
  const GroupInfo({required this.groupId, required this.groupName, Key? key})
      : super(key: key);

  @override
  State<GroupInfo> createState() => _GroupInfoState();
}

class _GroupInfoState extends State<GroupInfo> {
  List membersList = [];
  bool isLoading = true;

  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    getGroupDetails();
  }

  Future getGroupDetails() async {
    try {
      DocumentSnapshot chatMap =
          await _firestore.collection('groups').doc(widget.groupId).get();
      membersList = chatMap['members'] ?? [];
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() {
        isLoading = false;
      });
    }
  }

  bool checkAdmin() {
    return membersList.firstWhere(
          (element) => element['uid'] == _auth.currentUser!.uid,
          orElse: () => null,
        )?['isAdmin'] ??
        false;
  }

  Future removeMembers(int index) async {
    String uid = membersList[index]['uid'] ?? '';

    setState(() {
      isLoading = true;
      membersList.removeAt(index);
    });

    await _firestore.collection('groups').doc(widget.groupId).update({
      "members": membersList,
    }).then((value) async {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('groups')
          .doc(widget.groupId)
          .delete();

      setState(() {
        isLoading = false;
      });
    });
  }

  void showDialogBox(int index) {
    if (checkAdmin()) {
      if (_auth.currentUser!.uid != membersList[index]['uid']) {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                backgroundColor: Color(0xFF0719B7),
                content: ListTile(
                  onTap: () => removeMembers(index),
                  title: Text(
                    "Remove This Member",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            });
      }
    }
  }

  Future onLeaveGroup() async {
    if (!checkAdmin()) {
      setState(() {
        isLoading = true;
      });

      membersList
          .removeWhere((member) => member['uid'] == _auth.currentUser!.uid);

      await _firestore.collection('groups').doc(widget.groupId).update({
        "members": membersList,
      });

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('groups')
          .doc(widget.groupId)
          .delete();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFF0719B7),
        appBar: AppBar(
          backgroundColor: Color(0xFF0719B7),
          title: Text("Group Info", style: TextStyle(color: Colors.white)),
          leading: BackButton(color: Colors.white),
        ),
        body: isLoading
            ? Container(
                height: size.height,
                width: size.width,
                alignment: Alignment.center,
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              )
            : Container(
                width: size.width,
                height: size.height,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: size.height / 8,
                        width: size.width / 1.1,
                        child: Row(
                          children: [
                            Container(
                              height: size.height / 11,
                              width: size.height / 11,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF0719B7),
                              ),
                              child: Icon(
                                Icons.group,
                                color: Colors.white,
                                size: size.width / 10,
                              ),
                            ),
                            SizedBox(
                              width: size.width / 20,
                            ),
                            Expanded(
                              child: Text(
                                widget.groupName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: size.width / 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF0719B7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: size.height / 20,
                      ),
                      Container(
                        width: size.width / 1.1,
                        child: Text(
                          "${membersList.length} Members",
                          style: TextStyle(
                            fontSize: size.width / 20,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0719B7),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: size.height / 20,
                      ),
                      checkAdmin()
                          ? ListTile(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AddMembersINGroup(
                                    groupChatId: widget.groupId,
                                    name: widget.groupName,
                                    membersList: membersList,
                                  ),
                                ),
                              ),
                              leading:
                                  Icon(Icons.add, color: Color(0xFF0719B7)),
                              title: Text(
                                "Add Members",
                                style: TextStyle(
                                  fontSize: size.width / 22,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF0719B7),
                                ),
                              ),
                            )
                          : SizedBox(),
                      Flexible(
                        child: ListView.builder(
                          itemCount: membersList.length,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            // Ambil nama dan buat inisial dari nama anggota
                            String name =
                                membersList[index]['name'] ?? 'No Name';
                            String initials = name.isNotEmpty
                                ? name
                                    .trim()
                                    .split(' ')
                                    .map((e) => e[0])
                                    .take(2)
                                    .join()
                                    .toUpperCase()
                                : 'NN'; // Inisial default jika tidak ada nama

                            return ListTile(
                              onTap: () => showDialogBox(index),
                              leading: CircleAvatar(
                                backgroundColor:
                                    Colors.blue, // Warna latar belakang avatar
                                child: Text(
                                  initials, // Tampilkan inisial nama
                                  style: TextStyle(
                                    color: Colors.white, // Warna teks (inisial)
                                    fontWeight:
                                        FontWeight.bold, // Tebal inisial
                                  ),
                                ),
                              ),
                              title: Text(
                                name,
                                style: TextStyle(
                                  fontSize: size.width / 22,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF0719B7),
                                ),
                              ),
                              subtitle: Text(
                                membersList[index]['email'] ?? 'No Email',
                                style: TextStyle(color: Colors.grey),
                              ),
                              trailing: Text(
                                (membersList[index]['isAdmin'] ?? false)
                                    ? "Admin"
                                    : "",
                                style: TextStyle(color: Colors.green),
                              ),
                            );
                          },
                        ),
                      ),
                      ListTile(
                        onTap: onLeaveGroup,
                        leading: Icon(
                          Icons.logout,
                          color: Colors.redAccent,
                        ),
                        title: Text(
                          "Leave Group",
                          style: TextStyle(
                            fontSize: size.width / 22,
                            fontWeight: FontWeight.w500,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
