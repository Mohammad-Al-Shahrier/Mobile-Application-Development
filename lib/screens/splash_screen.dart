import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        // Background Gradient
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF0047B3),
              Color(0xFFB65AD8),
            ],
          ),
        ),

        child: Column(
          children: [
            const Spacer(),

            // Logo
            Image.asset(
              "assets/images/logo.png",
              width: 220,
              height: 220,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 20),

            // Text
            const Text(
              "Simplify Your Queue Experience",
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            // Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildDot(),
                const SizedBox(width: 10),
                buildDot(),
                const SizedBox(width: 10),
                buildDot(),
              ],
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget buildDot() {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }
}