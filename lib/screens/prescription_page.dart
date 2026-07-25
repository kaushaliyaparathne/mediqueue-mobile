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
  bool _needsClientSorting = false;

  Query<Map<String, dynamic>> _getQuery() {
    Query<Map<String, dynamic>> query = _firestore
        .collection("prescriptions")
        .where("patientId", isEqualTo: widget.patientId);

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
        backgroundColor: const Color(0xFF063C3D),
        title: const Text(
          "My Prescriptions",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getQuery().snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final isIndexError = snapshot.error.toString().contains('failed-precondition') ||
                snapshot.error.toString().contains('requires an index');

            // Index still building: silently fall back to client-side sorting
            if (isIndexError) {
              if (!_needsClientSorting) {
                Future.microtask(() {
                  setState(() {
                    _needsClientSorting = true;
                  });
                });
              }
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF00D9A3)),
              );
            }

            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "Something went wrong. Please try again later.",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00D9A3)),
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
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 80,
                    color: Colors.white38,
                  ),
                  SizedBox(height: 15),
                  Text(
                    "No Prescriptions Found",
                    style: TextStyle(
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
    );
  }

  Widget _buildCard(BuildContext context, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00D9A3).withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
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
                      color: const Color(0xFF00D9A3).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.medical_services,
                      color: Color(0xFF00D9A3),
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
                                color: const Color(0xFF00D9A3).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                data["serviceName"] ?? "General",
                                style: const TextStyle(
                                  color: Color(0xFF00D9A3),
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
                              color: Color(0xFF00D9A3),
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
        elevation: 0,
        title: const Text(
          "Prescription Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF063C3D),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: const Color(0xFF00D9A3),
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
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF00D9A3).withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF00D9A3).withValues(alpha: 0.15),
                child: const Icon(
                  Icons.medication,
                  color: Color(0xFF00D9A3),
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
                      backgroundColor: const Color(0xFF00D9A3).withValues(alpha: 0.2),
                      label: Text(
                        "Dosage: ${med["dosage"] ?? "-"}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    Chip(
                      backgroundColor: const Color(0xFF00D9A3).withValues(alpha: 0.2),
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
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00D9A3).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF00D9A3),
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