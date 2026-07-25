import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class QueueStatusPage extends StatefulWidget {
  const QueueStatusPage({super.key});

  @override
  State<QueueStatusPage> createState() => _QueueStatusPageState();
}

class _QueueStatusPageState extends State<QueueStatusPage> {
  String? selectedService;
  bool _alertShown = false; // Alert eka aye aye pennanna epa
  final int avgMinutesPerPatient = 5;

  void _showNextAlert() {
    if (_alertShown || !mounted) return;
    _alertShown = true;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A2F2F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_active, color: Colors.orangeAccent, size: 28),
            ),
            const SizedBox(width: 12),
            const Text(
              "Get Ready!",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          "You're next in the queue. Please be ready and proceed to the consultation room when called.",
          style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              "Got it",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF063C3D),
        body: Center(
          child: Text(
            "User not logged in",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF063C3D),
      body: SafeArea(
        child: Column(
          children: [
            // ================= HEADER =================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              color: const Color(0xFF0A2F2F),
              child: const Row(
                children: [
                  CircleAvatar(radius: 22, backgroundImage: AssetImage("assets/logo.jpg")),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("MediQueue",
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      Text("Smart Queue. Better Care.",
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ================= TITLE =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Queue Status",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Track your live queue position",
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ================= SERVICES =================
            SizedBox(
              height: 110,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("appointments")
                    .where("patientId", isEqualTo: user.uid)
                    .where("status", whereIn: ["Pending", "Approved", "Confirmed", "In Progress"])
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text("Error: ${snapshot.error}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.redAccent)),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("No Active Appointments",
                          style: TextStyle(color: Colors.white70, fontSize: 16)),
                    );
                  }

                  final docs = snapshot.data!.docs;
                  final Set<String> services = {};

                  for (var doc in docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final service = data["serviceName"] ?? data["service"] ?? data["serviceId"];
                    if (service != null && service.toString().isNotEmpty) {
                      services.add(service.toString());
                    }
                  }

                  final list = services.toList();

                  if (selectedService == null && list.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => selectedService = list.first);
                    });
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final s = list[i];
                      final isSelected = selectedService == s;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedService = s;
                            _alertShown = false; // Reset alert for new service
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 180,
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.teal : Colors.white10,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: isSelected ? Colors.tealAccent : Colors.white24,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.tealAccent.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isSelected)
                                  const Icon(Icons.check_circle, color: Colors.white, size: 18),
                                if (isSelected) const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    s,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // ================= LIVE QUEUE =================
            Expanded(
              child: selectedService == null
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.touch_app, color: Colors.white30, size: 48),
                          SizedBox(height: 12),
                          Text("Select a service above",
                              style: TextStyle(color: Colors.white70, fontSize: 16)),
                        ],
                      ),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("appointments")
                          .where("patientId", isEqualTo: user.uid)
                          .where("serviceName", isEqualTo: selectedService)
                          .where("status", whereIn: ["Pending", "Approved", "Confirmed", "In Progress"])
                          .snapshots(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
                        }

                        if (userSnapshot.hasError) {
                          return Center(
                            child: Text("Error: ${userSnapshot.error}",
                                style: const TextStyle(color: Colors.redAccent)),
                          );
                        }

                        if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.event_busy, color: Colors.white30, size: 48),
                                const SizedBox(height: 12),
                                Text("No Active Queue for $selectedService",
                                    style: const TextStyle(color: Colors.white70, fontSize: 16)),
                              ],
                            ),
                          );
                        }

                        final userDocs = userSnapshot.data!.docs.toList();
                        userDocs.sort((a, b) {
                          final aDate = (a.data() as Map<String, dynamic>)["date"] ?? "";
                          final bDate = (b.data() as Map<String, dynamic>)["date"] ?? "";
                          return bDate.toString().compareTo(aDate.toString());
                        });

                        final userDoc = userDocs.first;
                        final userData = userDoc.data() as Map<String, dynamic>;
                        final userQueueNumber = (userData["serviceQueueNumber"] ?? 0) as int;
                        final userStatus = userData["status"] ?? "Unknown";
                        final appointmentDate = userData["date"]?.toString() ?? "";
                        final queueNumberStr = userData["queueNumber"]?.toString() ?? "";
                        bool isAppointmentToday = false;

try {
  DateTime appointment =
      DateFormat("dd/MM/yyyy").parse(appointmentDate);

  DateTime today = DateTime.now();

  isAppointmentToday =
      appointment.year == today.year &&
      appointment.month == today.month &&
      appointment.day == today.day;
} catch (e) {
  isAppointmentToday = false;
}

                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("appointments")
                              .where("serviceName", isEqualTo: selectedService)
                              .where("date", isEqualTo: appointmentDate)
                              .where("status", whereIn: ["Pending", "Approved", "Confirmed", "In Progress"])
                              .snapshots(),
                          builder: (context, queueSnapshot) {
                            if (queueSnapshot.hasError) {
                              return Center(
                                child: Text("Queue Error: ${queueSnapshot.error}",
                                    style: const TextStyle(color: Colors.redAccent)),
                              );
                            }

                            if (!queueSnapshot.hasData) {
                              return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
                            }

                            final allQueueDocs = queueSnapshot.data!.docs.toList();
                            
                            allQueueDocs.sort((a, b) {
                              final aData = a.data() as Map<String, dynamic>;
                              final bData = b.data() as Map<String, dynamic>;
                              final aNum = (aData["serviceQueueNumber"] ?? 0) as int;
                              final bNum = (bData["serviceQueueNumber"] ?? 0) as int;
                              return aNum.compareTo(bNum);
                            });
                            
                            if (userQueueNumber == 0) {
                              return const Center(
                                child: Text("Queue number not assigned yet",
                                    style: TextStyle(color: Colors.white70, fontSize: 16)),
                              );
                            }

                            // Calculate position & current serving
                            int position = 1;
                            int peopleAhead = 0;
                            bool userFound = false;
                            int currentServingNumber = 0;
                            String currentServingPatient = "None";

                            for (var doc in allQueueDocs) {
                              final data = doc.data() as Map<String, dynamic>;
                              final queueNum = (data["serviceQueueNumber"] ?? 0) as int;
                              final status = data["status"] ?? "";
                              
                              if (status == "In Progress" && currentServingNumber == 0) {
                                currentServingNumber = queueNum;
                                currentServingPatient = data["patientName"] ?? "Unknown";
                              }
                              
                              if (doc.id == userDoc.id) {
                                userFound = true;
                                break;
                              }
                              
                              if (queueNum > 0 && queueNum < userQueueNumber) {
                                peopleAhead++;
                                position++;
                              }
                            }

                            if (currentServingNumber == 0 && allQueueDocs.isNotEmpty) {
                              final firstData = allQueueDocs.first.data() as Map<String, dynamic>;
                              currentServingNumber = (firstData["serviceQueueNumber"] ?? 0) as int;
                              currentServingPatient = firstData["patientName"] ?? "Unknown";
                            }

                            if (!userFound) {
                              return const Center(
                                child: Text("Your appointment not found in queue",
                                    style: TextStyle(color: Colors.white70, fontSize: 16)),
                              );
                            }

                            // TRIGGER ALERT WHEN USER IS NEXT
                            if (peopleAhead == 1 && userStatus != "In Progress") {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _showNextAlert();
                              });
                            }

                            // Calculate estimated wait time
                            final estimatedWaitMinutes = peopleAhead * avgMinutesPerPatient;
                            final hours = estimatedWaitMinutes ~/ 60;
                            final minutes = estimatedWaitMinutes % 60;
                            String waitTimeText = "";
                            if (hours > 0) {
                              waitTimeText = "$hours hr $minutes min";
                            } else {
                              waitTimeText = "$minutes min";
                            }

                            Color statusColor;
                            switch (userStatus) {
                              case "Approved":
                              case "Confirmed":
                                statusColor = Colors.greenAccent;
                                break;
                              case "In Progress":
                                statusColor = Colors.orangeAccent;
                                break;
                              default:
                                statusColor = Colors.yellowAccent;
                            }
if (!isAppointmentToday) {
  return Center(
    child: Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.tealAccent),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.event_available,
            color: Colors.tealAccent,
            size: 70,
          ),
          const SizedBox(height: 20),
          const Text(
            "Appointment Scheduled",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            "Date : $appointmentDate",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Time : ${userData["time"] ?? ""}",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            "Live queue tracking will be available on your appointment date.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.orangeAccent,
              fontSize: 16,
            ),
          ),
        ],
      ),
    ),
  );
}

                            return StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection("queue_status")
                                  .doc(selectedService!.trim())
                                  .snapshots(),
                              builder: (context, queueStatusSnapshot) {
                                final queueStatusData = queueStatusSnapshot.data
                                    ?.data() as Map<String, dynamic>?;
                                final currentServing =
                                    (queueStatusData?["currentServing"] ?? 0) as num;

                                if (currentServing <= 0) {
                                  return Center(
                                    child: Container(
                                      margin: const EdgeInsets.all(20),
                                      padding: const EdgeInsets.all(25),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.orangeAccent),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.hourglass_empty,
                                            color: Colors.orangeAccent,
                                            size: 70,
                                          ),
                                          const SizedBox(height: 20),
                                          const Text(
                                            "Queue Not Started Yet",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            "The staff hasn't started the queue for $selectedService yet. Please check back soon.",
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 15,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                return SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  // ========== CURRENT SERVING CARD ==========
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5), width: 2),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: Colors.orangeAccent,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.orangeAccent,
                                                    blurRadius: 8,
                                                    spreadRadius: 2,
                                                  )
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              "NOW SERVING",
                                              style: TextStyle(
                                                color: Colors.orangeAccent,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          currentServingNumber > 0 ? "#$currentServingNumber" : "Waiting",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 48,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (currentServingPatient != "None") ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            currentServingPatient,
                                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // ========== YOUR POSITION CARD ==========
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.teal.shade700, Colors.teal.shade900],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.tealAccent.withValues(alpha: 0.3),
                                          blurRadius: 15,
                                          spreadRadius: 2,
                                        )
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          "Your Position",
                                          style: TextStyle(color: Colors.white70, fontSize: 14),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "$position",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 64,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          peopleAhead == 0 
                                              ? "You're next!" 
                                              : "$peopleAhead ${peopleAhead == 1 ? 'person' : 'people'} ahead of you",
                                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // ========== WAIT TIME CARD ==========
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.schedule, color: Colors.blueAccent, size: 32),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                "Estimated Wait Time",
                                                style: TextStyle(color: Colors.white70, fontSize: 13),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                peopleAhead == 0 ? "Your turn now!" : waitTimeText,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // ========== DETAILS CARD ==========
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: Column(
                                      children: [
                                        _buildDetailRow(
                                          Icons.confirmation_number,
                                          "Your Queue Number",
                                          queueNumberStr.isNotEmpty ? queueNumberStr : "E-$userQueueNumber",
                                        ),
                                        const Divider(color: Colors.white12, height: 24),
                                        _buildDetailRow(
                                          Icons.local_hospital,
                                          "Doctor",
                                          userData["doctorName"] ?? "Not Assigned",
                                        ),
                                        const Divider(color: Colors.white12, height: 24),
                                        _buildDetailRow(
                                          Icons.calendar_today,
                                          "Date",
                                          appointmentDate,
                                        ),
                                        const Divider(color: Colors.white12, height: 24),
                                        _buildDetailRow(
                                          Icons.access_time,
                                          "Time",
                                          userData["time"] ?? "Not Set",
                                        ),
                                        const Divider(color: Colors.white12, height: 24),
                                        _buildDetailRow(
                                          Icons.person,
                                          "Patient",
                                          userData["patientName"] ?? "Unknown",
                                        ),
                                        const Divider(color: Colors.white12, height: 24),
                                        Row(
                                          children: [
                                            const Icon(Icons.info_outline, color: Colors.white70, size: 20),
                                            const SizedBox(width: 12),
                                            const Text(
                                              "Status",
                                              style: TextStyle(color: Colors.white70, fontSize: 14),
                                            ),
                                            const Spacer(),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: statusColor.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: statusColor),
                                              ),
                                              child: Text(
                                                userStatus,
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 16),
                                  
                                  // ========== TOTAL IN QUEUE ==========
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.groups, color: Colors.tealAccent, size: 20),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            "Total in queue: ${allQueueDocs.length} patients",
                                            style: TextStyle(color: Colors.tealAccent.shade100, fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}