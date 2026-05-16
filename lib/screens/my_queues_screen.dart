import 'dart:async';

import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'notification_screen.dart';

class MyQueuesScreen extends StatefulWidget {
  const MyQueuesScreen({super.key});

  @override
  State<MyQueuesScreen> createState() =>
      _MyQueuesScreenState();
}

class _MyQueuesScreenState
    extends State<MyQueuesScreen> {
  int currentIndex = 1;

  int queuePosition = 3;
  int waitingTime = 18;

  bool queueCancelled = false;

  Timer? timer;

  bool showAllHistory = false;

  final List<Map<String, String>> historyList = [
    {
      "title": "City Bank PLC",
      "email": "saraaaal212@gmail.com",
      "status": "Completed",
    },
    {
      "title": "United Hospital Limited",
      "email": "saraaaal212@gmail.com",
      "status": "Completed",
    },
    {
      "title": "UrbanBite Cafe",
      "email": "saraaaal212@gmail.com",
      "status": "Completed",
    },
    {
      "title": "BRAC Bank",
      "email": "saraaaal212@gmail.com",
      "status": "Completed",
    },
    {
      "title": "Square Hospital",
      "email": "saraaaal212@gmail.com",
      "status": "Completed",
    },
  ];

  @override
  void initState() {
    super.initState();

    startQueueTimer();
  }

  void startQueueTimer() {
    timer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) {
        if (waitingTime > 0 &&
            queuePosition > 0 &&
            !queueCancelled) {
          setState(() {
            waitingTime--;

            if (queuePosition > 1) {
              queuePosition--;
            }
          });
        } else {
          timer.cancel();
        }
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void cancelTicket() {
    setState(() {
      queueCancelled = true;
    });

    timer?.cancel();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Queue Ticket Cancelled",
        ),
      ),
    );
  }

  void viewStatus() {
    String message = "";

    if (queueCancelled) {
      message = "Your queue has been cancelled";
    } else if (queuePosition == 1) {
      message =
          "You are next in line. Please get ready.";
    } else {
      message =
          "Current Position: $queuePosition\nEstimated Wait: $waitingTime mins";
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
          ),
          title: const Text("Queue Status"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void joinNewQueue() {
    setState(() {
      queueCancelled = false;
      queuePosition = 5;
      waitingTime = 25;
    });

    timer?.cancel();

    startQueueTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Joined New Queue Successfully",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedHistory =
        showAllHistory
            ? historyList
            : historyList.take(3).toList();

    return Scaffold(
      backgroundColor: Colors.white,

      body: Column(
        children: [
          // ================= TOP SECTION =================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 65,
              bottom: 30,
              left: 20,
              right: 20,
            ),

            decoration: const BoxDecoration(
              color: Color(0xFFDCE4EC),

              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),
            ),

            child: Column(
              children: const [
                Text(
                  "Your Queues",
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  "We are there for you to find your serial",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
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
                  colors: [
                    Color(0xFF0047B3),
                    Color(0xFFB65AD8),
                  ],
                ),
              ),

              child: SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(),

                child: Padding(
                  padding: const EdgeInsets.all(18),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      // ================= ACTIVE QUEUE CARD =================

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),

                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF2EEF3,
                          ),

                          borderRadius:
                              BorderRadius.circular(
                            24,
                          ),

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: const Offset(
                                0,
                                4,
                              ),
                            ),
                          ],
                        ),

                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors
                                        .grey
                                        .shade400,
                                    thickness: 1.5,
                                  ),
                                ),

                                const Padding(
                                  padding:
                                      EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),

                                  child: Text(
                                    "Active Queue",
                                    style: TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                      color:
                                          Colors.black54,
                                    ),
                                  ),
                                ),

                                Expanded(
                                  child: Divider(
                                    color: Colors
                                        .grey
                                        .shade400,
                                    thickness: 1.5,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            const Text(
                              "City Bank PLC",
                              textAlign:
                                  TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 25),

                            infoRow(
                              "Ticket ID",
                              "qe1234",
                            ),

                            const SizedBox(height: 14),

                            infoRow(
                              "Position",
                              queueCancelled
                                  ? "-"
                                  : queuePosition
                                      .toString(),
                            ),

                            const SizedBox(height: 14),

                            infoRow(
                              "Status",
                              queueCancelled
                                  ? "Cancelled"
                                  : queuePosition == 1
                                      ? "Your Turn"
                                      : "Waiting",
                            ),

                            const SizedBox(height: 25),

                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 12,
                              ),

                              decoration:
                                  BoxDecoration(
                                color: Colors.white,

                                borderRadius:
                                    BorderRadius.circular(
                                  30,
                                ),
                              ),

                              child: Text(
                                queueCancelled
                                    ? "Queue Cancelled"
                                    : "Est. Wait Time : $waitingTime mins",

                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),

                            const SizedBox(height: 25),

                            Row(
                              children: [
                                Expanded(
                                  child: actionButton(
                                    text:
                                        "Cancel Ticket",

                                    color:
                                        Colors.red,

                                    onTap:
                                        cancelTicket,
                                  ),
                                ),

                                const SizedBox(
                                  width: 14,
                                ),

                                Expanded(
                                  child: actionButton(
                                    text:
                                        "View Status",

                                    color:
                                        const Color(
                                      0xFF109DFF,
                                    ),

                                    onTap:
                                        viewStatus,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 35),

                      // ================= HISTORY TITLE =================

                      const Text(
                        "History",
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight:
                              FontWeight.bold,
                          fontStyle:
                              FontStyle.italic,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ================= HISTORY LIST =================

                      ListView.builder(
                        shrinkWrap: true,

                        physics:
                            const NeverScrollableScrollPhysics(),

                        itemCount:
                            displayedHistory
                                .length,

                        itemBuilder:
                            (context, index) {
                          final item =
                              displayedHistory[
                                  index];

                          return Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom: 14,
                            ),

                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 14,
                              ),

                              decoration:
                                  BoxDecoration(
                                color: Colors.white,

                                borderRadius:
                                    BorderRadius.circular(
                                  20,
                                ),

                                boxShadow: [
                                  BoxShadow(
                                    color: Colors
                                        .black12,
                                    blurRadius: 5,
                                    offset:
                                        const Offset(
                                      0,
                                      3,
                                    ),
                                  ),
                                ],
                              ),

                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,

                                    decoration:
                                        const BoxDecoration(
                                      color: Color(
                                        0xFFECECEC,
                                      ),
                                      shape:
                                          BoxShape
                                              .circle,
                                    ),

                                    child: const Icon(
                                      Icons
                                          .location_on,
                                      color:
                                          Colors.red,
                                      size: 28,
                                    ),
                                  ),

                                  const SizedBox(
                                    width: 12,
                                  ),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,

                                      children: [
                                        Text(
                                          item["title"]!,
                                          style:
                                              const TextStyle(
                                            fontSize:
                                                19,
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),

                                        const SizedBox(
                                          height: 4,
                                        ),

                                        Text(
                                          item["email"]!,
                                          style:
                                              const TextStyle(
                                            fontSize:
                                                13,
                                            color: Colors
                                                .black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal:
                                          10,
                                      vertical: 5,
                                    ),

                                    decoration:
                                        BoxDecoration(
                                      color: Colors
                                          .green
                                          .shade100,

                                      borderRadius:
                                          BorderRadius.circular(
                                        20,
                                      ),
                                    ),

                                    child: Text(
                                      item["status"]!,
                                      style:
                                          const TextStyle(
                                        color: Colors
                                            .green,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // ================= SEE MORE =================

                      Align(
                        alignment:
                            Alignment.centerRight,

                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              showAllHistory =
                                  !showAllHistory;
                            });
                          },

                          child: Text(
                            showAllHistory
                                ? "Show Less"
                                : "See More >",

                            style:
                                const TextStyle(
                              color: Colors.black,
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // ================= JOIN BUTTON =================

                      SizedBox(
                        width: double.infinity,
                        height: 58,

                        child: ElevatedButton(
                          onPressed:
                              joinNewQueue,

                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.white,

                            elevation: 4,

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                35,
                              ),
                            ),
                          ),

                          child: const Text(
                            "Join New Queue",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 22,
                              fontWeight:
                                  FontWeight.bold,
                            ),
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

      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex: currentIndex,

        type: BottomNavigationBarType.fixed,

        selectedItemColor:
            const Color(0xFF0047B3),

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

          // NOTIFICATION
          if (index == 2) {
            Navigator.pushNamed(
              context,
              "/notifications",
            );
          }

          // PROFILE
          if (index == 3) {
            ScaffoldMessenger.of(context)
                .showSnackBar(
              const SnackBar(
                content: Text(
                  "Profile Screen Coming Soon",
                ),
              ),
            );
          }
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.sync),
            label: "Queue",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "Notification",
          ),

          BottomNavigationBarItem(
            icon:
                Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  // ================= INFO ROW =================

  Widget infoRow(
    String title,
    String value,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,

      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ================= ACTION BUTTON =================

  Widget actionButton({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        height: 45,

        decoration: BoxDecoration(
          color: color,

          borderRadius:
              BorderRadius.circular(25),
        ),

        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}