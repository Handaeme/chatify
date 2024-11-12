import 'package:chatify/HomeScreen.dart';
import 'package:chatify/SplashScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart'; // Inisialisasi Firebase
import 'package:flutter/material.dart';

class Authentication extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String accessToken; // Parameter accessToken
  final String? fcmToken; // Parameter fcmToken

  // Konstruktor untuk menerima accessToken dan fcmToken
  Authentication({required this.accessToken, this.fcmToken});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(), // Inisialisasi Firebase
      builder: (context, snapshot) {
        // Saat menunggu inisialisasi Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(), // Loading indicator
            ),
          );
        }

        // Jika ada error saat inisialisasi Firebase
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'), // Tampilkan pesan error
            ),
          );
        }

        // Jika inisialisasi berhasil
        if (snapshot.connectionState == ConnectionState.done) {
          // Menggunakan accessToken dan fcmToken jika diperlukan
          print("Access Token: $accessToken");
          print("FCM Token: $fcmToken");

          // Periksa apakah pengguna sudah login
          if (_auth.currentUser != null) {
            return HomeScreen(); // Jika sudah login, arahkan ke HomeScreen
          } else {
            return SplashScreen(); // Jika belum login, arahkan ke SplashScreen
          }
        }

        // Default, jika tidak ada kondisi terpenuhi
        return Scaffold(
          body: Center(
            child: Text("Something went wrong."), // Pesan error default
          ),
        );
      },
    );
  }
}
