import 'package:chatify/ChatRoom.dart';
import 'package:chatify/group_chats/group_chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  String defaultProfilePic = 'https://example.com/default_profile_pic.png';

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    setStatus("Online");
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
      userMap = null;
    });

    try {
      var value = await _firestore
          .collection('users')
          .where("email", isEqualTo: _search.text.trim())
          .get();

      setState(() {
        isLoading = false;
      });

      if (value.docs.isNotEmpty) {
        var foundUser = value.docs[0].data();
        setState(() {
          userMap = foundUser;
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
      await _auth.signOut();
      // Pastikan pengguna kembali ke layar login setelah logout
      Navigator.of(context)
          .pushReplacementNamed('/login'); // Sesuaikan dengan rute login Anda
    } catch (e) {
      print("Error logging out: $e"); // Menampilkan error di log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Logout failed: ${e.toString()}. Please try again.")),
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
              backgroundImage: userMap!['profilePic'] != null
                  ? NetworkImage(userMap!['profilePic'])
                  : NetworkImage(defaultProfilePic),
              child: userMap!['profilePic'] == null
                  ? Text(
                      userMap!['name'][0].toUpperCase(),
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    )
                  : null,
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
          ),
        Padding(
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
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _auth.currentUser !=
                    null // Cek apakah pengguna sedang login
                ? _firestore
                    .collection('chatRooms')
                    .where('users', arrayContains: _auth.currentUser!.uid)
                    .orderBy('lastMessageTime', descending: true)
                    .snapshots()
                : null, // Jika pengguna tidak login, StreamBuilder tidak akan menunggu stream Firestore
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

                  // Mendapatkan daftar pengguna dan memastikan ada lebih dari satu pengguna
                  List users = chatRoomData['users'] ?? [];
                  if (users.length < 2) {
                    return SizedBox
                        .shrink(); // Mengabaikan tampilan chat room ini
                  }

                  // Menemukan ID pengguna lain
                  String? otherUserId = users.firstWhere(
                    (id) => id != _auth.currentUser!.uid,
                    orElse: () => null,
                  );

                  if (otherUserId == null) {
                    return SizedBox
                        .shrink(); // Mengabaikan tampilan chat room ini
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
                      String photoUrl =
                          userData['profilePic'] ?? defaultProfilePic;

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
                          backgroundImage: photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl.isEmpty
                              ? Text(name[0].toUpperCase())
                              : null,
                        ),
                        title: Text(
                          name,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          formatTimestamp(lastMessageTime),
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String formatTimestamp(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    var now = DateTime.now();

    if (now.difference(date).inDays == 0) {
      return DateFormat.Hm().format(date); // Waktu dalam HH:mm jika hari ini
    } else if (now.difference(date).inDays == 1) {
      return "Yesterday"; // Tampilkan 'Yesterday' jika kemarin
    } else {
      return DateFormat.yMMMd().format(date); // Tanggal singkat
    }
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
      body: Container(
        width: double.infinity,
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
}
