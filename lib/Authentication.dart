import 'package:chatify/HomeScreen.dart';
import 'package:chatify/SplashScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart'; // Tambahkan ini untuk inisialisasi Firebase
import 'package:flutter/material.dart';

class Authentication extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(), // Inisialisasi Firebase
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child:
                  CircularProgressIndicator(), // Loading saat menunggu Firebase
            ),
          );
        }

        if (_auth.currentUser != null) {
          return HomeScreen();
        } else {
          return SplashScreen();
        }
      },
    );
  }
}
