import 'package:flutter/material.dart';

import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/registration_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/my_queues_screen.dart';
import '../screens/notification_screen.dart';
import '../screens/my_profile_screen.dart';

class AppRoutes {
  // ================= ROUTE NAMES =================

  static const String splash = "/";
  static const String login = "/login";
  static const String registration =
      "/registration";
  static const String dashboard =
      "/dashboard";
  static const String myQueues =
      "/my-queues";
  static const String notification =
      "/notification";
  static const String myProfile =
      "/my-profile";

  // ================= ROUTE GENERATOR =================

  static Route<dynamic> generateRoute(
    RouteSettings settings,
  ) {
    switch (settings.name) {
      // ================= SPLASH =================

      case splash:
        return MaterialPageRoute(
          builder: (context) =>
              const SplashScreen(),
        );

      // ================= LOGIN =================

      case login:
        return MaterialPageRoute(
          builder: (context) =>
              const LoginScreen(),
        );

      // ================= REGISTRATION =================

      case registration:
        return MaterialPageRoute(
          builder: (context) =>
              const RegistrationScreen(),
        );

      // ================= DASHBOARD =================

      case dashboard:
        return MaterialPageRoute(
          builder: (context) =>
              const DashboardScreen(),
        );

      // ================= MY QUEUES =================

      case myQueues:
        return MaterialPageRoute(
          builder: (context) =>
              const MyQueuesScreen(),
        );

      // ================= NOTIFICATION =================

      case notification:
        return MaterialPageRoute(
          builder: (context) =>
              const NotificationScreen(),
        );

      // ================= PROFILE =================

      case myProfile:
        return MaterialPageRoute(
          builder: (context) =>
              const MyProfileScreen(),
        );

      // ================= DEFAULT ERROR PAGE =================

      default:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor:
                Colors.white,

            appBar: AppBar(
              backgroundColor:
                  Colors.red,

              centerTitle: true,

              title: const Text(
                "Route Error",
              ),
            ),

            body: Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),

                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,

                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 90,
                      color: Colors.red,
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    const Text(
                      "Page Not Found",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      "No route defined for:\n${settings.name}",
                      textAlign:
                          TextAlign.center,

                      style:
                          const TextStyle(
                        fontSize: 16,
                        color:
                            Colors.black54,
                      ),
                    ),

                    const SizedBox(
                      height: 30,
                    ),

                    SizedBox(
                      width: 220,
                      height: 50,

                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            dashboard,
                            (route) => false,
                          );
                        },

                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.blue,

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),
                        ),

                        child: const Text(
                          "Go To Dashboard",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
    }
  }
}