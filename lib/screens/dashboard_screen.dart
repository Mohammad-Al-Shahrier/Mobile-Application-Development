import 'package:flutter/material.dart';

import 'my_profile_screen.dart';
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
    {
      "image": "assets/images/cafe.jpg",
      "title": "Cafe Milano",
      "address": "Gulshan, Dhaka",
      "rating": "4.5",
      "details":
          "Luxury cafe with reservation system.",
    },
    {
      "image": "assets/images/hospital.jpg",
      "title": "Popular Diagnostic",
      "address": "Shyamoli, Dhaka",
      "rating": "4.7",
      "details":
          "Diagnostic and healthcare service.",
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

  // ================= SEARCH =================

  void searchCenters(String value) {
    setState(() {
      filteredCenters = centers.where((center) {
        final query =
            value.toLowerCase();

        return center["title"]!
                .toLowerCase()
                .contains(query) ||
            center["address"]!
                .toLowerCase()
                .contains(query);
      }).toList();
    });
  }

  // ================= BOOK NOW =================

  void bookNow(String centerName) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,

        behavior:
            SnackBarBehavior.floating,

        content: Text(
          "Queue booked successfully at $centerName",
        ),
      ),
    );
  }

  // ================= DETAILS =================

  void viewDetails(
    Map<String, String> center,
  ) {
    showModalBottomSheet(
      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.white,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),

      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),

          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),

                  child: Image.asset(
                    center["image"]!,

                    width: double.infinity,
                    height: 220,

                    fit: BoxFit.cover,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  center["title"]!,

                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.red,
                    ),

                    const SizedBox(width: 6),

                    Expanded(
                      child: Text(
                        center["address"]!,
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
                    ),

                    const SizedBox(width: 6),

                    Text(
                      center["rating"]!,
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Text(
                  center["details"]!,

                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 50,

                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);

                      bookNow(
                        center["title"]!,
                      );
                    },

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                        0xFF109DFF,
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),
                    ),

                    child: const Text(
                      "Book Queue",

                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= NAVIGATION =================

  void onNavbarTapped(int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const MyQueuesScreen(),
          ),
        );
        break;

      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const NotificationScreen(),
          ),
        );
        break;

      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const MyProfileScreen(),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedCenters =
        showAllCenters
            ? filteredCenters
            : filteredCenters.take(4).toList();

    return Scaffold(
      backgroundColor: Colors.white,

      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex: currentIndex,

        onTap: onNavbarTapped,

        type:
            BottomNavigationBarType.fixed,

        selectedItemColor:
            const Color(0xFF109DFF),

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
            icon:
                Icon(Icons.notifications),
            label: "Notification",
          ),

          BottomNavigationBarItem(
            icon:
                Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          physics:
              const BouncingScrollPhysics(),

          child: Column(
            children: [
              // ================= HEADER =================

              Container(
                width: double.infinity,

                padding:
                    const EdgeInsets.only(
                  left: 18,
                  right: 18,
                  top: 10,
                  bottom: 30,
                ),

                decoration:
                    const BoxDecoration(
                  gradient: LinearGradient(
                    begin:
                        Alignment.topLeft,
                    end:
                        Alignment.bottomRight,

                    colors: [
                      Color(0xFF0047B3),
                      Color(0xFFB65AD8),
                    ],
                  ),

                  borderRadius:
                      BorderRadius.only(
                    bottomLeft:
                        Radius.circular(30),
                    bottomRight:
                        Radius.circular(30),
                  ),
                ),

                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .end,

                      children: [
                        circleIcon(
                          Icons.phone,
                        ),

                        const SizedBox(
                          width: 10,
                        ),

                        circleIcon(
                          Icons.email,
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    Image.asset(
                      "assets/images/logo.png",

                      width: 100,
                      height: 100,

                      errorBuilder:
                          (
                            context,
                            error,
                            stackTrace,
                          ) {
                        return const Icon(
                          Icons.image,
                          color:
                              Colors.white,
                          size: 80,
                        );
                      },
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    const Text(
                      "Find",

                      style: TextStyle(
                        color:
                            Colors.white,
                        fontSize: 34,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const Text(
                      "Service Center",

                      style: TextStyle(
                        color:
                            Colors.white,
                        fontSize: 34,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 25,
                    ),

                    // SEARCH BAR

                    Container(
                      height: 52,

                      decoration:
                          BoxDecoration(
                        color: Colors.white
                            .withOpacity(
                          0.15,
                        ),

                        borderRadius:
                            BorderRadius.circular(
                          30,
                        ),

                        border: Border.all(
                          color:
                              Colors.white,
                        ),
                      ),

                      child: TextField(
                        controller:
                            searchController,

                        onChanged:
                            searchCenters,

                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                        ),

                        decoration:
                            const InputDecoration(
                          border:
                              InputBorder.none,

                          prefixIcon: Icon(
                            Icons.search,
                            color:
                                Colors.white,
                          ),

                          hintText:
                              "Search service center",

                          hintStyle:
                              TextStyle(
                            color:
                                Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ================= BODY =================

              Container(
                width: double.infinity,

                padding:
                    const EdgeInsets.all(16),

                decoration:
                    const BoxDecoration(
                  gradient: LinearGradient(
                    begin:
                        Alignment.topLeft,
                    end:
                        Alignment.bottomRight,

                    colors: [
                      Color(0xFF0047B3),
                      Color(0xFFB65AD8),
                    ],
                  ),
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    const Text(
                      "Nearby Centers",

                      style: TextStyle(
                        fontSize: 28,
                        fontWeight:
                            FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (displayedCenters
                        .isEmpty)
                      const Center(
                        child: Padding(
                          padding:
                              EdgeInsets.only(
                            top: 40,
                          ),

                          child: Text(
                            "No centers found",

                            style: TextStyle(
                              color:
                                  Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),

                    ...displayedCenters.map(
                      (item) {
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

                              boxShadow: const [
                                BoxShadow(
                                  color:
                                      Colors.black12,
                                  blurRadius: 6,
                                ),
                              ],
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
                                    height: 120,

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

                                    child:
                                        Column(
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

                                            const Icon(
                                              Icons.star,
                                              color:
                                                  Colors.orange,
                                              size:
                                                  18,
                                            ),

                                            const SizedBox(
                                              width:
                                                  4,
                                            ),

                                            Text(
                                              item["rating"]!,
                                            ),
                                          ],
                                        ),

                                        const SizedBox(
                                          height:
                                              6,
                                        ),

                                        Text(
                                          item["address"]!,

                                          style:
                                              const TextStyle(
                                            color:
                                                Colors.grey,
                                          ),
                                        ),

                                        const SizedBox(
                                          height:
                                              15,
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
                            color:
                                Colors.white,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= BUTTON =================

  Widget actionButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        height: 38,

        decoration: BoxDecoration(
          color: const Color(
            0xFF109DFF,
          ),

          borderRadius:
              BorderRadius.circular(
            22,
          ),
        ),

        child: Center(
          child: Text(
            text,

            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ================= TOP ICON =================

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