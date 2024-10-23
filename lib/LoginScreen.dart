import 'package:chatify/CreateAccount.dart';
import 'package:chatify/HomeScreen.dart';
import 'package:chatify/Methods.dart';
import 'package:chatify/WelcomeScreen.dart';
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
      resizeToAvoidBottomInset:
          true, // Agar layar menyesuaikan saat keyboard muncul
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
                              transitionDuration: Duration(
                                  milliseconds:
                                      200), // Durasi transisi lebih cepat
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
                        transitionDuration: Duration(
                            milliseconds: 200), // Durasi transisi lebih cepat
                      ),
                    ),
                    child: Text(
                      "Create Account",
                      style: TextStyle(
                        color: Color(0xFF0719B7),
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
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          width: size.width / 1.2,
          child: Text(
            "Welcome",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          width: size.width / 1.2,
          child: Text(
            "Back",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
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
            isLoading = true;
          });

          loginAccount(_email.text, _password.text).then((user) {
            if (user != null) {
              print("Login Successful");
              setState(() {
                isLoading = false;
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
                  transitionDuration: Duration(
                      milliseconds: 200), // Durasi transisi lebih cepat
                ),
              );
            } else {
              print("Login Failed");
              setState(() {
                isLoading = false;
              });
            }
          });
        } else {
          print("Please fill form correctly");
        }
      },
      borderRadius: BorderRadius.circular(25), // Tambahkan radius border
      child: Container(
        height: size.height / 16,
        width: size.width / 1.2,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: Color(0xFF0719B7),
        ),
        child: Text(
          "Login",
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
        textCapitalization:
            TextCapitalization.none, // Agar tidak selalu huruf kapital
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(25), // Mengubah radius menjadi 25
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(25), // Untuk border saat tidak fokus
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25), // Untuk border saat fokus
            borderSide: BorderSide(color: Color(0xFF0719B7)),
          ),
        ),
      ),
    );
  }
}
