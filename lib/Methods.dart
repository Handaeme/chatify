import 'package:chatify/WelcomeScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<User?> createAccount(String name, String email, String password) async {
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  try {
    // Membuat akun baru dengan email dan password
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);

    User? user = userCredential.user;

    if (user != null) {
      print("Account created successfully");

      // Memperbarui displayName dengan cara baru (updateDisplayName)
      await user.updateDisplayName(name);

      // Menambahkan data pengguna ke Firestore
      await _firestore.collection('users').doc(user.uid).set({
        "name": name,
        "email": email,
        "status": "Unavailable",
        "uid": user.uid,
      });

      return user;
    } else {
      print("Account creation failed");
      return null;
    }
  } on FirebaseAuthException catch (e) {
    // Penanganan spesifik untuk error FirebaseAuth
    if (e.code == 'email-already-in-use') {
      print('The account already exists for that email.');
    } else if (e.code == 'weak-password') {
      print('The password provided is too weak.');
    } else if (e.code == 'invalid-email') {
      print('The email address is badly formatted.');
    } else {
      print("Error: ${e.message}");
    }
    return null;
  } catch (e) {
    print("Error: $e");
    return null;
  }
}

Future<User?> loginAccount(String email, String password) async {
  FirebaseAuth _auth = FirebaseAuth.instance;

  try {
    // Melakukan sign in dengan email dan password
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email, password: password);

    User? user = userCredential.user;

    if (user != null) {
      print("Login successful");
      return user;
    } else {
      print("Login failed");
      return null;
    }
  } on FirebaseAuthException catch (e) {
    // Penanganan spesifik untuk error FirebaseAuth
    if (e.code == 'user-not-found') {
      print('No user found for that email.');
    } else if (e.code == 'wrong-password') {
      print('Wrong password provided for that user.');
    } else {
      print("Error: ${e.message}");
    }
    return null;
  } catch (e) {
    print("Error: $e");
    return null;
  }
}

Future<void> logOut(BuildContext context) async {
  FirebaseAuth _auth = FirebaseAuth.instance;

  try {
    await _auth.signOut();
    // Gunakan pushReplacement untuk menggantikan halaman login
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => WelcomeScreen()));
    print("Logout successful");
  } catch (e) {
    print("Error: $e");
  }
}
