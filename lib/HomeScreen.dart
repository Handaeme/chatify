import 'dart:convert';

import 'package:chatify/ChatRoom.dart';
import 'package:chatify/Methods.dart';
import 'package:chatify/group_chats/group_chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Map<String, dynamic>? userMap;
  bool isLoading = false;
  bool _isSearching = false;
  final TextEditingController _search = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Menyimpan riwayat pencarian
  List<Map<String, dynamic>> searchHistory = [];
  int _selectedIndex = 0; // Untuk kontrol bottom bar

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    setStatus("Online");
    _loadSearchHistory();
  }

  void setStatus(String status) async {
    await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
      "status": status,
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setStatus("Online");
    } else {
      setStatus("Offline");
    }
  }

  // Fungsi untuk mengatur room ID
  String chatRoomId(String user1, String user2) {
    return user1.compareTo(user2) > 0 ? "${user1}_$user2" : "${user2}_$user1";
  }

  void onSearch() async {
    setState(() {
      isLoading = true;
    });

    await _firestore
        .collection('users')
        .where("email", isEqualTo: _search.text.trim())
        .get()
        .then((value) {
      setState(() {
        isLoading = false;
      });

      if (value.docs.isNotEmpty) {
        setState(() {
          userMap = value.docs[0].data();
        });

        _addToSearchHistory(userMap!);
      } else {
        setState(() {
          userMap = null;
        });
      }
    });
  }

  // Tambahkan pencarian ke riwayat
  void _addToSearchHistory(Map<String, dynamic> user) {
    setState(() {
      searchHistory.removeWhere((item) => item['user']['uid'] == user['uid']);
      searchHistory.add({'user': user});
    });
    _saveSearchHistory();
  }

  // Simpan riwayat pencarian
  void _saveSearchHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> history =
        searchHistory.map((item) => jsonEncode(item['user'])).toList();
    await prefs.setStringList('searchHistory', history);
  }

  void _loadSearchHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? history = prefs.getStringList('searchHistory');

    if (history != null) {
      setState(() {
        searchHistory =
            history.map((item) => {'user': jsonDecode(item)}).toList();
      });
    }
  }

  // Menghapus chat dari riwayat pencarian
  void _removeFromSearchHistory(int index) {
    setState(() {
      searchHistory.removeAt(index);
    });
    _saveSearchHistory();
  }

  // Fungsi untuk merender halaman berdasarkan tab yang dipilih
  Widget _renderPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeScreenContent();
      case 1:
        return GroupChatHomeScreen();
      default:
        return _buildHomeScreenContent();
    }
  }

  // Fungsi untuk merender konten HomeScreen
  Widget _buildHomeScreenContent() {
    final size = MediaQuery.of(context).size;
    return Column(
      children: [
        SizedBox(height: size.height / 30),
        userMap != null
            ? ListTile(
                onTap: () {
                  String roomId = chatRoomId(
                    _auth.currentUser!.uid,
                    userMap!['uid'],
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatRoom(
                        chatRoomId: roomId,
                        userMap: userMap!,
                      ),
                    ),
                  );
                },
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(userMap!['profilePic'] ?? ""),
                ),
                title: Text(
                  userMap!['name'],
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(userMap!['email']),
              )
            : Container(),
        searchHistory.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Recent Chats",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                ),
              )
            : Container(),
        Expanded(
          child: ListView.builder(
            itemCount: searchHistory.length,
            itemBuilder: (context, index) {
              var historyItem = searchHistory[index];
              var user = historyItem['user'];

              return StreamBuilder<DocumentSnapshot>(
                stream: _firestore
                    .collection('chatRooms')
                    .doc(chatRoomId(_auth.currentUser!.uid, user['uid']))
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(
                      title: Text("Loading..."),
                    );
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return ListTile(
                      title: Text("No chat available"),
                    );
                  }

                  var chatRoomData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  var lastMessage = chatRoomData['lastMessage'] ?? "";
                  var lastMessageTime = chatRoomData['lastMessageTime'] != null
                      ? formatTimestamp(chatRoomData['lastMessageTime'])
                      : "";

                  return ListTile(
                    onTap: () {
                      String roomId = chatRoomId(
                        _auth.currentUser!.uid,
                        user['uid'],
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatRoom(
                            chatRoomId: roomId,
                            userMap: user,
                          ),
                        ),
                      );
                    },
                    onLongPress: () {
                      // Konfirmasi penghapusan
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Remove Chat'),
                            content: Text(
                                'Are you sure you want to remove this chat?'),
                            actions: <Widget>[
                              TextButton(
                                child: Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: Text('Remove'),
                                onPressed: () {
                                  _removeFromSearchHistory(index);
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    leading: CircleAvatar(
                      backgroundImage: user['profilePic'] != null
                          ? NetworkImage(user['profilePic'])
                          : null,
                      child: user['profilePic'] == null
                          ? Text(
                              user['name'][0].toUpperCase(),
                              style:
                                  TextStyle(color: Colors.white, fontSize: 20),
                            )
                          : null,
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            user['name'],
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(lastMessageTime,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              )),
                        ),
                      ],
                    ),
                    subtitle: Text("$lastMessage"),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0719B7),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_selectedIndex == 0 ? "Messages" : "Group Chats"),
        backgroundColor: Color(0xFF0719B7),
        foregroundColor: Colors.white,
        actions: [
          // Tampilkan kotak pencarian dan ikon hanya di tab Messages
          if (_isSearching && _selectedIndex == 0)
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      hintText: "Search by email",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    ),
                    style: TextStyle(color: Colors.black),
                    onSubmitted: (value) => onSearch(),
                  ),
                ),
              ),
            ),
          // Tampilkan ikon pencarian hanya di tab Messages
          if (_selectedIndex == 0)
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  // Nonaktifkan pencarian saat berpindah ke Group Chat
                  if (_selectedIndex == 1) {
                    _isSearching = false; // Menonaktifkan pencarian
                  }
                });
                if (!_isSearching) {
                  _search.clear();
                  setState(() {
                    userMap = null;
                  });
                }
              },
            ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => logOut(context),
          ),
        ],
      ),
      body: Container(
        width: 440,
        height: 845,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: _renderPage(), // Merender halaman sesuai tab yang dipilih
            ),
            BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index; // Ganti tab yang dipilih
                  // Nonaktifkan pencarian saat berpindah ke Group Chat
                  if (_selectedIndex == 1) {
                    _isSearching = false; // Menonaktifkan pencarian
                  }
                });
              },
              backgroundColor: Colors.white,
              selectedItemColor: Color(0xFF0719B7),
              unselectedItemColor: Colors.grey,
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.group),
                  label: 'Group Chat',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String formatTimestamp(Timestamp timestamp) {
    var date = timestamp.toDate();
    var now = DateTime.now();

    if (now.difference(date).inDays == 0) {
      return DateFormat.Hm().format(date);
    } else if (now.difference(date).inDays == 1) {
      return "Yesterday";
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }
}
