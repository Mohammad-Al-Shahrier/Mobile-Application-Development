import 'package:flutter/material.dart';

import 'routes/app_routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const QEasyApp());
}

class QEasyApp extends StatelessWidget {
  const QEasyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ================= APP INFO =================

      debugShowCheckedModeBanner: false,
      title: "QEasy",

      // ================= THEME =================

      theme: ThemeData(
        useMaterial3: true,

        primaryColor: const Color(
          0xFF0047B3,
        ),

        scaffoldBackgroundColor:
            Colors.white,

        fontFamily: "Roboto",

        colorScheme: ColorScheme.fromSeed(
          seedColor:
              const Color(0xFF0047B3),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,

          iconTheme: IconThemeData(
            color: Colors.black,
          ),

          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        bottomNavigationBarTheme:
            const BottomNavigationBarThemeData(
          selectedItemColor:
              Color(0xFF0047B3),

          unselectedItemColor:
              Colors.black54,

          backgroundColor: Colors.white,

          elevation: 8,

          type:
              BottomNavigationBarType.fixed,
        ),

        snackBarTheme: SnackBarThemeData(
          behavior:
              SnackBarBehavior.floating,

          backgroundColor:
              Colors.black87,

          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      ),

      // ================= ROUTES =================

      initialRoute: AppRoutes.splash,

      onGenerateRoute:
          AppRoutes.generateRoute,
    );
  }
}