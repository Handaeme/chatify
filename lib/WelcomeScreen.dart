import 'package:chatify/CreateAccount.dart';
import 'package:chatify/LoginScreen.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255), // Background putih
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Menambahkan gambar di sini
                Image.asset(
                    'assets/images/logo_welcome2.png', // Ganti dengan path aset gambar Anda
                    height: 300, // Tinggi gambar
                    width: 300,
                    fit: BoxFit.cover // Menjaga proporsi gambar
                    ),
                const SizedBox(height: 20), // Spasi antara gambar dan teks
                const Text(
                  "Chatify",
                  style: TextStyle(
                    color: Color(0xFF0719B7), // Warna teks biru
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Lorem Ipsum is simply dummy text of the\nprinting and typesetting industry.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color.fromARGB(
                        255, 80, 80, 80), // Warna teks sedikit abu-abu
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: size.height / 10),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 35.0), // Padding kiri-kanan
            child: Container(
              height: 55,
              decoration: BoxDecoration(
                color: const Color.fromARGB(
                    255, 223, 223, 223), // Warna latar belakang abu-abu gelap
                borderRadius: BorderRadius.circular(30), // Membulatkan tombol
              ),
              child: Row(
                children: [
                  // Tombol Login (putih dengan teks hitam)
                  Expanded(
                    child: AnimatedButton(
                      text: "Login",
                      backgroundColor: Color(0xFF0719B7),
                      textColor: Color.fromARGB(255, 255, 255, 255),
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    LoginScreen(),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: AnimatedButton(
                      text: "Sign up",
                      backgroundColor: const Color.fromARGB(255, 223, 223, 223),
                      textColor: Color.fromARGB(255, 0, 0, 0),
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    CreateAccount(),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                        topLeft: Radius.zero, // Menghilangkan radius kiri
                        bottomLeft: Radius.zero, // Menghilangkan radius kiri
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: size.height / 20),
        ],
      ),
    );
  }
}

// Widget custom untuk tombol dengan animasi scale saat ditekan
class AnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color textColor;
  final BorderRadius? borderRadius; // Allowing custom border radius

  const AnimatedButton({
    Key? key,
    required this.text,
    required this.onTap,
    required this.backgroundColor,
    required this.textColor,
    this.borderRadius, // Optional border radius for custom shapes
  }) : super(key: key);

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose the controller to avoid memory leaks
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
    setState(() {
      _scale = 0.9; // Scale down effect when pressed
    });
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    setState(() {
      _scale = 1.0; // Scale back to normal
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: () {
        _controller.reverse();
        setState(() {
          _scale = 1.0;
        });
      },
      child: Transform.scale(
        scale: _scale,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: widget.borderRadius ??
                BorderRadius.circular(
                    50), // Membulatkan tombol atau custom radius
          ),
          child: Text(
            widget.text,
            style: TextStyle(
              color: widget.textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
