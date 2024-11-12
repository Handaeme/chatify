import 'package:googleapis_auth/auth_io.dart';

class AccessFirebaseToken {
  // Define the Firebase Messaging Scope URL
  static String firebaseMessagingScope =
      "https://www.googleapis.com/auth/firebase.messaging";

  // Function to get access token
  Future<String> getAccessToken() async {
    // Initialize client using service account credentials
    final client = await clientViaServiceAccount(
      ServiceAccountCredentials.fromJson({
        "type": "service_account",
        "project_id": "chatify-a9f62",
        "private_key_id": "f4b13fcd95752dd3d0a5100b7e482fa9d82e386e",
        "private_key":
            "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCqe0ygVXoG+lLr\nXtzLTybRTW22jqfclK28TzDawdwVylhEdWTsk3MxiVfr/1fMcXk3aha6Q0ICYwOx\nY4LvmPj42X1JR2M4f3rmlf6id5k1vR+8+DR2MsaIt+MpJ6UGgbB6Ey96XVS0JSvW\nUKSENlEWm2Akz3UdabOPvrWh34Ko1kYgT6or5dgrgimw4qauwGQF78+IQs+gLc+m\na9T0NNaOmhLUBjQ2yXrZ+ZS+/eRRhWBRgxHaxYT2fIGR5WVoENA5hYY8OC7e1wqk\nyYJ7aL6lbdutzWer6mdOs7qSq9LtR3oMCltyuuPDRcNOmIVVN8DiFBYQxjDy1QOB\nW7HYIywpAgMBAAECggEAAOiTzbXu5sseNoFkqVO0aACi4Ups1BTZwStl3gCS+O3B\nXyoF/enCPyUVeh07/UusgvJWiSsTFrqq2h7m43p79y2HiKSv/2zUfZaWiwyanSnz\nGZl0BB48px1dwUokC78Uru3bvqnxKd2Z2HRJEChO8dElp8SQQfYefhlc0+5CPr6V\nWjvkbMR3GdzRaVF4PZ38inbbScVLYkqIKjHr9KxVTtp3wELnRYldRYmxzxGVP8ur\nPozPEIx3kT2oKVqWiwwts+aHAejrO+xRPvpEgOK0NbR6lTbKw8a/kNHHPgKu7ZBU\n2YyTNc1udbIAiJsDvX4HnODLz02LBgeaxV/+5sRf5QKBgQDYPixX+7MgCWvlm9lV\nc247cq1M8u35pCuvuPqcy6wvWcgnaA/JfSBPKaGLmGOxnkLIOimWy+Dt7TpnhdJy\nI8IMTPyu1FMHTfenTc8idR+vuy7+ZdwQZaaMNAI2fNVxgIDKhgqINrnnu/3FoWKB\njmhGCSMlpfvr4xtqdkY6kxgYxQKBgQDJ00xvkwziClLncO6FBxyIolyHnvupwim9\nLDvIfVmSXL/idTHy7IEt9aMY5otOF+ye5Oq2uAJf6KicJYvJkdfWAf1FxKxsxFP+\nhPa5VpR8v5flYsn1L4hS5mX4yXoRWMuDcqFC7F6dvr4E7X8PrspFltrPueDvzAML\nORE7Vm7UFQKBgDPwMvxq8yoluSmsFjZlBDv5HlDWJHyKhwes2Vzhupig6uc0Il6V\n1DXPXQLHdmKKDaZD+gtDKuJa0WVeCh7qIciMkUB4tPyTKIGhubegBB1US0RFOOcj\nUy5nq4Rk1WtunwCF02/GHT7gs2JNkfhmOPthZHS9elW89a/LerDE9cu1AoGAJguA\nwx+TNCECE8LEE6uNg2wnySD9C7kgKRrnghmvAtodCdFRwxs2FrXRMuZyqBv2bNV2\nMU9qky3Gavjg6vRlHWBun/I9FpvDwZzK7ZEWmJV9Sq5ep6t4JThtTIKeUhrM8lBv\nebAY/d9w7njelNQ8KPYQ9UtyzYFFqZ3uU6MtbSkCgYBkpk4MZMLbTkAjSg9dh/2r\nGEYd+5jDElcaNp0Dcl1sUpxc5k72hVvLhTkXKXgOsS6U8t/ykiFd7PpEj8v7FAq/\n5nhsrZKw4RYb/M26t7i8lmoc2jZeDIaxo8aJtSqIpkaQvf9CkkULGSXfKzgK1Hmh\n67oSdDncBqpv+n16Z+KflQ==\n-----END PRIVATE KEY-----\n",
        "client_email":
            "firebase-adminsdk-cmqez@chatify-a9f62.iam.gserviceaccount.com",
        "client_id": "112501382120361394873",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url":
            "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url":
            "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-cmqez@chatify-a9f62.iam.gserviceaccount.com",
        "universe_domain": "googleapis.com"
      }),
      [firebaseMessagingScope],
    );

    // Return the access token
    return client.credentials.accessToken.data;
  }
}
