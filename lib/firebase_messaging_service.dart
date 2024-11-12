import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseCM {
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  final AndroidNotificationChannel channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    importance: Importance.max,
    playSound: true,
    showBadge: true,
  );

  final FlutterLocalNotificationsPlugin localNotification =
      FlutterLocalNotificationsPlugin();
  String? fcmToken; // Property untuk menyimpan token FCM

  Future<void> initNotification() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await localNotification.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          print('Notification payload: ${response.payload}');
          // Navigasi berdasarkan payload jika diperlukan
        }
      },
    );

    NotificationSettings settings = await firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('Permission denied');
    } else {
      print('Permission granted: ${settings.authorizationStatus}');
      if (FirebaseAuth.instance.currentUser != null) {
        fcmToken = await firebaseMessaging.getToken();
        print('FCM Token: $fcmToken');
        // Simpan token di database jika diperlukan
      }

      await localNotification
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    firebaseMessaging.onTokenRefresh.listen((newToken) {
      fcmToken = newToken;
      print('FCM Token refreshed: $newToken');
      // Update token di database jika diperlukan
    });
  }

  void listenToMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Message received in foreground: ${message.messageId}');
      showNotification(message);
    });
  }

  void showNotification(RemoteMessage message) {
    localNotification.show(
      0,
      message.notification?.title,
      message.notification?.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          importance: Importance.max,
          playSound: true,
        ),
      ),
    );
  }
}
