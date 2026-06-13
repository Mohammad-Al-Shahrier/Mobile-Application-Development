import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const QEasyApp());
}

class QEasyApp extends StatelessWidget {
  const QEasyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ================= APP SETTINGS =================

      debugShowCheckedModeBanner: false,
      title: 'QEasy',

      // ================= THEME =================

      theme: ThemeData(
        useMaterial3: true,

        primaryColor: const Color(0xFF0047B3),

        scaffoldBackgroundColor: Colors.white,

        fontFamily: 'Roboto',

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0047B3),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          centerTitle: true,
          elevation: 0,
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
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF0047B3),
          unselectedItemColor: Colors.black54,
          type: BottomNavigationBarType.fixed,
          elevation: 10,
        ),

        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        elevatedButtonTheme:
            ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                const Color(0xFF0047B3),
            foregroundColor: Colors.white,
            minimumSize:
                const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(12),
            ),
          ),
        ),
      ),

      // ================= ROUTES =================

      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,

      // ================= ERROR PAGE =================

      builder: (context, child) {
        ErrorWidget.builder =
            (FlutterErrorDetails details) {
          return Material(
            child: Container(
              color: Colors.white,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(20),
              child: const Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 70,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Something went wrong!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        };

        return child!;
      },
    );
  }
}