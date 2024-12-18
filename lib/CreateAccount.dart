import 'package:chatify/HomeScreen.dart';
import 'package:chatify/Methods.dart';
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
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Color(0xFF0A1233),
      body: isLoading
          ? Center(
              child: Container(
                height: size.height / 20,
                width: size.height / 20,
                child: CircularProgressIndicator(),
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
                          color: Colors.white,
                          onPressed: () {
                            Navigator.pop(context);
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
                          fontFamily: 'JosefinSans',
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  Container(
                    width: size.width / 1.2,
                    child: Text(
                      "Started",
                      style: TextStyle(
                          fontFamily: 'JosefinSans',
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
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
                  customButton(size),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text(
                        "Login",
                        style: TextStyle(
                          fontFamily: 'JosefinSans',
                          color: Color(0xFF718096),
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
            isLoading = true; // Mengaktifkan loading saat proses dimulai
          });

          createAccount(_name.text, _email.text, _password.text).then((user) {
            if (user != null) {
              setState(() {
                isLoading = false; // Menonaktifkan loading jika berhasil
              });
              print("Account created successfully");

              saveFcmToken(user.uid);

              // Optimized navigation using pushReplacement
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => HomeScreen()),
              );
            } else {
              setState(() {
                isLoading = false; // Menonaktifkan loading jika gagal
              });
              print("Account creation failed");
            }
          }).catchError((error) {
            setState(() {
              isLoading = false; // Menonaktifkan loading jika terjadi error
            });
            print("Error during account creation: $error");
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
          borderRadius: BorderRadius.circular(25),
          color: Colors.red,
        ),
        child: isLoading
            ? CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              )
            : Text(
                "Create Account",
                style: TextStyle(
                  fontFamily: 'JosefinSans',
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
        style: TextStyle(color: Colors.white, fontFamily: 'JosefinSans'),
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: hintText,
          hintStyle: TextStyle(color: Color(0xFF718096)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: Color(0xFF718096)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: Color(0xFF0719B7)),
          ),
        ),
        cursorColor: Colors.red,
      ),
    );
  }

  Future<void> saveFcmToken(String userId) async {
    print("Saving FCM Token...");
    String? token = await PushNotificationService().getFcmToken();
    print("FCM Token: $token");

    if (token != null) {
      print("Saving FCM Token for user: $userId, token: $token");
      await PushNotificationService().saveTokenToFirestore(userId);
    } else {
      print("FCM Token not found after account creation.");
    }
  }
}
