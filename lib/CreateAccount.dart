import 'package:chatify/HomeScreen.dart';
import 'package:chatify/Methods.dart'; // Import PushNotificationService
import 'package:chatify/push_notification_service.dart';
import 'package:flutter/material.dart';

class CreateAccount extends StatefulWidget {
  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool isLoading = false; // Untuk menunjukkan status loading

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: isLoading
          ? Center(
              child: Container(
                height: size.height / 20,
                width: size.height / 20,
                child:
                    CircularProgressIndicator(), // Menampilkan loading saat pembuatan akun
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: size.height / 10,
                  ),
                  Container(
                    alignment: Alignment.centerLeft,
                    width: size.width / 1.0,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Padding(
                        padding: EdgeInsets.only(left: 15),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back_ios),
                          onPressed: () {
                            Navigator.pop(context); // Navigasi kembali
                          },
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: size.height / 50,
                  ),
                  Container(
                    width: size.width / 1.2,
                    child: Text(
                      "Let's Get",
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    width: size.width / 1.2,
                    child: Text(
                      "Started",
                      style: TextStyle(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: size.height / 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18.0),
                    child: Container(
                      width: size.width,
                      alignment: Alignment.center,
                      child: field(size, "Name", Icons.account_box, _name),
                    ),
                  ),
                  Container(
                    width: size.width,
                    alignment: Alignment.center,
                    child: field(size, "Email", Icons.account_box, _email),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18.0),
                    child: Container(
                      width: size.width,
                      alignment: Alignment.center,
                      child: field(size, "Password", Icons.lock, _password),
                    ),
                  ),
                  SizedBox(
                    height: size.height / 20,
                  ),
                  customButton(size), // Tombol untuk membuat akun
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.pop(context), // Navigasi ke halaman login
                      child: Text(
                        "Login",
                        style: TextStyle(
                          color: Color(0xFF0719B7),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget customButton(Size size) {
    return GestureDetector(
      onTap: () {
        if (_name.text.isNotEmpty &&
            _email.text.isNotEmpty &&
            _password.text.isNotEmpty) {
          setState(() {
            isLoading = true; // Tampilkan loading sebelum proses pembuatan akun
          });

          createAccount(_name.text, _email.text, _password.text).then((user) {
            if (user != null) {
              setState(() {
                isLoading =
                    false; // Sembunyikan loading setelah akun berhasil dibuat
              });
              print("Account created successfully");

              // Ambil dan simpan token FCM setelah akun berhasil dibuat
              saveFcmToken(user
                  .uid); // Pastikan createAccount() mengembalikan user dengan UID

              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        HomeScreen()), // Arahkan ke HomeScreen setelah sukses
              );
            } else {
              setState(() {
                isLoading =
                    false; // Sembunyikan loading jika pembuatan akun gagal
              });
              print("Account creation failed");
            }
          });
        } else {
          print("Please fill all fields");
        }
      },
      child: Container(
        height: size.height / 16,
        width: size.width / 1.2,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(25), // Sesuaikan dengan desain login
          color: Color(0xFF0719B7), // Sesuaikan dengan warna login
        ),
        child: Text(
          "Create Account",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget field(
      Size size, String hintText, IconData icon, TextEditingController cont) {
    return Container(
      height: size.height / 15,
      width: size.width / 1.2,
      child: TextField(
        controller: cont,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25), // Sesuaikan dengan desain
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: Color(0xFF0719B7)),
          ),
        ),
      ),
    );
  }

  // Fungsi untuk menyimpan FCM Token ke Firestore setelah akun dibuat
  Future<void> saveFcmToken(String userId) async {
    String? token = await PushNotificationService().getFcmToken();
    if (token != null) {
      print("Saving FCM Token for user: $userId, token: $token");
      await PushNotificationService().saveTokenToFirestore(userId);
    } else {
      print("FCM Token not found after account creation.");
    }
  }
}
