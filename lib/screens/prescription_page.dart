import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection("prescriptions")
            .where("patientId", isEqualTo: widget.patientId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Something went wrong",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.tealAccent,
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

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
              final data =
                  docs[index].data() as Map<String, dynamic>;

              return _buildCard(context, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildCard(
      BuildContext context,
      Map<String, dynamic> data,
      ) {
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
              builder: (_) =>
                  PrescriptionDetailPage(data: data),
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
                  color:
                  Colors.tealAccent.withOpacity(0.15),
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
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [
                    Text(
                      data["doctorName"] ?? "Doctor",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      data["diagnosis"] ?? "-",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
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
                          data["appointmentDate"] ?? "-",
                          style: const TextStyle(
                            color: Colors.white60,
                          ),
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
}

class PrescriptionDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const PrescriptionDetailPage({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    String patientName =
        data["patientName"]?.toString() ?? "Patient";

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
                patientName.isNotEmpty
                    ? patientName[0].toUpperCase()
                    : "P",

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
              "👨‍⚕️ Doctor Details",
              [
                "Name: ${data["doctorName"] ?? "-"}",
                "Doctor ID: ${data["doctorId"] ?? "-"}",
              ],
            ),

            _card(
              "📅 Appointment Details",
              [
                "Date: ${data["appointmentDate"] ?? "-"}",
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
    if (meds == null || meds.isEmpty) {
      return const Text(
        "No medicines available",
        style: TextStyle(color: Colors.white70),
      );
    }

    return Column(
      children: (meds as List).map((m) {
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
                backgroundColor:
                Colors.tealAccent.withOpacity(0.15),

                child: const Icon(
                  Icons.medication,
                  color: Colors.tealAccent,
                ),
              ),

              title: Text(
                m["medicine"] ?? "-",
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
                      label: Text(
                        "Dosage: ${m["dosage"] ?? "-"}",
                      ),
                    ),

                    Chip(
                      label: Text(
                        "Duration: ${m["duration"] ?? "-"}",
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

  static Widget _card(
      String title,
      List<String> items,
      ) {
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

        border: Border.all(
          color: Colors.white24,
        ),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.tealAccent,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),

          const Divider(
            color: Colors.white24,
            height: 20,
          ),

          ...items.map(
                (e) => Padding(
              padding:
              const EdgeInsets.symmetric(
                  vertical: 4),
              child: Text(
                e,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}