import 'package:chatify/ChatRoom.dart';
import 'package:chatify/group_chats/group_chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    setStatus("Online");

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (message.notification != null) {
        // Jika perlu pemrosesan berat, pastikan dilakukan secara async
        await Future.delayed(Duration(
            milliseconds:
                500)); // Simulasi penundaan ringan untuk menyeimbangkan

        // Proses notifikasi dalam dialog
        _showNotificationDialog(
            message.notification!.title, message.notification!.body);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void setStatus(String status) async {
    try {
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        "status": status,
      });
    } catch (e) {
      print("Error setting status: $e");
    }
  }

  void _showNotificationDialog(String? title, String? body) {
    // Pastikan widget masih terpasang (mounted)
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Color(0xFF0A1233),
          title: Text(
            title ?? 'Notification',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'JosefinSans',
            ),
          ),
          content: Text(
            body ?? 'No content',
            style: TextStyle(
              color: Color(0xFF718096),
              fontFamily: 'JosefinSans',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(
                  color: Colors.red,
                  fontFamily: 'JosefinSans',
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setStatus("Online");
    } else {
      setStatus("Offline");
    }
  }

  String chatRoomId(String user1, String user2) {
    return user1.compareTo(user2) > 0 ? "${user1}_$user2" : "${user2}_$user1";
  }

  void onSearch() async {
    setState(() {
      isLoading = true;
      userMap = null; // Mengosongkan hasil pencarian sebelumnya
    });

    // Pastikan ada input sebelum melakukan pencarian
    if (_search.text.trim().isEmpty) {
      setState(() {
        isLoading = false;
      });
      return; // Keluarkan fungsi jika tidak ada input
    }

    try {
      var value = await _firestore
          .collection('users')
          .where("email", isEqualTo: _search.text.trim())
          .get();

      setState(() {
        isLoading = false;
      });

      if (value.docs.isNotEmpty) {
        var foundUser = value.docs[0].data() as Map<String, dynamic>;
        setState(() {
          userMap = foundUser;
        });
      } else {
        setState(() {
          userMap = null; // Menangani ketika tidak ada hasil ditemukan
        });
      }
    } catch (e) {
      print("Error during search: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> logOut(BuildContext context) async {
    try {
      // Menambahkan penundaan ringan untuk mencegah UI freeze
      await Future.delayed(Duration(milliseconds: 100));
      await _auth.signOut();
      Navigator.of(context).pushReplacementNamed('/login');
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthError: ${e.message}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Logout failed: ${e.message ?? 'Unknown error'}")),
      );
    } catch (e) {
      print("Error logging out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout failed: ${e.toString()}")),
      );
    }
  }

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

  Widget _buildHomeScreenContent() {
    final size = MediaQuery.of(context).size;
    return Column(
      children: [
        SizedBox(height: size.height / 30),
        if (userMap != null)
          ListTile(
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
              backgroundImage: userMap!['profilePic'] != null &&
                      userMap!['profilePic'].isNotEmpty
                  ? NetworkImage(userMap!['profilePic'])
                  : null,
              child: userMap!['profilePic'] == null ||
                      userMap!['profilePic'].isEmpty
                  ? Text(
                      userMap!['name'][0].toUpperCase(),
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    )
                  : null,
            ),
            title: Text(
              userMap!['name'],
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'JosefinSans',
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              userMap!['email'],
              style: TextStyle(fontFamily: 'JosefinSans', color: Colors.white),
            ),
          ),
        // Padding(
        //   padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
        //   child: Align(
        //     alignment: Alignment.centerLeft,
        //     child: Text(
        //       "Recent Chats",
        //       style: TextStyle(
        //           fontSize: 18,
        //           fontWeight: FontWeight.bold,
        //           color: Colors.white),
        //     ),
        //   ),
        // ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _auth.currentUser != null
                ? _firestore
                    .collection('chatRooms')
                    .where('users', arrayContains: _auth.currentUser!.uid)
                    .orderBy('lastMessageTime', descending: true)
                    .snapshots()
                : null,
            builder: (context, snapshot) {
              if (_auth.currentUser == null) {
                return Center(child: Text("Please log in to view chats"));
              }

              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              var chatRooms = snapshot.data!.docs;

              if (chatRooms.isEmpty) {
                return Center(child: Text("No recent chats"));
              }

              return ListView.builder(
                itemCount: chatRooms.length,
                itemBuilder: (context, index) {
                  var chatRoomData =
                      chatRooms[index].data() as Map<String, dynamic>;
                  String lastMessage = chatRoomData['lastMessage'] ?? '';
                  Timestamp lastMessageTime =
                      chatRoomData['lastMessageTime'] ?? Timestamp.now();

                  List users = chatRoomData['users'] ?? [];
                  if (users.length < 2) {
                    return SizedBox.shrink();
                  }

                  String? otherUserId = users.firstWhere(
                    (id) => id != _auth.currentUser!.uid,
                    orElse: () => null,
                  );

                  if (otherUserId == null) {
                    return SizedBox.shrink();
                  }

                  return FutureBuilder<DocumentSnapshot>(
                    future:
                        _firestore.collection('users').doc(otherUserId).get(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) {
                        return ListTile(
                          title: Text("Loading..."),
                        );
                      }

                      var userData =
                          userSnapshot.data!.data() as Map<String, dynamic>;

                      String name = userData['name'] ?? 'Unknown User';
                      String? photoUrl = userData['profilePic'] ?? null;

                      return ListTile(
                        onTap: () {
                          String roomId = chatRoomId(
                            _auth.currentUser!.uid,
                            userData['uid'],
                          );
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatRoom(
                                chatRoomId: roomId,
                                userMap: userData,
                              ),
                            ),
                          );
                        },
                        leading: CircleAvatar(
                          backgroundImage:
                              photoUrl != null && photoUrl.isNotEmpty
                                  ? NetworkImage(photoUrl)
                                  : null,
                          backgroundColor: photoUrl == null || photoUrl.isEmpty
                              ? Colors.red
                              : null,
                          child: photoUrl == null || photoUrl.isEmpty
                              ? Text(
                                  name[0].toUpperCase(),
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 20),
                                )
                              : null,
                        ),
                        title: Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'JosefinSans',
                          ),
                        ),
                        subtitle: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'JosefinSans',
                            color: Colors.white,
                          ),
                        ),
                        trailing: Text(
                          formatTimestamp(lastMessageTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontFamily: 'JosefinSans',
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        )
      ],
    );
  }

  String formatTimestamp(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    var now = DateTime.now();

    if (now.difference(date).inDays == 0) {
      return DateFormat.Hm().format(date);
    } else if (now.difference(date).inDays == 1) {
      return "Yesterday";
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A1233),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          _selectedIndex == 0 ? "Messages" : "Group Chats",
          style: TextStyle(fontFamily: 'JosefinSans'),
        ),
        backgroundColor: Color(0xFF0A1233),
        foregroundColor: Colors.white,
        actions: [
          if (_isSearching && _selectedIndex == 0)
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Container(
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      hintText: "Search by email",
                      hintStyle: TextStyle(
                          color: Colors.grey[400], fontFamily: 'JosefinSans'),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search, color: Colors.white),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    ),
                    style: TextStyle(
                        color: Colors.white, fontFamily: 'JosefinSans'),
                    onSubmitted: (value) => onSearch(),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
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
      body: Column(
        children: [
          Expanded(
            child: _renderPage(),
          ),
          BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
                if (_selectedIndex == 1) {
                  _isSearching = false;
                }
              });
            },
            backgroundColor: Color(0xFF0A1233),
            selectedItemColor: Colors.red,
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: TextStyle(
              fontFamily: 'JosefinSans',
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: TextStyle(
              fontFamily: 'JosefinSans',
              fontWeight: FontWeight.normal,
            ),
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
    );
  }
}
