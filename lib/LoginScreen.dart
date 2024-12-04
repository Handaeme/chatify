import 'package:chatify/CreateAccount.dart';
import 'package:chatify/HomeScreen.dart';
import 'package:chatify/Methods.dart';
import 'package:chatify/WelcomeScreen.dart';
import 'package:chatify/push_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    return Scaffold(
      backgroundColor: Color(0xFF0A1233),
      resizeToAvoidBottomInset: true,
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  SizedBox(height: size.height / 10),
                  Container(
                    alignment: Alignment.centerLeft,
                    width: size.width / 1.0,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 15.0),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_ios),
                        color: Colors.white,
                        onPressed: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      WelcomeScreen(),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                var fadeAnimation =
                                    Tween<double>(begin: 0.0, end: 1.0)
                                        .animate(animation);
                                return FadeTransition(
                                  opacity: fadeAnimation,
                                  child: child,
                                );
                              },
                              transitionDuration: Duration(milliseconds: 200),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: size.height / 50),
                  buildWelcomeText(size),
                  SizedBox(height: size.height / 10),
                  field(size, "email", Icons.account_box, _email),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18.0),
                    child: field(size, "password", Icons.lock, _password),
                  ),
                  SizedBox(height: size.height / 10),
                  customButton(size),
                  SizedBox(height: size.height / 40),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            CreateAccount(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          var fadeAnimation =
                              Tween<double>(begin: 0.0, end: 1.0)
                                  .animate(animation);
                          return FadeTransition(
                            opacity: fadeAnimation,
                            child: child,
                          );
                        },
                        transitionDuration: Duration(milliseconds: 200),
                      ),
                    ),
                    child: Text(
                      "Create Account",
                      style: TextStyle(
                        fontFamily: 'JosefinSans',
                        color: Color(0xFF718096),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildWelcomeText(Size size) {
    return Column(
      children: [
        Container(
          width: size.width / 1.2,
          child: Text(
            "Hey,",
            style: TextStyle(
                fontFamily: 'JosefinSans',
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
        ),
        Container(
          width: size.width / 1.2,
          child: Text(
            "Welcome",
            style: TextStyle(
                fontFamily: 'JosefinSans',
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
        ),
        Container(
          width: size.width / 1.2,
          child: Text(
            "Back",
            style: TextStyle(
                fontFamily: 'JosefinSans',
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget customButton(Size size) {
    return InkWell(
      onTap: () {
        if (_email.text.isNotEmpty && _password.text.isNotEmpty) {
          setState(() {
            isLoading = true; // Menyalakan loading saat proses dimulai
          });

          handleLogin(
              _email.text, _password.text); // Panggil fungsi handleLogin()
        } else {
          print("Please fill form correctly");
        }
      },
      borderRadius: BorderRadius.circular(25),
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
                "Login",
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
        textCapitalization: TextCapitalization.none,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: Color(0xFF718096),
          ),
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

  // Fungsi untuk menangani login secara asynchronous
  Future<void> handleLogin(String email, String password) async {
    try {
      var user = await loginAccount(email, password);
      if (user != null) {
        print("Login Successful");

        // Menyimpan FCM token setelah login berhasil
        await saveFcmToken(user.uid);

        if (mounted) {
          setState(() {
            isLoading = false; // Mematikan loading setelah login berhasil
          });

          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  HomeScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                var fadeAnimation =
                    Tween<double>(begin: 0.0, end: 1.0).animate(animation);
                return FadeTransition(
                  opacity: fadeAnimation,
                  child: child,
                );
              },
              transitionDuration: Duration(milliseconds: 200),
            ),
          );
        }
      } else {
        print("Login Failed");

        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (error) {
      print("Error during login: $error");

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> saveFcmToken(String userId) async {
    String? token = await PushNotificationService().getFcmToken();
    if (token != null) {
      print("Saving FCM Token for user: $userId, token: $token");
      await PushNotificationService().saveTokenToFirestore(userId);
    } else {
      print("FCM Token not found after login.");
    }
  }
}
