import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/dashboard_screen.dart';

/*import 'screens/my_queues_screen.dart';
import 'screens/my_profile_screen.dart';*/

class AppRoutes {
  // Route Names
  static const String splash = "/";
  static const String login = "/login";
  static const String registration = "/registration";
  static const String dashboard = "/dashboard";

  /*static const String myQueues = "/my-queues";
  static const String myProfile = "/my-profile";*/

  // Route Generator
  static Route<dynamic> generateRoute(
    RouteSettings settings,
  ) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );

      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );

      case registration:
        return MaterialPageRoute(
          builder: (_) => const RegistrationScreen(),
        );

      case dashboard:
        return MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        );

      /*case myQueues:
        return MaterialPageRoute(
          builder: (_) => const MyQueuesScreen(),
        );

      case myProfile:
        return MaterialPageRoute(
          builder: (_) => const MyProfileScreen(),
        );*/

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: const Text("Error"),
            ),

            body: const Center(
              child: Text(
                "Page Not Found",
              ),
            ),
          ),
        );
    }
  }
}