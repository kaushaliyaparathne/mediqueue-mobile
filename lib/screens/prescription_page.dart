import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PrescriptionPage extends StatefulWidget {
  final String patientId;

  const PrescriptionPage({
    super.key,
    required this.patientId,
  });

  @override
  State<PrescriptionPage> createState() => _PrescriptionPageState();
}

class _PrescriptionPageState extends State<PrescriptionPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? selectedService; // null = All services
  List<String> serviceList = ['All'];
  bool _needsClientSorting = false;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  // Load unique service names for dropdown
  Future<void> _loadServices() async {
    try {
      final snapshot = await _firestore
          .collection("prescriptions")
          .where("patientId", isEqualTo: widget.patientId)
          .get();

      final services = snapshot.docs
          .map((doc) => doc.data()["serviceName"]?.toString() ?? "General")
          .toSet()
          .toList();

      setState(() {
        serviceList = ['All', ...services];
      });
    } catch (e) {
      debugPrint("Error loading services: $e");
    }
  }

  Query<Map<String, dynamic>> _getQuery() {
    Query<Map<String, dynamic>> query = _firestore
        .collection("prescriptions")
        .where("patientId", isEqualTo: widget.patientId);

    // Filter by service if selected
    if (selectedService != null && selectedService != 'All') {
      query = query.where("serviceName", isEqualTo: selectedService);
    }

    // Try server-side sorting. If index missing, we'll catch error and sort client-side
    if (!_needsClientSorting) {
      query = query.orderBy("appointmentDate", descending: true);
    }
    return query;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF063C3D),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFF0A2F2F),
        title: const Text(
          "My Prescriptions",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          // Service filter dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF0A2F2F),
            child: Row(
              children: [
                const Icon(Icons.filter_list, color: Colors.tealAccent),
                const SizedBox(width: 10),
                const Text(
                  "Service:",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedService ?? 'All',
                    dropdownColor: const Color(0xFF0D4D4D),
                    isExpanded: true,
                    underline: const SizedBox(),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    items: serviceList.map((service) {
                      return DropdownMenuItem(
                        value: service,
                        child: Text(service),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedService = value;
                        _needsClientSorting = false; // Reset and try server sort again
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Prescription list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  // If index error, switch to client-side sorting
                  if (snapshot.error.toString().contains('failed-precondition') ||
                      snapshot.error.toString().contains('requires an index')) {
                    if (!_needsClientSorting) {
                      // Trigger rebuild with client sorting
                      Future.microtask(() {
                        setState(() {
                          _needsClientSorting = true;
                        });
                      });
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.tealAccent),
                      );
                    }
                  }
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.orange, size: 60),
                          const SizedBox(height: 16),
                          Text(
                            "Firestore index building...\nTry again in 2 minutes.",
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${snapshot.error}",
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.tealAccent),
                  );
                }

                var docs = snapshot.data?.docs ?? [];

                // Client-side sort if server sort failed due to missing index
                if (_needsClientSorting) {
                  docs.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aDate = aData["appointmentDate"];
                    final bDate = bData["appointmentDate"];
                    
                    if (aDate is Timestamp && bDate is Timestamp) {
                      return bDate.compareTo(aDate); // Descending
                    }
                    return 0;
                  });
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.medical_services_outlined,
                          size: 80,
                          color: Colors.white38,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          selectedService == null || selectedService == 'All'
                              ? "No Prescriptions Found"
                              : "No Prescriptions for $selectedService",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildCard(context, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      color: const Color(0xFF0D4D4D),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PrescriptionDetailPage(data: data),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.tealAccent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.medical_services,
                  color: Colors.tealAccent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data["doctorName"] ?? "Doctor",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.tealAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            data["serviceName"] ?? "General",
                            style: const TextStyle(
                              color: Colors.tealAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data["diagnosis"] ?? "-",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.tealAccent,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _formatDate(data["appointmentDate"]),
                          style: const TextStyle(color: Colors.white60),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white70,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return "-";
    if (date is Timestamp) {
      return DateFormat('dd MMM yyyy').format(date.toDate());
    }
    return date.toString();
  }
}

class PrescriptionDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const PrescriptionDetailPage({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    String patientName = data["patientName"]?.toString() ?? "Patient";

    return Scaffold(
      backgroundColor: const Color(0xFF063C3D),
      appBar: AppBar(
        title: const Text("Prescription Details"),
        backgroundColor: const Color(0xFF0A2F2F),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: Colors.tealAccent,
              child: Text(
                patientName.isNotEmpty ? patientName[0].toUpperCase() : "P",
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              patientName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _card(
              "👤 Patient Details",
              [
                "Name: ${data["patientName"] ?? "-"}",
                "Phone: ${data["phone"] ?? "-"}",
                "Email: ${data["email"] ?? "-"}",
                "Gender: ${data["gender"] ?? "-"}",
                "Address: ${data["address"] ?? "-"}",
              ],
            ),
            _card(
              "👨⚕ Doctor Details",
              [
                "Name: ${data["doctorName"] ?? "-"}",
                "Doctor ID: ${data["doctorId"] ?? "-"}",
              ],
            ),
            _card(
              "📅 Appointment Details",
              [
                "Service: ${data["serviceName"] ?? "General"}",
                "Date: ${_formatDate(data["appointmentDate"])}",
                "Time: ${data["appointmentTime"] ?? "-"}",
                "Status: ${data["appointmentStatus"] ?? "-"}",
                "Queue Number: ${data["queueNumber"] ?? "-"}",
              ],
            ),
            _card(
              "💊 Prescription",
              [
                "Diagnosis: ${data["diagnosis"] ?? "-"}",
                "Notes: ${data["notes"] ?? "-"}",
              ],
            ),
            const SizedBox(height: 15),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Medicines",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildMedicines(data["medicines"]),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicines(dynamic meds) {
    if (meds == null || meds is! List || meds.isEmpty) {
      return const Text(
        "No medicines available",
        style: TextStyle(color: Colors.white70),
      );
    }

    return Column(
      children: (meds).map<Widget>((m) {
        final med = m as Map<String, dynamic>;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: const Color(0xFF0D4D4D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.tealAccent.withOpacity(0.15),
                child: const Icon(
                  Icons.medication,
                  color: Colors.tealAccent,
                ),
              ),
              title: Text(
                med["medicine"] ?? "-",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      backgroundColor: Colors.teal.withOpacity(0.2),
                      label: Text(
                        "Dosage: ${med["dosage"] ?? "-"}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    Chip(
                      backgroundColor: Colors.teal.withOpacity(0.2),
                      label: Text(
                        "Duration: ${med["duration"] ?? "-"}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return "-";
    if (date is Timestamp) {
      return DateFormat('dd MMM yyyy').format(date.toDate());
    }
    return date.toString();
  }

  static Widget _card(String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.tealAccent,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const Divider(color: Colors.white24, height: 20),
          ...items.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                e,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}