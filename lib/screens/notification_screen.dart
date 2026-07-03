import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../controllers/auth_controller.dart';
import '../models/notification_model.dart';
import 'dashboard_screen.dart';
import 'my_profile_screen.dart';
import 'my_queues_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int currentIndex = 2;
  final _db = FirebaseFirestore.instance;

  Stream<List<NotificationModel>> _notificationsStream() {
    final uid = AuthController.currentUid;
    if (uid == null) return Stream.value(const []);
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((s) {
      final list = s.docs.map((d) => NotificationModel.fromDoc(d)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> clearNotifications(List<NotificationModel> notifications) async {
    if (notifications.isEmpty) return;
    final batch = _db.batch();
    for (final n in notifications) {
      batch.delete(_db.collection('notifications').doc(n.id));
    }
    await batch.commit();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text("All notifications cleared"),
      ),
    );
  }

  void navigateBottomBar(int index) {
    if (currentIndex == index) return;
    setState(() => currentIndex = index);

    if (index == 0) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
    } else if (index == 1) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const MyQueuesScreen()));
    } else if (index == 3) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const MyProfileScreen()));
    }
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
          child: StreamBuilder<List<NotificationModel>>(
            stream: _notificationsStream(),
            builder: (context, snapshot) {
              final notifications = snapshot.data ?? [];
              final isLoading = snapshot.connectionState == ConnectionState.waiting;

              return Column(
                children: [
                  // ================= HEADER =================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 18, bottom: 24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const DashboardScreen()),
                                );
                              },
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration:
                                    BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                                child: const Icon(Icons.arrow_back, color: Colors.black),
                              ),
                            ),
                            const Expanded(
                              child: Center(
                                child: Text(
                                  "Notifications",
                                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: notifications.isEmpty
                                  ? null
                                  : () => clearNotifications(notifications),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: notifications.isEmpty ? Colors.grey : const Color(0xFF109DFF),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "Clear",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Stay updated with your running queues and bookings.",
                            style: TextStyle(color: Colors.black54, fontSize: 14, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ================= BODY =================
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : notifications.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                                      child: const Icon(Icons.notifications_off_rounded,
                                          color: Colors.white, size: 58),
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      "No Notifications",
                                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      "You are all caught up!",
                                      style: TextStyle(color: Colors.white70, fontSize: 15),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                itemCount: notifications.length,
                                itemBuilder: (context, index) {
                                  final item = notifications[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4)),
                                      ],
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                              color: item.color.withOpacity(0.12), shape: BoxShape.circle),
                                          child: Icon(item.icon, color: item.color, size: 30),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item.title,
                                                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(item.timeAgo,
                                                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                item.subtitle,
                                                style: const TextStyle(color: Colors.black54, fontSize: 14, height: 1.5),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              );
            },
          ),
        ),
      ),

      // ================= BOTTOM NAVBAR =================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 10,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black54,
        onTap: navigateBottomBar,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.sync), label: "Queue"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Notification"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }
}
