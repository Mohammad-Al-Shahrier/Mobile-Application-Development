import 'dart:async';

import 'package:flutter/material.dart';

import '../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen> {
  int currentDot = 0;

  Timer? dotTimer;
  Timer? navigationTimer;

  @override
  void initState() {
    super.initState();

    startAnimation();
    navigateToLogin();
  }

  // ================= DOT ANIMATION =================

  void startAnimation() {
    dotTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (!mounted) return;

        setState(() {
          currentDot = (currentDot + 1) % 3;
        });
      },
    );
  }

  // ================= AUTO NAVIGATION =================

  void navigateToLogin() {
    navigationTimer = Timer(
      const Duration(seconds: 3),
      () {
        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          AppRoutes.login,
        );
      },
    );
  }

  @override
  void dispose() {
    dotTimer?.cancel();
    navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0047B3),
              Color(0xFFB65AD8),
            ],
          ),
        ),

        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),

              // ================= LOGO =================

              Hero(
                tag: "app_logo",

                child: Image.asset(
                  "assets/images/logo.png",

                  width: 200,
                  height: 200,

                  fit: BoxFit.contain,

                  errorBuilder:
                      (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return const Icon(
                          Icons.queue,
                          size: 140,
                          color: Colors.white,
                        );
                      },
                ),
              ),

              const SizedBox(height: 25),

              // ================= APP NAME =================

              const Text(
                "QEasy",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 12),

              // ================= TAGLINE =================

              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 30,
                ),

                child: Text(
                  "Simplify Your Queue Experience",
                  textAlign: TextAlign.center,

                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ================= DOTS =================

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: List.generate(
                  3,
                  (index) =>
                      buildDot(index),
                ),
              ),

              const Spacer(),

              // ================= FOOTER =================

              const Padding(
                padding: EdgeInsets.only(
                  bottom: 20,
                ),

                child: Text(
                  "Powered by QEasy",

                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= DOT =================

  Widget buildDot(int index) {
    final bool isActive =
        currentDot == index;

    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 300,
      ),

      margin:
          const EdgeInsets.symmetric(
        horizontal: 5,
      ),

      width: isActive ? 28 : 12,
      height: 12,

      decoration: BoxDecoration(
        color: isActive
            ? Colors.white
            : Colors.white38,

        borderRadius:
            BorderRadius.circular(20),
      ),
    );
  }
}