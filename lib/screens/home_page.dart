import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:mediqueue/screens/bookappoinment_page.dart';
import 'package:mediqueue/screens/appoinments_page.dart';
import 'package:mediqueue/screens/prescription_page.dart';
import 'package:mediqueue/screens/image_slider.dart';
import 'package:mediqueue/screens/profile_page.dart';
import 'package:mediqueue/screens/queuestatus_page.dart';

class HomePage extends StatefulWidget {
  final String patientId;

  const HomePage({super.key, required this.patientId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();

    pages = [
      const HomeUI(),
      const AppointmentsPage(),
      const BookAppointmentPage(),
      PrescriptionPage(patientId: widget.patientId),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentIndex],
    );
  }
}

/// ================= HOME UI =================
class HomeUI extends StatelessWidget {
  const HomeUI({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF063C3D), Color(0xFF0F9D9A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 5),

          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(45),
                  topRight: Radius.circular(45),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// WELCOME CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.tealAccent),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            "Welcome to MediQueue 👋",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          ImageSlider(),
                          SizedBox(height: 10),
                          Text(
                            "Your Health, Our Priority 💙",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "Easily book doctors and manage appointments.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    /// QUEUE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const QueueStatusPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.tealAccent,
                        ),
                        child: const Text(
                          "Check Queue Status",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    /// DOCTORS
                    const Text(
                      "Available Doctors",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    SizedBox(
                      height: 180,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                          .collection("doctors")
                          .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(color: Colors.tealAccent),
                            );
                          }
                          if (snapshot.hasError) {
                            return const Center(
                              child: Text("Error loading doctors", style: TextStyle(color: Colors.white70)),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Text("No doctors available", style: TextStyle(color: Colors.white70)),
                            );
                          }

                          final doctors = snapshot.data!.docs;

                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: doctors.length,
                            itemBuilder: (context, index) {
                              final doc = doctors[index].data() as Map<String, dynamic>;

                              return doctorCard(
                                doc['name']?? 'No Name',
                                doc['serviceName']?? 'Doctor',
                                doc['imageUrl']?? '',
                              );
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      "Clinic Services",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    /// SERVICES - SHOW TYPE + DESCRIPTION ONLY
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection("services").snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: Colors.tealAccent),
                          );
                        }
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text("Error loading services", style: TextStyle(color: Colors.white70)),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text("No services available", style: TextStyle(color: Colors.white70)),
                          );
                        }

                        final services = snapshot.data!.docs;

                        return Column(
                          children: services.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.tealAccent),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.local_hospital,
                                    color: Colors.tealAccent,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // ✅ Service Type = name field
                                        Text(
                                          data['name']?? 'Service',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        // ✅ Description only
                                        if (data['description']!= null && data['description'].toString().isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              data['description'],
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget doctorCard(String name, String service, String imageUrl) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.tealAccent),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.teal.shade700,
            backgroundImage: imageUrl.isNotEmpty? NetworkImage(imageUrl) : null,
            child: imageUrl.isEmpty? const Icon(Icons.person, color: Colors.white) : null,
          ),
          const SizedBox(height: 10),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            service,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.tealAccent, fontSize: 11),
          ),
        ],
      ),
    );
  }
}