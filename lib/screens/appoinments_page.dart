import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => AppointmentsPageState();
}

class AppointmentsPageState extends State<AppointmentsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String formatDate(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

  DateTime? parseDate(String date) {
    try {
      final parts = date.split("/");
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> cancelAppointment(String docId) async {
    await _firestore.collection("appointments").doc(docId).update({
      "status": "Cancelled",
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.white),
              SizedBox(width: 12),
              Text("Appointment Cancelled"),
            ],
          ),
          backgroundColor: Colors.redAccent.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> rescheduleAppointment(String docId, String doctorName) async {
    DateTime? newDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.tealAccent,
              onPrimary: Colors.black,
              surface: Color(0xFF0A3F3F),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (newDate == null) return;

    TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.tealAccent,
              onPrimary: Colors.black,
              surface: Color(0xFF0A3F3F),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (newTime == null) return;

    await _firestore.collection("appointments").doc(docId).update({
      "date": formatDate(newDate),
      "time": newTime.format(context),
      "status": "Pending",
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 12),
              Text("Appointment Rescheduled"),
            ],
          ),
          backgroundColor: Colors.teal.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF063C3D),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "My Appointments",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF063C3D), Color(0xFF0A4F4F)],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection("appointments")
                .where("patientId", isEqualTo: uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.tealAccent),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _emptyState();
              }

              final docs = snapshot.data!.docs;
              List<QueryDocumentSnapshot> upcoming = [];
              List<QueryDocumentSnapshot> previous = [];

              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);

              for (var doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                final dateStr = data["date"] ?? "";
                final date = parseDate(dateStr);
                final status = data["status"] ?? "Pending";

                if (status == "Cancelled") {
                  previous.add(doc);
                } else if (date != null && date.isBefore(today)) {
                  previous.add(doc);
                } else {
                  upcoming.add(doc);
                }
              }

              // Sort: upcoming by date asc, previous by date desc
              upcoming.sort((a, b) {
                final dateA = parseDate((a.data() as Map)["date"] ?? "") ?? DateTime(2100);
                final dateB = parseDate((b.data() as Map)["date"] ?? "") ?? DateTime(2100);
                return dateA.compareTo(dateB);
              });

              previous.sort((a, b) {
                final dateA = parseDate((a.data() as Map)["date"] ?? "") ?? DateTime(2000);
                final dateB = parseDate((b.data() as Map)["date"] ?? "") ?? DateTime(2000);
                return dateB.compareTo(dateA);
              });

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                color: Colors.tealAccent,
                backgroundColor: const Color(0xFF0A3F3F),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (upcoming.isNotEmpty) ...[
                      sectionTitle("Upcoming", upcoming.length, Icons.upcoming),
                      ...upcoming.map((doc) => appointmentCard(doc)),
                      const SizedBox(height: 24),
                    ],
                    if (previous.isNotEmpty) ...[
                      sectionTitle("Previous", previous.length, Icons.history),
                      ...previous.map((doc) => appointmentCard(doc)),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            "No Appointments Yet",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Book your first appointment to get started",
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget sectionTitle(String title, int count, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.tealAccent, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.tealAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.tealAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget appointmentCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    String status = data["status"] ?? "Pending";

    final statusConfig = _getStatusConfig(status);
    final isActive = status != "Cancelled" && status != "Completed";

    return Dismissible(
      key: Key(doc.id),
      direction: isActive ? DismissDirection.horizontal : DismissDirection.none,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right - Cancel
          return await _showConfirmDialog(
            "Cancel Appointment?",
            "Are you sure you want to cancel this appointment?",
          );
        } else {
          // Swipe left - Reschedule
          rescheduleAppointment(doc.id, data["doctorName"] ?? "");
          return false;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          cancelAppointment(doc.id);
        }
      },
      background: _swipeBackground(Alignment.centerLeft, Colors.redAccent, Icons.cancel_outlined, "Cancel"),
      secondaryBackground: _swipeBackground(Alignment.centerRight, Colors.tealAccent, Icons.edit_calendar, "Reschedule"),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showDetailsSheet(data),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.tealAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.medical_services, color: Colors.tealAccent, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data["serviceName"] ?? "-",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                data["doctorName"] ?? "-",
                                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        _statusChip(status, statusConfig),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _infoItem(Icons.calendar_today, data["date"] ?? "-"),
                          Container(width: 1, height: 20, color: Colors.white.withOpacity(0.2)),
                          _infoItem(Icons.access_time, data["time"] ?? "-"),
                          Container(width: 1, height: 20, color: Colors.white.withOpacity(0.2)),
                          _infoItem(Icons.confirmation_number, data["queueNumber"] ?? "-"),
                        ],
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => cancelAppointment(doc.id),
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text("Cancel"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => rescheduleAppointment(doc.id, data["doctorName"] ?? ""),
                              icon: const Icon(Icons.edit_calendar, size: 18),
                              label: const Text("Reschedule"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.tealAccent,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.tealAccent.withOpacity(0.8), size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _swipeBackground(Alignment alignment, Color color, IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String status, Map<String, dynamic> config) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: config["color"].withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config["color"].withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config["icon"], color: config["color"], size: 14),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(color: config["color"], fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case "Approved":
        return {"color": Colors.greenAccent, "icon": Icons.check_circle};
      case "Cancelled":
        return {"color": Colors.redAccent, "icon": Icons.cancel};
      case "Completed":
        return {"color": Colors.blueAccent, "icon": Icons.done_all};
      default:
        return {"color": Colors.orangeAccent, "icon": Icons.pending};
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF0A3F3F),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(title, style: const TextStyle(color: Colors.white)),
            content: Text(message, style: TextStyle(color: Colors.white.withOpacity(0.8))),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("No", style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Yes", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showDetailsSheet(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A3F3F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Appointment Details",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _detailRow("Service", data["serviceName"] ?? "-"),
            _detailRow("Doctor", data["doctorName"] ?? "-"),
            _detailRow("Date", data["date"] ?? "-"),
            _detailRow("Time", data["time"] ?? "-"),
            _detailRow("Queue", data["queueNumber"] ?? "-"),
            _detailRow("Fee", "Rs. ${data["fee"] ?? 0}"),
            _detailRow("Status", data["status"] ?? "-"),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
