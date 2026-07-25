import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/dashboard_controller.dart';
import '../controllers/queue_controller.dart';
import '../models/queue_model.dart';
import '../utils/constants.dart';
import 'my_profile_screen.dart';
import 'my_queues_screen.dart';
import 'notification_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int currentIndex = 0;

  final TextEditingController searchController = TextEditingController();

  bool showAllCenters = false;
  String searchQuery = '';
  String selectedCategory = 'All';

  /// Debounces search-box typing so filtering/rebuilds happen once the
  /// person pauses instead of on every single keystroke.
  Timer? _searchDebounce;

  /// Center id currently being booked (shows a spinner on its button).
  String? bookingCenterId;

  @override
  void initState() {
    super.initState();
    // One-time: fills Firestore with demo centers if the collection
    // is empty, so the dashboard always has real, live data.
    DashboardController.seedServiceCentersIfEmpty();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        searchQuery = value;
        showAllCenters = false; // start collapsed for a fresh search
      });
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    searchController.clear();
    setState(() {
      searchQuery = '';
      showAllCenters = false;
    });
  }

  void _selectCategory(String category) {
    setState(() {
      selectedCategory = category;
      showAllCenters = false;
    });
  }


  // ================= BOOK NOW =================

  Future<void> bookNow(ServiceCenter center) async {
    if (bookingCenterId != null) return; // already booking something
    setState(() => bookingCenterId = center.id);

    final error = await QueueController.joinQueue(
      serviceCenterId: center.id,
      serviceCenterName: center.name,
    );

    if (!mounted) return;
    setState(() => bookingCenterId = null);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Text(error),
      ));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      content: Text('Queue booked successfully at ${center.name}'),
    ));

    // Jump straight to My Queue so the user sees their live ticket.
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MyQueuesScreen()),
      );
    }
  }

  // ================= DETAILS =================

  void viewDetails(ServiceCenter center) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    center.image,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: double.infinity,
                      height: 220,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, size: 60, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  center.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red),
                    const SizedBox(width: 6),
                    Expanded(child: Text(center.address)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange),
                    const SizedBox(width: 6),
                    Text(center.rating.toStringAsFixed(1)),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  center.description,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      bookNow(center);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF109DFF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Book Queue',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
            context, MaterialPageRoute(builder: (_) => const MyQueuesScreen()));
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onNavbarTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF109DFF),
        unselectedItemColor: Colors.black54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.sync), label: "Queue"),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: "Notification"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profile"),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<ServiceCenter>>(
          stream: DashboardController.serviceCentersStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF0047B3)));
            }

            final allCenters = snapshot.data ?? [];
            final filteredCenters = DashboardController.filterCenters(
              allCenters,
              searchQuery,
              category: selectedCategory,
            );
            final displayedCenters =
                showAllCenters ? filteredCenters : filteredCenters.take(4).toList();

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // ================= HEADER =================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(left: 18, right: 18, top: 10, bottom: 30),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0047B3), Color(0xFFB65AD8)],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            circleIcon(Icons.phone),
                            const SizedBox(width: 10),
                            circleIcon(Icons.email),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Image.asset(
                          "assets/images/logo.png",
                          width: 100,
                          height: 100,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.image, color: Colors.white, size: 80);
                          },
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Find",
                          style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          "Service Center",
                          style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 25),
                        Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white),
                          ),
                          child: TextField(
                            controller: searchController,
                            onChanged: _onSearchChanged,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              prefixIcon: const Icon(Icons.search, color: Colors.white),
                              hintText: "Search service center",
                              hintStyle: const TextStyle(color: Colors.white70),
                              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                                valueListenable: searchController,
                                builder: (context, value, _) {
                                  if (value.text.isEmpty) return const SizedBox.shrink();
                                  return IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                                    onPressed: _clearSearch,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 34,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _categoryChip('All'),
                              ...ServiceCenterCategories.all.map(_categoryChip),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ================= BODY =================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0047B3), Color(0xFFB65AD8)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Nearby Centers",
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        if (displayedCenters.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Column(
                                children: [
                                  const Icon(Icons.search_off, color: Colors.white70, size: 40),
                                  const SizedBox(height: 10),
                                  Text(
                                    searchQuery.isNotEmpty
                                        ? 'No centers match "$searchQuery"'
                                        : selectedCategory != 'All'
                                            ? 'No $selectedCategory centers yet'
                                            : 'No centers found',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                  if (searchQuery.isNotEmpty || selectedCategory != 'All') ...[
                                    const SizedBox(height: 10),
                                    TextButton(
                                      onPressed: () {
                                        _clearSearch();
                                        setState(() => selectedCategory = 'All');
                                      },
                                      child: const Text('Clear filters',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              decoration: TextDecoration.underline)),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ...displayedCenters.map((center) {
                          final isBooking = bookingCenterId == center.id;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      bottomLeft: Radius.circular(20),
                                    ),
                                    child: Image.asset(
                                      center.image,
                                      width: 105,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 105,
                                        height: 120,
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.image, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  center.name,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              const Icon(Icons.star, color: Colors.orange, size: 18),
                                              const SizedBox(width: 4),
                                              Text(center.rating.toStringAsFixed(1)),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(center.address, style: const TextStyle(color: Colors.grey)),
                                          const SizedBox(height: 15),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: actionButton(
                                                  text: isBooking ? "Booking..." : "Book Now",
                                                  onTap: isBooking ? null : () => bookNow(center),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: actionButton(
                                                  text: "View Details",
                                                  onTap: () => viewDetails(center),
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
                        }),
                        if (filteredCenters.length > 4)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => setState(() => showAllCenters = !showAllCenters),
                              child: Text(
                                showAllCenters ? "Show Less" : "See More",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
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
    );
  }

  // ================= BUTTON =================

  Widget _categoryChip(String label) {
    final selected = selectedCategory == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _selectCategory(label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white70),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF0047B3) : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget actionButton({required String text, required VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: onTap == null ? Colors.grey : const Color(0xFF109DFF),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
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
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Icon(icon, size: 18, color: Colors.red),
    );
  }
}
