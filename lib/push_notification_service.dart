import 'dart:convert';

import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

class PushNotificationService {
  // Fungsi untuk mendapatkan Access Token menggunakan akun layanan Firebase
  Future<String> getAccessToken() async {
    final serviceAccountJson = {"YOUR_SERVICE_ACCOUNT_JSON"};

    // Scope yang diperlukan untuk mengakses Firebase Messaging
    List<String> scopes = [
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging",
    ];

    // Membuat client dengan akun layanan
    final client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );

    // Mendapatkan token akses
    final credentials = await client.credentials;

    return credentials.accessToken.data;
  }

  // Fungsi untuk mengirim notifikasi push ke perangkat
  Future<void> sendNotification(
      String deviceToken, String title, String body) async {
    final serverAccessTokenKey = await getAccessToken();
    final endpoint =
        'https://fcm.googleapis.com/v1/projects/chatify-a9f62/messages:send';

    // Data pesan yang akan dikirimkan
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

    // Mengirimkan pesan ke FCM
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $serverAccessTokenKey',
      },
      body: jsonEncode(message),
    );

    // Mengecek respons
    if (response.statusCode == 200) {
      print("Notifikasi berhasil dikirim.");
    } else {
      print("Gagal mengirim notifikasi: ${response.statusCode}");
    }
  }
}
