import 'package:flutter/material.dart';

class MyQueuesScreen extends StatefulWidget {
  const MyQueuesScreen({super.key});

  @override
  State<MyQueuesScreen> createState() =>
      _MyQueuesScreenState();
}

class _MyQueuesScreenState
    extends State<MyQueuesScreen> {
  int currentIndex = 1;

  final List<Map<String, String>> historyList = [
    {
      "title": "City Bank PLC",
      "email": "saraaaal212@gmail.com",
    },
    {
      "title": "City Bank PLC",
      "email": "saraaaal212@gmail.com",
    },
    {
      "title": "United Hospital Limited",
      "email": "saraaaal212@gmail.com",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Column(
        children: [
          // ================= TOP SECTION =================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 70,
              bottom: 30,
            ),

            decoration: const BoxDecoration(
              color: Color(0xFFD6DEE8),

              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
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

                SizedBox(height: 5),

                Text(
                  "We are there for you to find your serial",
                  style: TextStyle(
                    fontSize: 12,
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
                            0xFFE9E4EA,
                          ),

                          borderRadius:
                              BorderRadius.circular(
                            22,
                          ),
                        ),

                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 2,
                                    color: Colors.grey
                                        .shade400,
                                  ),
                                ),

                                const Padding(
                                  padding:
                                      EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),

                                  child: Text(
                                    "Active Queues",
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
                                  child: Container(
                                    height: 2,
                                    color: Colors.grey
                                        .shade400,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 15),

                            const Text(
                              "City Bank PLC",
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 22),

                            infoRow(
                              "Ticket ID",
                              "qe1234",
                            ),

                            const SizedBox(height: 14),

                            infoRow(
                              "Positoin",
                              "3",
                            ),

                            const SizedBox(height: 14),

                            infoRow(
                              "Status",
                              "Waiting",
                            ),

                            const SizedBox(height: 25),

                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),

                              decoration:
                                  BoxDecoration(
                                color: Colors.grey
                                    .shade300,

                                borderRadius:
                                    BorderRadius.circular(
                                  25,
                                ),
                              ),

                              child: const Text(
                                "Est. wait Time : 18 mins",
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            Row(
                              children: [
                                Expanded(
                                  child: actionButton(
                                    text:
                                        "Cancel Ticket",
                                  ),
                                ),

                                const SizedBox(
                                  width: 14,
                                ),

                                Expanded(
                                  child: actionButton(
                                    text:
                                        "View status",
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 35),

                      // ================= HISTORY =================

                      const Text(
                        "History",
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight:
                              FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 18),

                      ListView.builder(
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),

                        itemCount:
                            historyList.length,

                        itemBuilder:
                            (context, index) {
                          final item =
                              historyList[index];

                          return Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom: 14,
                            ),

                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),

                              decoration:
                                  BoxDecoration(
                                color: Colors.white,

                                borderRadius:
                                    BorderRadius.circular(
                                  18,
                                ),
                              ),

                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 42,
                                  ),

                                  const SizedBox(
                                    width: 10,
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
                                                20,
                                            fontWeight:
                                                FontWeight
                                                    .bold,
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

                                  const Icon(
                                    Icons
                                        .keyboard_arrow_right,
                                    size: 32,
                                    color:
                                        Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // ================= INDICATOR =================

                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 7,

                            decoration:
                                BoxDecoration(
                              color: Colors.red,

                              borderRadius:
                                  BorderRadius.circular(
                                20,
                              ),
                            ),
                          ),

                          const SizedBox(width: 6),

                          dotIndicator(),
                          const SizedBox(width: 6),
                          dotIndicator(),
                          const SizedBox(width: 6),
                          dotIndicator(),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ================= SEE MORE =================

                      Align(
                        alignment:
                            Alignment.centerRight,

                        child: TextButton(
                          onPressed: () {},

                          child: const Text(
                            "See More >",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight:
                                  FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),

                      // ================= BUTTON =================

                      SizedBox(
                        width: double.infinity,
                        height: 55,

                        child: ElevatedButton(
                          onPressed: () {},

                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.grey.shade300,

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                30,
                              ),
                            ),

                            elevation: 0,
                          ),

                          child: const Text(
                            "Join New Queue",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 24,
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

      // ================= BOTTOM NAVIGATION =================

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,

        type: BottomNavigationBarType.fixed,

        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
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
            icon: Icon(Icons.person_outline),
            label: "",
          ),
        ],
      ),
    );
  }

  // ================= INFO ROW =================

  Widget infoRow(String title, String value) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,

      children: [
        SizedBox(
          width: 130,

          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const Text(
          ":",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(width: 18),

        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ================= ACTION BUTTON =================

  Widget actionButton({
    required String text,
  }) {
    return Container(
      height: 42,

      decoration: BoxDecoration(
        color: Colors.grey.shade300,

        borderRadius:
            BorderRadius.circular(25),
      ),

      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ================= DOT INDICATOR =================

  Widget dotIndicator() {
    return Container(
      width: 12,
      height: 7,

      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius:
            BorderRadius.circular(20),
      ),
    );
  }
}