import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mediqueue/screens/alerts_page.dart';

import 'package:mediqueue/screens/home_page.dart';
import 'package:mediqueue/screens/bookappoinment_page.dart';
import 'package:mediqueue/screens/appoinments_page.dart';
import 'package:mediqueue/screens/prescription_page.dart';
import 'package:mediqueue/screens/profile_page.dart';

class LayoutPage extends StatefulWidget {
  final int startIndex;
  final String patientId;

  const LayoutPage({
    super.key,
    this.startIndex = 0,
    required this.patientId,
  });

  @override
  State<LayoutPage> createState() => _LayoutPageState();
}

class _LayoutPageState extends State<LayoutPage> {
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.startIndex;
  }

  /// ✅ FIX: all pages must receive patientId where required
  List<Widget> get pages => [
        HomePage(patientId: widget.patientId), // 🔥 FIXED
        const AppointmentsPage(),
        const BookAppointmentPage(),
        PrescriptionPage(patientId: widget.patientId),
        const ProfilePage(),
      ];

  void onTabTapped(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF063C3D),

      body: SafeArea(
        child: Column(
          children: [
            /// HEADER
            Container(
  width: double.infinity,
  padding: const EdgeInsets.symmetric(
    horizontal: 25,
    vertical: 15,
  ),
  decoration: const BoxDecoration(
    color: Color(0xFF0A2F2F),
    borderRadius: BorderRadius.only(
      bottomLeft: Radius.circular(25),
      bottomRight: Radius.circular(25),
    ),
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [

      /// LEFT SIDE (LOGO + TEXT)
      Row(
        children: [
          ClipOval(
            child: Image.asset(
              "assets/logo.jpg",
              width: 45,
              height: 45,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(width: 12),

          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "MediQueue",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                "Smart Queue. Better Care.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),

      /// RIGHT SIDE (NOTIFICATION ICON)
      IconButton(
        icon: const Icon(
          Icons.notifications,
          color: Colors.white,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AlertsPage(),
            ),
          );
        },
      ),
    ],
  ),
),
            /// BODY
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0F9D9A),
                      Color(0xFF063C3D),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: pages[currentIndex],
              ),
            ),
          ],
        ),
      ),

      /// BOTTOM NAV
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF063C3D),
        selectedItemColor: Colors.tealAccent,
        unselectedItemColor: Colors.white70,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: "Appointments",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle, size: 30),
            label: "Book",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: "Prescriptions",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}