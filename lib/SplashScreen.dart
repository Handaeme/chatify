import 'package:chatify/WelcomeScreen.dart'; // Ganti dengan path ke WelcomeScreen Anda
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final String _text = 'Chatify';
  late List<Animation<double>> _letterAnimations;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Menginisialisasi animasi untuk keseluruhan teks
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    // Mengatur animasi untuk setiap huruf
    _letterAnimations = List.generate(_text.length, (index) {
      final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(index * 0.1, 1.0,
              curve: Curves.easeIn), // Delay per huruf
        ),
      );
      return animation;
    });

    // Navigasi ke WelcomeScreen setelah splash
    Future.delayed(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              WelcomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Color(0xFF0719B7), // Background color
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _text.split('').map((char) {
              int index = _text.indexOf(char); // Dapatkan indeks huruf
              return FadeTransition(
                opacity: _letterAnimations[index], // Animasi untuk huruf ini
                child: Text(
                  char,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Text color
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}