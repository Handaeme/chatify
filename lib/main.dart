import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'HomeScreen.dart'; // Import HomeScreen untuk daftar obrolan
import 'LoginScreen.dart'; // Import LoginScreen untuk halaman login
import 'push_notification_service.dart'; // Import PushNotificationService

// Handler untuk pesan background
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
  // Anda dapat menambahkan logika untuk menyimpan notifikasi ke local storage di sini jika diperlukan.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  PushNotificationService pushNotificationService = PushNotificationService();
  await pushNotificationService.initialize();

  User? currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser != null) {
    String userId = currentUser.uid;
    String? token = await pushNotificationService.getFcmToken();

    if (token != null) {
      await pushNotificationService.saveTokenToFirestore(userId);
      print("Token FCM diperbarui untuk userId: $userId");
    }

    pushNotificationService.listenToTokenRefresh(userId);
  } else {
    print("Pengguna belum login.");
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute:
          FirebaseAuth.instance.currentUser != null ? '/home' : '/login',
      routes: {
        '/home': (context) => HomeScreen(),
        '/login': (context) => LoginScreen(),
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
