import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class JsonLoader {
  /// Fungsi untuk membaca file JSON dari path tertentu
  static Future<Map<String, dynamic>> loadJson(String path) async {
    try {
      String jsonString = await rootBundle.loadString(path);
      return jsonDecode(jsonString);
    } catch (e) {
      print("Gagal memuat file JSON: $e");
      rethrow;
    }
  }
}
