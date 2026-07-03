import 'package:flutter/material.dart';

import '../controllers/queue_controller.dart';
import '../models/queue_model.dart';
import 'dashboard_screen.dart';
import 'my_profile_screen.dart';
import 'notification_screen.dart';

class MyQueuesScreen extends StatefulWidget {
  const MyQueuesScreen({super.key});

  @override
  State<MyQueuesScreen> createState() => _MyQueuesScreenState();
}

class _MyQueuesScreenState extends State<MyQueuesScreen> {
  int currentIndex = 1;
  bool showAllHistory = false;
  bool isCancelling = false;

  // ================= CANCEL =================

  Future<void> cancelTicket(QueueToken token) async {
    if (isCancelling) return;
    setState(() => isCancelling = true);

    final error = await QueueController.cancelToken(token.id);

    if (!mounted) return;
    setState(() => isCancelling = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: error != null ? Colors.red.shade700 : Colors.black87,
      behavior: SnackBarBehavior.floating,
      content: Text(error ?? "Queue Ticket Cancelled"),
    ));
  }

  void viewStatus(QueueToken token, int position, bool isServing) {
    String message;
    if (isServing) {
      message = "It's your turn! Please proceed now.";
    } else if (position == 0) {
      message = "You are next in line. Please get ready.";
    } else {
      final wait = position * 5; // ~5 min per person ahead
      message = "People ahead of you: $position\nEstimated Wait: ~$wait mins";
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text("Queue Status"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void joinNewQueue() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  // ================= NAVIGATION =================

  void onNavbarTapped(int index) {
    if (index == currentIndex) return;
    setState(() => currentIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
        break;
      case 2:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
        break;
      case 3:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const MyProfileScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ================= TOP SECTION =================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 65, bottom: 30, left: 20, right: 20),
            decoration: const BoxDecoration(
              color: Color(0xFFDCE4EC),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),
            ),
            child: const Column(
              children: [
                Text(
                  "Your Queues",
                  style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                SizedBox(height: 8),
                Text(
                  "We are there for you to find your serial",
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),

          // ================= BODY =================
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF0047B3), Color(0xFFB65AD8)],
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ================= ACTIVE QUEUE CARD =================
                      StreamBuilder<QueueToken?>(
                        stream: QueueController.myActiveTokenStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(child: CircularProgressIndicator(color: Colors.white)),
                            );
                          }

                          final token = snapshot.data;
                          if (token == null) {
                            return _noActiveQueueCard();
                          }

                          return StreamBuilder<int>(
                            stream: QueueController.positionAheadStream(token),
                            builder: (context, posSnap) {
                              final position = posSnap.data ?? 0;
                              final isServing = token.isServing;
                              return _activeQueueCard(token, position, isServing);
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 35),

                      // ================= HISTORY TITLE =================
                      const Text(
                        "History",
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ================= HISTORY LIST =================
                      StreamBuilder<List<QueueToken>>(
                        stream: QueueController.myHistoryStream(),
                        builder: (context, snapshot) {
                          final history = snapshot.data ?? [];
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(child: CircularProgressIndicator(color: Colors.white)),
                            );
                          }
                          if (history.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Text(
                                  "No past queues yet",
                                  style: TextStyle(color: Colors.white70, fontSize: 15),
                                ),
                              ),
                            );
                          }

                          final displayedHistory =
                              showAllHistory ? history : history.take(3).toList();

                          return Column(
                            children: [
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: displayedHistory.length,
                                itemBuilder: (context, index) {
                                  final item = displayedHistory[index];
                                  return _historyTile(item);
                                },
                              ),
                              const SizedBox(height: 12),
                              if (history.length > 3)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () =>
                                        setState(() => showAllHistory = !showAllHistory),
                                    child: Text(
                                      showAllHistory ? "Show Less" : "See More >",
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 15),

                      // ================= JOIN BUTTON =================
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: joinNewQueue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
                          ),
                          child: const Text(
                            "Join New Queue",
                            style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // ================= NAVIGATION =================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0047B3),
        unselectedItemColor: Colors.black54,
        onTap: onNavbarTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.sync), label: "Queue"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Notification"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
    );
  }

  // ================= NO ACTIVE QUEUE =================

  Widget _noActiveQueueCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFF2EEF3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Icons.confirmation_number_outlined, size: 48, color: Colors.black38),
          const SizedBox(height: 14),
          const Text(
            "No active queue",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            "Book a service center from Home to get a ticket.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // ================= ACTIVE QUEUE CARD =================

  Widget _activeQueueCard(QueueToken token, int position, bool isServing) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF2EEF3),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade400, thickness: 1.5)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text("Active Queue",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
              ),
              Expanded(child: Divider(color: Colors.grey.shade400, thickness: 1.5)),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            token.serviceCenterName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 25),
          infoRow("Ticket No.", token.tokenNumber),
          const SizedBox(height: 14),
          infoRow("Position", isServing ? "-" : "${position + 1}"),
          const SizedBox(height: 14),
          infoRow("Status", isServing ? "Your Turn" : (position == 0 ? "Next" : "Waiting")),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
            child: Text(
              isServing ? "It's your turn now!" : "Est. Wait Time : ~${position * 5} mins",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: actionButton(
                  text: isCancelling ? "Cancelling..." : "Cancel Ticket",
                  color: Colors.red,
                  onTap: isCancelling ? null : () => cancelTicket(token),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: actionButton(
                  text: "View Status",
                  color: const Color(0xFF109DFF),
                  onTap: () => viewStatus(token, position, isServing),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= HISTORY TILE =================

  Widget _historyTile(QueueToken item) {
    final statusColor = item.status == 'Served'
        ? Colors.green
        : item.status == 'Cancelled'
            ? Colors.red
            : Colors.orange;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 25,
              backgroundColor: Color(0xFFECECEC),
              child: Icon(Icons.location_on, color: Colors.red, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.serviceCenterName,
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(item.tokenNumber,
                      style: const TextStyle(fontSize: 13, color: Colors.black54)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item.status,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= INFO ROW =================

  Widget infoRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ================= ACTION BUTTON =================

  Widget actionButton({required String text, required Color color, required VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: onTap == null ? Colors.grey : color,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Center(
          child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
