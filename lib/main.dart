import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'routes/app_routes.dart';
import 'utils/app_theme.dart';

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
      // Centralized in utils/app_theme.dart so colors are defined once.
      theme: AppTheme.themeData(),

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