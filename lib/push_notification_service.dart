import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

class PushNotificationService {
  // Fungsi untuk mendapatkan Access Token menggunakan akun layanan Firebase
  Future<String> getAccessToken() async {
    await dotenv.load(); // Memuat file .env

    final serviceAccountJson = {
      "type": "service_account",
      "project_id": dotenv.env['GOOGLE_CLOUD_PROJECT_ID'],
      "private_key_id": dotenv.env['GOOGLE_CLOUD_PRIVATE_KEY_ID'],
      "private_key": dotenv.env['GOOGLE_CLOUD_PRIVATE_KEY'],
      "client_email": dotenv.env['GOOGLE_CLOUD_CLIENT_EMAIL'],
      "client_id": dotenv.env['GOOGLE_CLOUD_CLIENT_ID'],
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/chatify-app%40chatify-a9f62.iam.gserviceaccount.com",
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
  }

  // Fungsi untuk mengirim notifikasi push
  Future<void> sendNotification(
      String deviceToken, String title, String body) async {
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
    }
  }
}
