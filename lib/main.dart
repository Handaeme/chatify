import 'package:chatify/Authentication.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'firebase_messaging_service.dart'; // Import FirebaseCM yang telah dibuat

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handler untuk menangani pesan saat aplikasi berada di background
  print('Handling a background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Inisialisasi FirebaseCM
  FirebaseCM firebaseCM = FirebaseCM();
  await firebaseCM.initNotification(); // Menginisialisasi notifikasi
  firebaseCM
      .listenToMessages(); // Mendengarkan pesan saat aplikasi di foreground

  // Menangani notifikasi saat aplikasi di background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Mendapatkan token FCM perangkat
  String? token = await FirebaseMessaging.instance.getToken();
  print("FCM Token: $token");

  // Mendapatkan accessToken secara async
  User? user = FirebaseAuth.instance.currentUser;

  // Memastikan bahwa kita menggunakan await dan menangani kemungkinan nilai null
  String accessToken = user != null
      ? (await user.getIdToken()) ??
          "default_access_token" // Tangani kemungkinan null
      : "default_access_token"; // Gunakan nilai default jika user null

  // Jalankan aplikasi setelah semua async selesai
  runApp(MyApp(
    fcmToken: token,
    accessToken: accessToken,
  ));
}

class MyApp extends StatelessWidget {
  final String? fcmToken;
  final String accessToken; // Tambahkan accessToken

  MyApp({
    required this.fcmToken,
    required this.accessToken,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Authentication(
        fcmToken: fcmToken, // Pass FCM token to Authentication
        accessToken: accessToken, // Pass accessToken to Authentication
      ),
    );
  }
}
