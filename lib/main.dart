import 'package:chatify/SplashScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'HomeScreen.dart';
import 'LoginScreen.dart';
import 'push_notification_service.dart';

// Handler untuk pesan background
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  PushNotificationService pushNotificationService = PushNotificationService();
  await pushNotificationService.initialize();

  // Periksa apakah pengguna sudah login
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
      // Gunakan StreamBuilder untuk memantau status login pengguna
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Jika user login, arahkan ke HomeScreen
          if (snapshot.hasData) {
            return HomeScreen();
          }

          // Jika user belum login, arahkan ke LoginScreen
          return SplashScreen();
        },
      ),
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
