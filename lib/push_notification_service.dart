import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
      // Masukkan JSON akun layanan langsung di dalam kode
      final serviceAccountJson = {
        "type": "service_account",
        "project_id": "chatify-a9f62",
        "private_key_id": "83a75c796557e64d2b9e17e40d1ae64d9bb9d25a",
        "private_key":
            "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCOvQBctBLIkMgz\nXfPx/WQSRLebDtAdljVNf1jUjD6ZotZQXy+y6GDtKvtUizLeoaU3vF9pGrZrIs8w\npe+4uC6HZyPT3rOq6rZBWCK6HOVAcYPuhyRGFHFJU00CaR1/qiNhogY3bMtgqHix\ndlytaeZRfiZnA3aFtZ3bdPSt2ez5NLfVWsb15WzM1CTh3crAHRoKc3dSgxS93i3o\nqKQc2KI30j+bgq7ejafpRxgkxfBHp7Bky1wQsld4LIosNCyAt+PsjqQYkml+yLmK\nSp93QfAL4XuXp5KZ0Uw4ThiAk3y9WvHIFdLDSE765TmXvWfKfivOH31WCg+VxwJJ\nBzMMAbjzAgMBAAECggEABQUuuxP2SSmWcQAP8WXpHB9gmcqGlVPQIh6lgCxCk2K/\nyOngIpm7tvu5BTs0GdJznic479hprBD4WoyrhsKrmEWPZAdEKHHC4T95UTRs97xG\nWKBWLUTQyzRr0/bge7n/LpLlRxPDf23NeOhh0BOWby1RqnPbuk4t9CcD6A1vIUCk\n9Z8NIoJlYgSlWyyfcvAg3wUhqUga9gSkVdM/F5T21fN6agfKWY7KtkFTzKS2ltqA\nGl1p5BUYKHJorACwaPS3/KYuPmocMJ5qY/VlsTYZ2pSjoWwzgzzxMjffBzj2+FCw\nqdthUXCNjAE9bf8P0Odh4r7pt8u0bjchoDRXXINk4QKBgQDGyD6Tv3yG57o4ETXa\nQEGrYxaWs5r0xVkkICzxxamZH1MruFbBab/bG8iW1YXH6aLMKBvEIHNRQxJ6STep\nIUxwJTFfw2+SrqUktPahuKXVyq1nmlnBv9Z43vWVjLb6g84Qtv94slu/cotadlQ/\n2LAwR/ItCnNtxEut+2PLF4WPcQKBgQC30wXnS1d5HkujwXFWnXJjTxFHa0nVUqLD\nihy/PjA1+XmYVDX990l+f4YNJBntG5fxlF5EXTNWAGUgnIhLqJiM1o+zjS79KOwM\nhH90oBcnLGFB2gEwifbHcoyvCL3x7EnMrnVm+CveNtrEcvzHi7c87QsqdIYPAIKQ\n6AT3r8OkowKBgQC1i4CLU6EZXF2Ygy9ZysGvE2o37ISi8/H7ql8h2FKShCdjkJG7\nRydvpypFh3ENKXYDWsYxEyn+l3EyudfZ4Y18BpvXSBiIMHSm15dAD/F1FgvUyQUc\njGYGMiq8kK00klgKr/cWdl6QtL5MujErtm0DS1IEjLzrDRHJLgTwIOVcIQKBgEie\nYrymtN2yLCt65e1Tsbatq6PNLJPLW2VoEEc0qBMKhRC6Y8H6iNwiQLC8TEmxFutm\ns37KWtdkvI6PiABrkChDMu25npCANBAV38wQ2lStYZaEKugj+It+IzmaeH8z20uy\nt8p/y8SzYuUsj9O8zByTgE+7TKJsjyfzoNLAaseFAoGADjNuH6bcxm4bvF7SRi5P\nA2MWTmU9rQyB2n2a1XHXdwwcjijL//1kSvlgE7TXxfKw6TnJ3zBDazU9Ac+ZroSw\ntSNPSUT2J+3d35YrSvryQR/4w/APA+fF3teaQ081qfNGXn+EL/AufbyaB8oOa0dd\nJzZvHV0FQcst24PmSppJX78=\n-----END PRIVATE KEY-----\n",
        "client_email": "chatify-a9f62@appspot.gserviceaccount.com",
        "client_id": "100245583829619521114",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url":
            "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url":
            "https://www.googleapis.com/robot/v1/metadata/x509/chatify-a9f62%40appspot.gserviceaccount.com",
        "universe_domain": "googleapis.com"
      };

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
