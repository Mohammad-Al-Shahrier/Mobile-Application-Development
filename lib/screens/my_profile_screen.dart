import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'my_queues_screen.dart';
import 'notification_screen.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() =>
      _MyProfileScreenState();
}

class _MyProfileScreenState
    extends State<MyProfileScreen> {
  int currentIndex = 3;

  File? profileImage;

  final TextEditingController nameController =
      TextEditingController(
    text: "Sarah Johnson",
  );

  final TextEditingController emailController =
      TextEditingController(
    text: "saraaaal212@gmail.com",
  );

  Future<void> pickImage() async {
    final pickedImage = await ImagePicker()
        .pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        profileImage = File(pickedImage.path);
      });
    }
  }

  void editProfile() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Text("Edit Profile"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration:
                    const InputDecoration(
                  labelText: "Name",
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: emailController,
                decoration:
                    const InputDecoration(
                  labelText: "Email",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () {
                setState(() {});

                Navigator.pop(context);

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Profile Updated",
                    ),
                  ),
                );
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void logout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Text("Logout"),
          content: const Text(
            "Are you sure you want to logout?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const LoginScreen(),
                  ),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
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
            colors: [
              Color(0xFF0047B3),
              Color(0xFFB65AD8),
            ],
          ),
        ),

        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),

              child: Column(
                children: [
                  // PROFILE CARD
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 25,
                    ),

                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(
                        40,
                      ),

                      gradient:
                          const LinearGradient(
                        begin: Alignment.topLeft,
                        end:
                            Alignment.bottomRight,
                        colors: [
                          Color(0xFF6B4A92),
                          Color(0xFFC654A3),
                        ],
                      ),
                    ),

                    child: Column(
                      children: [
                        const Text(
                          "Profile",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 34,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 15),

                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 55,
                              backgroundColor:
                                  Colors.white,

                              backgroundImage:
                                  profileImage !=
                                          null
                                      ? FileImage(
                                          profileImage!,
                                        )
                                      : const AssetImage(
                                              "assets/images/profile.jpg",
                                            )
                                            as ImageProvider,
                            ),

                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: pickImage,

                                child: Container(
                                  width: 35,
                                  height: 35,

                                  decoration:
                                      const BoxDecoration(
                                    color:
                                        Colors.blue,
                                    shape:
                                        BoxShape
                                            .circle,
                                  ),

                                  child: const Icon(
                                    Icons.camera_alt,
                                    color:
                                        Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 15),

                        Text(
                          nameController.text,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          emailController.text,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 18),

                        ElevatedButton(
                          onPressed: editProfile,

                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.white,

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                20,
                              ),
                            ),
                          ),

                          child: const Text(
                            "Edit Profile",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // MENU ITEMS
                  profileTile(
                    "Account Details",
                    Icons.person_outline,
                    () {},
                  ),

                  profileTile(
                    "My Queue History",
                    Icons.history,
                    () {},
                  ),

                  profileTile(
                    "Payment Methods",
                    Icons.payment,
                    () {},
                  ),

                  profileTile(
                    "Notifications",
                    Icons.notifications_none,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const NotificationScreen(),
                        ),
                      );
                    },
                  ),

                  profileTile(
                    "Support",
                    Icons.support_agent,
                    () {},
                  ),

                  profileTile(
                    "Logout",
                    Icons.logout,
                    logout,
                  ),

                  const SizedBox(height: 20),

                  // INDICATOR
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,

                    children: [
                      indicator(
                        Colors.red,
                        30,
                      ),

                      const SizedBox(width: 6),

                      indicator(
                        Colors.white70,
                        10,
                      ),

                      const SizedBox(width: 6),

                      indicator(
                        Colors.white70,
                        10,
                      ),

                      const SizedBox(width: 6),

                      indicator(
                        Colors.white70,
                        10,
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // FOOTER
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 18,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,

                      borderRadius:
                          BorderRadius.circular(
                        25,
                      ),
                    ),

                    child: const Column(
                      children: [
                        Text(
                          "QEasy",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 3),

                        Text(
                          "Version 1.0.0",
                          style: TextStyle(
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // BOTTOM NAVBAR
      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex: currentIndex,

        type: BottomNavigationBarType.fixed,

        selectedItemColor: Colors.black,
        unselectedItemColor:
            Colors.black54,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });

          // HOME
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const DashboardScreen(),
              ),
            );
          }

          // QUEUE
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const MyQueuesScreen(),
              ),
            );
          }

          // NOTIFICATION
          if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const NotificationScreen(),
              ),
            );
          }
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.sync),
            label: "",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "",
          ),

          BottomNavigationBarItem(
            icon:
                Icon(Icons.person_outline),
            label: "",
          ),
        ],
      ),
    );
  }

  // PROFILE TILE
  Widget profileTile(
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 14,
      ),

      child: GestureDetector(
        onTap: onTap,

        child: Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(18),
          ),

          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.black54,
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.red,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // INDICATOR
  Widget indicator(
    Color color,
    double width,
  ) {
    return Container(
      width: width,
      height: 7,

      decoration: BoxDecoration(
        color: color,
        borderRadius:
            BorderRadius.circular(20),
      ),
    );
  }
}