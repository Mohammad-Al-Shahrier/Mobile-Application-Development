import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState
    extends State<DashboardScreen> {
  int currentIndex = 0;

  final List<Map<String, String>> centers = [
    {
      "image": "assets/images/hospital.jpg",
      "title": "United Hospital Limited",
      "address": "Address uttara",
      "rating": "4.8",
    },
    {
      "image": "assets/images/bank.jpg",
      "title": "City Bank PLC",
      "address": "Address mirpur",
      "rating": "4.9",
    },
    {
      "image": "assets/images/cafe.jpg",
      "title": "UrbanBite Cafe",
      "address": "Address uttara",
      "rating": "4.8",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Column(
        children: [
          // TOP SECTION
          Container(
            width: double.infinity,
            height: 250,

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

            child: Stack(
              children: [
                Positioned(
                  bottom: 0,
                  child: Container(
                    width:
                        MediaQuery.of(context)
                            .size
                            .width,

                    height: 70,

                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black87,
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ),

                SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      // LOGO
                      Center(
                        child: Image.asset(
                          "assets/images/logo.png",
                          width: 90,
                          height: 90,
                        ),
                      ),

                      const SizedBox(height: 5),

                      // TITLE
                      const Text(
                        "find",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),

                      const Text(
                        "Service Center",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                // RIGHT ICONS
                Positioned(
                  right: 10,
                  top: 50,

                  child: Column(
                    children: [
                      circleIcon(
                        Icons.phone_in_talk,
                      ),

                      const SizedBox(height: 10),

                      circleIcon(
                        Icons.email,
                      ),
                    ],
                  ),
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
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF0047B3),
                    Color(0xFFB65AD8),
                  ],
                ),
              ),

              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 15,
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      // SEARCH
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,

                            decoration:
                                const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),

                            child: const Icon(
                              Icons.tune,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),

                          const SizedBox(width: 8),

                          Expanded(
                            child: Container(
                              height: 40,

                              decoration:
                                  BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(
                                        25),

                                border: Border.all(
                                  color:
                                      Colors.white70,
                                ),
                              ),

                              child: TextField(
                                decoration:
                                    InputDecoration(
                                  border:
                                      InputBorder.none,

                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 10,
                                  ),

                                  hintText:
                                      "Search by location center na.",

                                  hintStyle:
                                      const TextStyle(
                                    color:
                                        Colors.white70,
                                    fontSize: 12,
                                  ),

                                  suffixIcon:
                                      const Icon(
                                    Icons.search,
                                    color:
                                        Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 35),

                      // TITLE
                      const Text(
                        "Nearby centers",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 26,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      // CARD LIST
                      ListView.builder(
                        itemCount: centers.length,
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),

                        itemBuilder: (
                          context,
                          index,
                        ) {
                          final item =
                              centers[index];

                          return Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom: 12,
                            ),

                            child: Container(
                              height: 95,

                              decoration:
                                  BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(
                                        15),
                              ),

                              child: Row(
                                children: [
                                  // IMAGE
                                  ClipRRect(
                                    borderRadius:
                                        const BorderRadius.only(
                                      topLeft:
                                          Radius.circular(
                                              15),
                                      bottomLeft:
                                          Radius.circular(
                                              15),
                                    ),

                                    child:
                                        Image.asset(
                                      item["image"]!,
                                      width: 100,
                                      height: 95,
                                      fit: BoxFit.cover,
                                    ),
                                  ),

                                  Expanded(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.all(
                                              8),

                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,

                                        children: [
                                          // TOP
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceBetween,

                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item["title"]!,
                                                  maxLines:
                                                      1,

                                                  overflow:
                                                      TextOverflow
                                                          .ellipsis,

                                                  style:
                                                      const TextStyle(
                                                    fontSize:
                                                        16,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                              ),

                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal:
                                                      5,
                                                  vertical:
                                                      2,
                                                ),

                                                decoration:
                                                    BoxDecoration(
                                                  color: Colors
                                                      .grey
                                                      .shade200,

                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8),
                                                ),

                                                child:
                                                    Row(
                                                  children: [
                                                    const Icon(
                                                      Icons
                                                          .star,
                                                      color:
                                                          Colors.red,
                                                      size:
                                                          12,
                                                    ),

                                                    Text(
                                                      item["rating"]!,
                                                      style:
                                                          const TextStyle(
                                                        fontSize:
                                                            10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(
                                              height:
                                                  4),

                                          Text(
                                            item["address"]!,
                                            style:
                                                const TextStyle(
                                              color:
                                                  Colors
                                                      .grey,
                                              fontSize:
                                                  13,
                                            ),
                                          ),

                                          const Spacer(),

                                          Row(
                                            children: [
                                              Expanded(
                                                child:
                                                    smallButton(
                                                  "Book Now",
                                                ),
                                              ),

                                              const SizedBox(
                                                  width:
                                                      8),

                                              Expanded(
                                                child:
                                                    smallButton(
                                                  "View Details",
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

                      const SizedBox(height: 15),

                      // INDICATOR
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 5,

                            decoration:
                                BoxDecoration(
                              color: Colors.red,
                              borderRadius:
                                  BorderRadius.circular(
                                      10),
                            ),
                          ),

                          const SizedBox(width: 5),

                          dot(),

                          const SizedBox(width: 5),

                          dot(),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Align(
                        alignment:
                            Alignment.centerRight,

                        child: Row(
                          mainAxisSize:
                              MainAxisSize.min,

                          children: const [
                            Text(
                              "See More",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            SizedBox(width: 3),

                            Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.black,
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
        ],
      ),

      // BOTTOM NAVBAR
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,

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
            icon: Icon(Icons.person_outline),
            label: "",
          ),
        ],
      ),
    );
  }

  Widget smallButton(String text) {
    return Container(
      height: 30,

      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(15),
      ),

      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget dot() {
    return Container(
      width: 8,
      height: 8,

      decoration: const BoxDecoration(
        color: Colors.white70,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget circleIcon(IconData icon) {
    return Container(
      width: 25,
      height: 25,

      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),

      child: Icon(
        icon,
        size: 15,
        color: Colors.red,
      ),
    );
  }
}