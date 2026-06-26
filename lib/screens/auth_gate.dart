import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';

/// Auth gate — checks login state on every app start.
/// Splash → AuthGate → Dashboard / AdminDashboard / Login
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthController.authStateChanges,
      builder: (context, snapshot) {

        // Still loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF0047B3)),
            ),
          );
        }

        // Not logged in
        if (!snapshot.hasData || snapshot.data == null) {
          return const _Redirect(route: '/login');
        }

        // Logged in — check role
        final uid = snapshot.data!.uid;
        return FutureBuilder<String>(
          future: AuthController.getUserRole(uid),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF0047B3)),
                ),
              );
            }
            final role = roleSnap.data ?? 'customer';
            return _Redirect(
              route: role == 'admin' ? '/admin_dashboard' : '/dashboard',
            );
          },
        );
      },
    );
  }
}

class _Redirect extends StatefulWidget {
  final String route;
  const _Redirect({required this.route});

  @override
  State<_Redirect> createState() => _RedirectState();
}

class _RedirectState extends State<_Redirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pushReplacementNamed(context, widget.route);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF0047B3)),
      ),
    );
  }
}