import 'package:flutter/material.dart';

import 'my_queues_screen.dart';
import 'notification_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen> {
  int currentIndex = 0;

  final TextEditingController searchController =
      TextEditingController();

  bool showAllCenters = false;

  final List<Map<String, String>> centers = [
    {
      "image": "assets/images/hospital.jpg",
      "title": "United Hospital Limited",
      "address": "Uttara, Dhaka",
      "rating": "4.8",
      "details":
          "Modern hospital with emergency support.",
    },
    {
      "image": "assets/images/bank.jpg",
      "title": "City Bank PLC",
      "address": "Mirpur, Dhaka",
      "rating": "4.9",
      "details":
          "Fast banking service with queue system.",
    },
    {
      "image": "assets/images/cafe.jpg",
      "title": "UrbanBite Cafe",
      "address": "Banani, Dhaka",
      "rating": "4.7",
      "details":
          "Popular cafe with online booking.",
    },
    {
      "image": "assets/images/hospital.jpg",
      "title": "Square Hospital",
      "address": "Panthapath, Dhaka",
      "rating": "4.9",
      "details":
          "Premium healthcare and appointment system.",
    },
    {
      "image": "assets/images/bank.jpg",
      "title": "BRAC Bank",
      "address": "Dhanmondi, Dhaka",
      "rating": "4.6",
      "details":
          "Modern banking service and support.",
    },
  ];

  late List<Map<String, String>>
      filteredCenters;

  @override
  void initState() {
    super.initState();
    filteredCenters = centers;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void searchCenters(String value) {
    setState(() {
      filteredCenters = centers.where((center) {
        final title =
            center["title"]!.toLowerCase();

        final address =
            center["address"]!.toLowerCase();

        final query = value.toLowerCase();

        return title.contains(query) ||
            address.contains(query);
      }).toList();
    });
  }

  void bookNow(String centerName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          "Booking request sent to $centerName",
        ),
      ),
    );
  }

  void viewDetails(
    Map<String, String> center,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),

      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(16),

                child: Image.asset(
                  center["image"]!,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                center["title"]!,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 20,
                  ),

                  const SizedBox(width: 5),

                  Text(
                    center["address"]!,
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.orange,
                    size: 20,
                  ),

                  const SizedBox(width: 5),

                  Text(
                    "Rating: ${center["rating"]}",
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Text(
                center["details"]!,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 25),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedCenters =
        showAllCenters
            ? filteredCenters
            : filteredCenters.take(3).toList();

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [
            // TOP SECTION

            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                left: 18,
                right: 18,
                top: 10,
                bottom: 25,
              ),

              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight:
                      Radius.circular(28),
                ),

                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0047B3),
                    Color(0xFFB65AD8),
                  ],
                ),
              ),

              child: Column(
                children: [
                  // TOP ICONS
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.end,

                    children: [
                      circleIcon(
                        Icons.phone_disabled,
                      ),

                      const SizedBox(width: 10),

                      circleIcon(Icons.email),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // LOGO
                  Image.asset(
                    "assets/images/logo.png",
                    width: 100,
                    height: 100,
                  ),

                  const SizedBox(height: 10),

                  // TITLE
                  const Text(
                    "find",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight:
                          FontWeight.bold,
                      height: 1,
                    ),
                  ),

                  const Text(
                    "Service Center",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight:
                          FontWeight.bold,
                      height: 1,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // SEARCH BAR
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,

                        decoration:
                            const BoxDecoration(
                          color:
                              Color(0xFFFF3B30),
                          shape: BoxShape.circle,
                        ),

                        child: const Icon(
                          Icons.tune,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Container(
                          height: 46,

                          decoration:
                              BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(
                              30,
                            ),

                            border: Border.all(
                              color:
                                  Colors.white,
                              width: 1,
                            ),
                          ),

                          child: TextField(
                            controller:
                                searchController,

                            onChanged:
                                searchCenters,

                            style:
                                const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),

                            decoration:
                                const InputDecoration(
                              border:
                                  InputBorder.none,

                              contentPadding:
                                  EdgeInsets.symmetric(
                                vertical: 12,
                              ),

                              prefixIcon: Icon(
                                Icons.search,
                                color:
                                    Colors.white,
                              ),

                              hintText:
                                  "Search by location or center name",

                              hintStyle:
                                  TextStyle(
                                color:
                                    Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // BODY
            Expanded(
              child: Container(
                width: double.infinity,

                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin:
                        Alignment.centerLeft,
                    end:
                        Alignment.centerRight,
                    colors: [
                      Color(0xFF0047B3),
                      Color(0xFFB65AD8),
                    ],
                  ),
                ),

                child: Padding(
                  padding:
                      const EdgeInsets.all(14),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      const Text(
                        "Nearby centers",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 28,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 18),

                      Expanded(
                        child: ListView.builder(
                          itemCount:
                              displayedCenters
                                  .length,

                          itemBuilder:
                              (context, index) {
                            final item =
                                displayedCenters[
                                    index];

                            return Padding(
                              padding:
                                  const EdgeInsets.only(
                                bottom: 16,
                              ),

                              child: Container(
                                decoration:
                                    BoxDecoration(
                                  color:
                                      Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(
                                    20,
                                  ),
                                ),

                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius:
                                          const BorderRadius.only(
                                        topLeft:
                                            Radius.circular(
                                          20,
                                        ),
                                        bottomLeft:
                                            Radius.circular(
                                          20,
                                        ),
                                      ),

                                      child:
                                          Image.asset(
                                        item["image"]!,
                                        width: 105,
                                        height: 110,
                                        fit:
                                            BoxFit.cover,
                                      ),
                                    ),

                                    Expanded(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.all(
                                          12,
                                        ),

                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,

                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child:
                                                      Text(
                                                    item["title"]!,
                                                    maxLines:
                                                        1,
                                                    overflow:
                                                        TextOverflow.ellipsis,

                                                    style:
                                                        const TextStyle(
                                                      fontSize:
                                                          18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),

                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.star,
                                                      color:
                                                          Colors.orange,
                                                      size:
                                                          18,
                                                    ),

                                                    Text(
                                                      item["rating"]!,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),

                                            const SizedBox(
                                              height: 6,
                                            ),

                                            Text(
                                              item["address"]!,
                                              style:
                                                  const TextStyle(
                                                color:
                                                    Colors.grey,
                                                fontSize:
                                                    14,
                                              ),
                                            ),

                                            const SizedBox(
                                              height: 16,
                                            ),

                                            Row(
                                              children: [
                                                Expanded(
                                                  child:
                                                      actionButton(
                                                    text:
                                                        "Book Now",

                                                    onTap:
                                                        () {
                                                      bookNow(
                                                        item["title"]!,
                                                      );
                                                    },
                                                  ),
                                                ),

                                                const SizedBox(
                                                  width:
                                                      10,
                                                ),

                                                Expanded(
                                                  child:
                                                      actionButton(
                                                    text:
                                                        "View Details",

                                                    onTap:
                                                        () {
                                                      viewDetails(
                                                        item,
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      Align(
                        alignment:
                            Alignment.centerRight,

                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              showAllCenters =
                                  !showAllCenters;
                            });
                          },

                          child: Text(
                            showAllCenters
                                ? "Show Less"
                                : "See More",

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
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // BOTTOM NAVIGATION
      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex: currentIndex,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });

          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const MyQueuesScreen(),
              ),
            );
          }

          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const NotificationScreen(),
              ),
            );
          }
        },

        type: BottomNavigationBarType.fixed,

        selectedItemColor: Colors.blue,
        unselectedItemColor:
            Colors.black54,

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
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  Widget actionButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        height: 38,

        decoration: BoxDecoration(
          color: const Color(0xFF109DFF),

          borderRadius:
              BorderRadius.circular(22),
        ),

        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget circleIcon(IconData icon) {
    return Container(
      width: 38,
      height: 38,

      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),

      child: Icon(
        icon,
        size: 18,
        color: Colors.red,
      ),
    );
  }
}