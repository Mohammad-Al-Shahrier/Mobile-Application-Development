import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../models/user_model.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';
import 'my_queues_screen.dart';
import 'notification_screen.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  int currentIndex = 3;

  void editProfile(UserModel user) {
    final nameController = TextEditingController(text: user.fullName);
    final phoneController = TextEditingController(text: user.phone);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Edit Profile"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: "Phone"),
                ),
                const SizedBox(height: 8),
                Text(user.email, style: const TextStyle(color: Colors.black45, fontSize: 12)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        setDialogState(() => isSaving = true);
                        final error = await ProfileController.updateProfile(
                          fullName: nameController.text,
                          phone: phoneController.text,
                        );
                        if (!mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          backgroundColor: error != null ? Colors.red.shade700 : Colors.green,
                          behavior: SnackBarBehavior.floating,
                          content: Text(error ?? "Profile Updated"),
                        ));
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Save"),
              ),
            ],
          );
        });
      },
    );
  }

  void logout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // close dialog first
                await AuthController.logout();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0047B3), Color(0xFFB65AD8)],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<UserModel?>(
            stream: ProfileController.currentUserStream(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              final isLoading = snapshot.connectionState == ConnectionState.waiting;

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    children: [
                      // PROFILE CARD
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 25),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF6B4A92), Color(0xFFC654A3)],
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Profile",
                              style: TextStyle(color: Colors.black, fontSize: 34, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 15),
                            CircleAvatar(
                              radius: 55,
                              backgroundColor: Colors.white,
                              child: Text(
                                user?.initials ?? '?',
                                style: const TextStyle(
                                    fontSize: 34, fontWeight: FontWeight.bold, color: Color(0xFF0047B3)),
                              ),
                            ),
                            const SizedBox(height: 15),
                            if (isLoading)
                              const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            else ...[
                              Text(
                                user?.fullName ?? 'Guest',
                                style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? '',
                                style: const TextStyle(color: Colors.black87, fontSize: 14),
                              ),
                            ],
                            const SizedBox(height: 18),
                            ElevatedButton(
                              onPressed: user == null ? null : () => editProfile(user),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: const Text(
                                "Edit Profile",
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // MENU ITEMS
                      profileTile("Account Details", Icons.person_outline, () {
                        if (user != null) editProfile(user);
                      }),
                      profileTile("My Queue History", Icons.history, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MyQueuesScreen()),
                        );
                      }),
                      profileTile("Notifications", Icons.notifications_none, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationScreen()),
                        );
                      }),
                      profileTile("Support", Icons.support_agent, () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text("Contact us at support@qeasy.app"),
                        ));
                      }),
                      profileTile("Logout", Icons.logout, logout),

                      const SizedBox(height: 20),

                      // FOOTER
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Column(
                          children: [
                            Text("QEasy", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                            SizedBox(height: 3),
                            Text("Version 1.0.0", style: TextStyle(color: Colors.black54)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),

      // BOTTOM NAVBAR
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        onTap: (index) {
          if (index == currentIndex) return;
          setState(() => currentIndex = index);

          if (index == 0) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
          }
          if (index == 1) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => const MyQueuesScreen()));
          }
          if (index == 2) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.sync), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: ""),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ""),
        ],
      ),
    );
  }

  // PROFILE TILE
  Widget profileTile(String title, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
          child: Row(
            children: [
              Icon(icon, color: Colors.black54),
              const SizedBox(width: 15),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.red, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
