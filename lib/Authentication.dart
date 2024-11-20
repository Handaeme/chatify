import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Authentication {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fungsi untuk registrasi pengguna baru
  Future<void> registerUser(String name, String email, String password) async {
    try {
      // Mendaftar pengguna baru dengan email dan password
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String? userId = userCredential.user?.uid;
      if (userId != null) {
        print("User ID berhasil dibuat: $userId");

        // Simpan data pengguna ke Firestore
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'uid': userId,
          'name': name,
          'email': email,
          'status': 'Online',
        }, SetOptions(merge: true));
        print("Data pengguna berhasil disimpan di Firestore.");
      } else {
        print("Error: User ID kosong setelah registrasi.");
      }
    } catch (e) {
      print("Error saat registrasi: $e");
    }
  }

  // Fungsi untuk login pengguna
  Future<void> loginUser(String email, String password) async {
    try {
      // Login pengguna dengan email dan password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String? userId = userCredential.user?.uid;
      if (userId != null) {
        print("User ID login: $userId");

        // Perbarui status pengguna menjadi Online
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'status': 'Online',
        });
        print("Status pengguna berhasil diperbarui di Firestore.");
      } else {
        print("Error: User ID kosong saat login.");
      }
    } catch (e) {
      print("Error saat login: $e");
    }
  }

  // Fungsi untuk logout pengguna
  Future<void> logoutUser() async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        print("User ID logout: $userId");

        // Perbarui status pengguna menjadi Offline
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'status': 'Offline'});
        print("Status diperbarui menjadi Offline.");
      } else {
        print("Error: User ID tidak ditemukan saat logout.");
      }

      await _auth.signOut();
      print("User berhasil logout.");
    } catch (e) {
      print("Error saat logout: $e");
    }
  }

  // Fungsi opsional untuk mendapatkan token autentikasi pengguna
  Future<String?> getAuthToken() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        String? token = await user.getIdToken();
        print("Token autentikasi pengguna: $token");
        return token;
      } else {
        print("Error: Tidak ada pengguna yang sedang login.");
      }
    } catch (e) {
      print("Error saat mendapatkan token autentikasi: $e");
    }
    return null;
  }
}
