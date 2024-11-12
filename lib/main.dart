import 'package:chatify/Authentication.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'HomeScreen.dart'; // Import HomeScreen untuk daftar obrolan
import 'LoginScreen.dart'; // Import LoginScreen untuk halaman login
import 'firebase_messaging_service.dart'; // Import FirebaseCM yang telah dibuat

// Handler untuk menangani pesan saat aplikasi berada di background
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}

Future<void> main() async {
  // Inisialisasi widget Flutter dan Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Inisialisasi Firebase Cloud Messaging Service
  FirebaseCM firebaseCM = FirebaseCM();
  await firebaseCM.initNotification(); // Inisialisasi notifikasi
  firebaseCM.listenToMessages(); // Mendengarkan pesan di foreground

  // Menangani pesan saat aplikasi di background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Mendapatkan token FCM perangkat
  String? fcmToken = await FirebaseMessaging.instance.getToken();
  print("FCM Token: $fcmToken");

  // Mendapatkan token autentikasi pengguna
  String? accessToken = await _getAccessToken();

  // Jalankan aplikasi
  runApp(MyApp(
    fcmToken: fcmToken,
    accessToken: accessToken,
  ));
}

// Fungsi untuk mendapatkan token autentikasi pengguna
Future<String?> _getAccessToken() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    return await user.getIdToken();
  }
  return null; // Kembalikan null jika pengguna belum login
}

class MyApp extends StatelessWidget {
  final String? fcmToken;
  final String? accessToken;

  MyApp({
    required this.fcmToken,
    required this.accessToken,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: FirebaseAuth.instance.currentUser != null
          ? '/home' // Jika pengguna sudah login, langsung ke home
          : '/login', // Jika belum login, ke halaman login
      routes: {
        '/auth': (context) => Authentication(
              fcmToken: fcmToken,
              accessToken: accessToken ?? "default_access_token",
            ),
        '/home': (context) => HomeScreen(), // Halaman utama
        '/login': (context) => LoginScreen(), // Halaman login
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            body: Center(child: Text('404: Page not found')),
          ),
        );
      },
    );
  }
}
