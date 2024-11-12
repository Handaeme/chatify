import 'dart:convert';

import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class PushNotificationService {
  // Fungsi untuk mendapatkan Access Token menggunakan akun layanan Firebase
  Future<String> getAccessToken() async {
    final serviceAccountJson = {
      "type": "service_account",
      "project_id": "chatify-a9f62",
      "private_key_id": "63127ef60f3c179ca6481d2729545a2c9cf7ab17",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDBszV5NSvihiE4\nl82xJ3u7DxOd4/92mxJ6QyO4ORrvnI9+KGEqqrbtV6JBYEzhUdf7bj6sGsVo+r8R\nJIJaPOsJeQd1ywqNerrKQn9lObM7Ybw7zD9mdUFRCeUVdKo2JMs3ABQF17H+d/ZK\nN51yZ46MmCvzDgQn+y+EBwjFO3v5ECwL1NNeCPrjBNppXKhxuL2XQsTorxjZpaFq\nDxp76tSPArPfRfvzqF+b/q/AmYIUgq6HwQEZ4UP+57eA+Ou0CNX/NQwwgvxggT6e\n1Bzd5WgU9UDfS8lKHC1cROqxIhYJpq6AX6KWGqRzZ8ndvvx29KtBwyAAlFWWUsRb\nTqrcWp+fAgMBAAECggEAEwwY04jvflB7PtHqp6N+zseuQaX0bojUOdKVVh3DcNF/\n6MN2vpfX8iHecjhShwuhxfcy0YC2bdrOZBSnftEjuaQ9oA8tw/jQGmiMl3sjjVDQ\njj7I8z3PhPUIomH9BOL8WrW2wlZSCfho7yZl5KSbR2cFV1rG/Nl99Cku6xos2DJb\nOIe03sLHjxJqtF7OjBwovjcl7ZNcLwl72OtG/odHZDYRRR7B4klbwGzzhcjwsmJS\nUr7J295ccO5AY4t8FJ6+LaUYm8Z0TSyDnjIBk3ZKMe3OaAGXhJbtOrNegr9Osnq7\nkmCoS0ha5byWmBye8hxuyBI6cT5TNr5vaTk17rpwiQKBgQD+4jbyQuwPhlNyqnt7\nXCcWoKc8OB1oeVcZqXsbFODC1veLFuPtZ5lPMRAvYKNjNlhE5thqokVP0PTU9HXp\nWCeEbNjoo85TVoLGE4Pa4f8sYnCfPk0OU2Yl8diVEf0ejYcESMO0ktmQSEXMJgKI\nLvUHLH23o7XipX2lnN6e2aiH2QKBgQDCjGSP1RLvnlFSgHkaYK2u5Kge5XhBZFoY\nMRxVSwXw7WTvkrH7HtQh4ogsznRiJaXdrdB4pfVHxEGGfz/AeQtf0TEq4j+XW1sO\nMf1X6avkfrLG793gtsceDZ/eILsLoh9OLD0ugbWAiAcGfR16MN1Dp0aKDLcvB7oz\neTG749rwNwKBgGu4y6Qj6IS/LrF9n+aJEfQcPdHTnYo0Dj3IRUEy17NBCyn7qKUD\nbeXsRHzhiOw7YZ7tOXYH0udi1rbSAqt2GG19W0cnQ+Iw4+A3CzkM3r2xdQu4VvTB\nBqDuz6xhB+tLwU5sOlos3kp+YRFg1x0bS2+WvCNKy2pYqvu9itD0CKgxAoGBAK3t\n0+3fIZnGIZAvuZVCf6SPWlqc7mEP9ZgRN/JtKzeVFRs2PBZ1HlPY8cOVI+mnHN3O\nCkYCoQHzTF2RIA7UaL3WCS38rbuEeih7urJA/2M9fllqkyPWZLfSmG1/N5oT7Ab4\neA4++mSZuCYt7w+R5g8Y2nCLI65RKz/fhv4inFcLAoGATB/uZavbc/femUaaGqtG\n3M6ZFlN0Cmr0K/6jSHQyQoWJbyNxeU9qcvrGylwl/2h7JRBpJIcnZS/SFAYhYcWI\nUkOlXEMnapsLz2oNTdUsL/4cim8iFjREoQ9pB2UpaS4iPbxhNm38Ywe/u75oSHrH\nbK/u5c7FDI/tNCSzIT5ifSA=\n-----END PRIVATE KEY-----\n",
      "client_email": "chatify-app@chatify-a9f62.iam.gserviceaccount.com",
      "client_id": "117790253326026094284",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/chatify-app%40chatify-a9f62.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    };

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
