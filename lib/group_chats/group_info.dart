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
                backgroundColor: Color(0xFF0A1233),
                content: ListTile(
                  onTap: () => removeMembers(index),
                  title: Text(
                    "Remove This Member",
                    style: TextStyle(
                        fontFamily: 'JosefinSans', color: Colors.white),
                  ),
                ),
              );
            });
      }
    }
  }

  Future onLeaveGroup() async {
    setState(() {
      isLoading = true;
    });

    if (membersList.length == 1 &&
        membersList[0]['uid'] == _auth.currentUser!.uid) {
      try {
        await _firestore.collection('groups').doc(widget.groupId).delete();

        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('groups')
            .doc(widget.groupId)
            .delete();

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => HomeScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        print("Error saat menghapus grup: $e");
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      membersList
          .removeWhere((member) => member['uid'] == _auth.currentUser!.uid);

      if (checkAdmin() && membersList.isNotEmpty) {
        membersList[0]['isAdmin'] = true;
      }

      try {
        await _firestore.collection('groups').doc(widget.groupId).update({
          "members": membersList,
        });

        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('groups')
            .doc(widget.groupId)
            .delete();

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => HomeScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        print("Error saat meninggalkan grup: $e");
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Color(0xFF0A1233),
        appBar: AppBar(
          backgroundColor: Color(0xFF0A1233),
          title: Text("Group Info",
              style: TextStyle(color: Colors.white, fontFamily: 'JosefinSans')),
          leading: BackButton(color: Colors.white),
        ),
        body: isLoading
            ? Container(
                height: size.height,
                width: size.width,
                alignment: Alignment.center,
                child: CircularProgressIndicator(
                  color: Colors.red,
                ),
              )
            : SingleChildScrollView(
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
                              color: Colors.red,
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
                                fontFamily: 'JosefinSans',
                                fontSize: size.width / 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
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
                          fontFamily: 'JosefinSans',
                          fontSize: size.width / 20,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
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
                            leading: Icon(Icons.add, color: Colors.green),
                            title: Text(
                              "Add Members",
                              style: TextStyle(
                                fontFamily: 'JosefinSans',
                                fontSize: size.width / 22,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
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
                          String name = membersList[index]['name'] ?? 'No Name';
                          String initials = name.isNotEmpty
                              ? name
                                  .trim()
                                  .split(' ')
                                  .map((e) => e[0])
                                  .take(2)
                                  .join()
                                  .toUpperCase()
                              : 'NN';

                          return ListTile(
                            onTap: () => showDialogBox(index),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text(
                                initials,
                                style: TextStyle(
                                  fontFamily: 'JosefinSans',
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              name,
                              style: TextStyle(
                                fontFamily: 'JosefinSans',
                                fontSize: size.width / 22,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: Text(
                              membersList[index]['email'] ?? 'No Email',
                              style: TextStyle(
                                  fontFamily: 'JosefinSans-Regular',
                                  color: Color(0xFF718096)),
                            ),
                            trailing: Text(
                              (membersList[index]['isAdmin'] ?? false)
                                  ? "Admin"
                                  : "",
                              style: TextStyle(
                                  fontFamily: 'JosefinSans',
                                  color: Color(0xFF718096)),
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
                          fontFamily: 'JosefinSans',
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
    );
  }
}
