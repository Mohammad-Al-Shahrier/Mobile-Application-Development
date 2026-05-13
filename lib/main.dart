import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';

void main() {
  runApp(const QEasyApp());
}

class QEasyApp extends StatelessWidget {
  const QEasyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'QEasy',

      theme: ThemeData(
        primarySwatch: Colors.blue,

        scaffoldBackgroundColor: Colors.white,

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(
            color: Colors.black,
          ),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      home: const SplashScreen(),
    );
  }
}