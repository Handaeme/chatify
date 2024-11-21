import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

class PushNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotification =
      FlutterLocalNotificationsPlugin();
  String? _fcmToken;

  Future<void> initialize() async {
    try {
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print("Izin notifikasi diberikan.");
      } else {
        print("Izin notifikasi tidak diberikan.");
      }

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      final InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await _localNotification.initialize(initializationSettings);

      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      _fcmToken = await _firebaseMessaging.getToken();
      print("Token FCM berhasil diambil saat inisialisasi: $_fcmToken");
    } catch (e) {
      print("Error during FCM initialization: $e");
    }
  }

  Future<String?> getFcmToken() async {
    _fcmToken ??= await _firebaseMessaging.getToken();
    print("Token FCM yang diambil dari getFcmToken(): $_fcmToken");
    return _fcmToken;
  }

  Future<void> saveTokenToFirestore(String userId) async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print("Menyimpan token FCM untuk userId: $userId, token: $token");
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'fcmToken': token,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print("Token FCM berhasil disimpan.");
      } else {
        print("Error: Token FCM tidak ditemukan.");
      }
    } catch (e) {
      print("Error saat menyimpan token ke Firestore: $e");
    }
  }

  void listenToTokenRefresh(String userId) {
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      print("Token FCM diperbarui: $newToken");
      await saveTokenToFirestore(userId);
    });
  }

  Future<String> getAccessToken() async {
    try {
      // Baca file JSON dari aset
      final serviceAccountJson = jsonDecode(
          await rootBundle.loadString('assets/config/chatify_key.json'));

      List<String> scopes = [
        "https://www.googleapis.com/auth/firebase.messaging",
        "https://www.googleapis.com/auth/firebase.database"
      ];

      final client = await auth.clientViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
        scopes,
      );

      final credentials = await client.credentials;
      return credentials.accessToken.data;
    } catch (e) {
      print("Error mendapatkan access token: $e");
      rethrow;
    }
  }

  Future<void> sendNotification(
      String deviceToken, String title, String body) async {
    try {
      final serverAccessTokenKey = await getAccessToken();
      final endpoint =
          'https://fcm.googleapis.com/v1/projects/chatify-a9f62/messages:send';

      final message = {
        'message': {
          'token': deviceToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          }
        }
      };

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $serverAccessTokenKey',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        print("Notifikasi berhasil dikirim.");
      } else {
        print("Gagal mengirim notifikasi: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (e) {
      print("Error saat mengirim notifikasi: $e");
    }
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    print('Handling a background message: ${message.messageId}');
  }
}
