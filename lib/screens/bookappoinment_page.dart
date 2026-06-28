import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BookAppointmentPage extends StatefulWidget {
  const BookAppointmentPage({super.key});

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> doctors = [];
  List<Map<String, dynamic>> filteredDoctors = [];
  List<String> services = [];

  String? selectedService;
  String? selectedDoctor;
  String? selectedDoctorId;
  
  List<String> doctorWorkingDays = [];
  Map<String, dynamic> doctorTimeSlots = {"start": "09:00", "end": "17:00"};
  List<String> doctorBlockedDates = [];
  String doctorStatus = "Available";
  String selectedDoctorSchedule = "everyday";

  String doctorFee = "";
  String serviceFee = ""; // 👈 අලුතෙන් add කළා
  String doctorImage = "";
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  String? patientName;

  int nextServiceQueueNumber = 1;
  String queuePreview = "";

  bool isLoading = true;

  final Map<String, String> serviceCode = {
    "Child Care": "C",
    "Dental Care": "D",
    "Eye Care": "E",
    "Laboratory Tests": "L",
    "Heart Care": "H",
    "General Consultation": "G",
  };

  @override
  void initState() {
    super.initState();
    fetchDoctors();
    fetchPatient();
  }

  bool isDoctorAvailableOnDate(DateTime date) {
    if (doctorStatus != "Available") return false;

    String dayName = DateFormat('EEEE').format(date);
    if (doctorWorkingDays.isNotEmpty && !doctorWorkingDays.contains(dayName)) {
      return false;
    }

    String dateStr = DateFormat('yyyy-MM-dd').format(date);
    if (doctorBlockedDates.contains(dateStr)) return false;

    if (doctorWorkingDays.isEmpty) {
      return _isDoctorAvailableOld(date, selectedDoctorSchedule);
    }

    return true;
  }

  bool isDoctorAvailableAtTime(TimeOfDay time) {
    String selectedTimeStr = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    String startTime = doctorTimeSlots["start"] ?? "09:00";
    String endTime = doctorTimeSlots["end"] ?? "17:00";

    return selectedTimeStr.compareTo(startTime) >= 0 && selectedTimeStr.compareTo(endTime) <= 0;
  }

  bool _isDoctorAvailableOld(DateTime date, String schedule) {
    String day = DateFormat('EEEE').format(date).toLowerCase();
    String sch = schedule.toLowerCase();

    if (sch == "everyday") return true;
    if (sch == "weekdays") return date.weekday >= 1 && date.weekday <= 5;
    if (sch == "weekends") return date.weekday == 6 || date.weekday == 7;
    return sch == day;
  }

  Future<void> fetchPatient() async {
    final uid = _auth.currentUser!.uid;
    final doc = await _firestore.collection("users").doc(uid).get();

    setState(() {
      patientName = doc.data()?["fullName"] ?? "Unknown";
    });
  }

  Future<void> fetchDoctors() async {
    try {
      final snapshot = await _firestore.collection("doctors").get();

      Set<String> serviceSet = {};
      List<Map<String, dynamic>> loaded = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();

        String serviceName =
            data["serviceName"]?.toString().trim() ??
            data["service"]?.toString().trim() ??
            "";

        if (serviceName.isEmpty) continue;

        loaded.add({
          "id": doc.id,
          "name": data["name"]?.toString() ?? "",
          "service": serviceName,
          "fee": data["fee"] ?? 0,
          "schedule": data["schedule"]?.toString() ?? "everyday",
          "imageUrl": data["imageUrl"]?.toString() ?? "",
          "workingDays": List<String>.from(data["workingDays"] ?? []),
          "timeSlots": data["timeSlots"] ?? {"start": "09:00", "end": "17:00"},
          "blockedDates": List<String>.from(data["blockedDates"] ?? []),
          "status": data["status"]?.toString() ?? "Available",
        });

        serviceSet.add(serviceName);
      }

      setState(() {
        doctors = loaded;
        services = serviceSet.toList()..sort();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching doctors: $e");
      setState(() => isLoading = false);
    }
  }

  Future<int> generateFinalQueueNumber(
    String service,
    DateTime selectedDate,
  ) async {
    String formattedDate =
        "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";

    final snapshot = await _firestore
        .collection("appointments")
        .where("serviceName", isEqualTo: service)
        .where("date", isEqualTo: formattedDate)
        .where("status", whereIn: ["Pending", "Approved"])
        .get();

    List<int> usedNumbers = [];

    for (var doc in snapshot.docs) {
      usedNumbers.add(doc["serviceQueueNumber"] ?? 0);
    }

    usedNumbers.sort();

    int nextNumber = 1;

    for (int num in usedNumbers) {
      if (num == nextNumber) {
        nextNumber++;
      } else {
        break;
      }
    }

    return nextNumber;
  }

  void filterDoctors(String service) {
    // 👈 Service එකේ price එක ගන්නවා
    final selectedServiceData = services.isNotEmpty 
        ? doctors.firstWhere((d) => d["service"] == service, orElse: () => {})
        : {};
    
    setState(() {
      selectedService = service;
      filteredDoctors = doctors.where((d) => d["service"] == service).toList();

      selectedDoctor = null;
      selectedDoctorId = null;
      doctorFee = "";
      serviceFee = ""; // 👈 Reset කරනවා
      doctorImage = "";
      doctorWorkingDays = [];
      doctorTimeSlots = {"start": "09:00", "end": "17:00"};
      doctorBlockedDates = [];
      doctorStatus = "Available";
      selectedDoctorSchedule = "everyday";
      selectedDate = null;
      selectedTime = null;
      queuePreview = "";
    });
  }

  void selectDoctor(String name) {
    final doctor = doctors.firstWhere((d) => d["name"] == name);

    setState(() {
      selectedDoctor = name;
      selectedDoctorId = doctor["id"];
      doctorFee = doctor["fee"].toString();
      doctorImage = doctor["imageUrl"] ?? "";
      selectedDoctorSchedule = doctor["schedule"] ?? "everyday";
      doctorWorkingDays = List<String>.from(doctor["workingDays"] ?? []);
      doctorTimeSlots = Map<String, dynamic>.from(
          doctor["timeSlots"] ?? {"start": "09:00", "end": "17:00"});
      doctorBlockedDates = List<String>.from(doctor["blockedDates"] ?? []);
      doctorStatus = doctor["status"] ?? "Available";

      selectedDate = null;
      selectedTime = null;
      queuePreview = "";
    });
  }

  Future<void> updateQueuePreview() async {
    if (selectedService == null || selectedDate == null) return;

    final number = await generateFinalQueueNumber(
      selectedService!,
      selectedDate!,
    );

    // 👈 Service price එක fetch කරනවා
    final serviceDoc = await _firestore.collection("services")
        .where("name", isEqualTo: selectedService)
        .limit(1)
        .get();
    
    String price = "0";
    if (serviceDoc.docs.isNotEmpty) {
      price = serviceDoc.docs.first.data()["price"]?.toString() ?? "0";
    }

    setState(() {
      nextServiceQueueNumber = number;
      serviceFee = price; // 👈 Service price set කරනවා
      generatePreview();
    });
  }

  void generatePreview() {
    if (selectedService == null || selectedDate == null) return;
    final code = serviceCode[selectedService!] ?? "X";
    queuePreview =
        "MQ-$code-${nextServiceQueueNumber.toString().padLeft(3, '0')}";
  }

  Future<void> pickDate() async {
    if (selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a doctor first")),
      );
      return;
    }

    if (doctorStatus != "Available") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Doctor is currently unavailable")),
      );
      return;
    }

    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      selectableDayPredicate: (DateTime date) {
        return isDoctorAvailableOnDate(date);
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00D9A3),
              onPrimary: Colors.black,
              surface: Color(0xFF0A3F3F),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF063C3D),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() => selectedDate = date);
      await updateQueuePreview();
    }
  }

  Future<void> pickTime() async {
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a date first")),
      );
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00D9A3),
              onPrimary: Colors.black,
              surface: Color(0xFF0A3F3F),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF063C3D),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      if (!isDoctorAvailableAtTime(time)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Doctor only available ${doctorTimeSlots['start']} - ${doctorTimeSlots['end']}",
            ),
          ),
        );
        return;
      }
      setState(() => selectedTime = time);
    }
  }

  Future<bool> alreadyBooked() async {
    if (selectedDoctor == null || selectedDate == null) return false;

    final formattedDate =
        "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}";

    final snapshot = await _firestore
        .collection("appointments")
        .where("patientId", isEqualTo: _auth.currentUser!.uid)
        .where("doctorName", isEqualTo: selectedDoctor)
        .where("date", isEqualTo: formattedDate)
        .where("status", whereIn: ["Pending", "Approved"])
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<bool> isSlotBooked() async {
    if (selectedDoctorId == null || selectedDate == null || selectedTime == null) {
      return false;
    }

    final formattedDate =
        "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}";
    final formattedTime = selectedTime!.format(context);

    final snapshot = await _firestore
        .collection("appointments")
        .where("doctorId", isEqualTo: selectedDoctorId)
        .where("date", isEqualTo: formattedDate)
        .where("time", isEqualTo: formattedTime)
        .where("status", whereIn: ["Pending", "Approved", "Confirmed", "In Progress"])
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<void> bookAppointment() async {
    if (selectedService == null ||
        selectedDoctor == null ||
        selectedDoctorId == null ||
        selectedDate == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    if (!isDoctorAvailableOnDate(selectedDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Doctor not available on selected day")),
      );
      return;
    }

    if (!isDoctorAvailableAtTime(selectedTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Doctor only available ${doctorTimeSlots['start']} - ${doctorTimeSlots['end']}",
          ),
        ),
      );
      return;
    }

    bool slotBooked = await isSlotBooked();
    if (slotBooked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This time slot is already booked")),
      );
      return;
    }

    bool exists = await alreadyBooked();
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You already booked this doctor on this date"),
        ),
      );
      return;
    }

    final latestNumber = await generateFinalQueueNumber(
      selectedService!,
      selectedDate!,
    );
    final code = serviceCode[selectedService!] ?? "X";
    final formattedQueue =
        "MQ-$code-${latestNumber.toString().padLeft(3, '0')}";

    // 👈 Service price එක use කරනවා
    final serviceDoc = await _firestore.collection("services")
        .where("name", isEqualTo: selectedService)
        .limit(1)
        .get();
    final servicePrice = serviceDoc.docs.isNotEmpty 
        ? serviceDoc.docs.first.data()["price"] ?? 0 
        : 0;

    await _firestore.collection("appointments").add({
      "patientId": _auth.currentUser!.uid,
      "patientName": patientName ?? "Unknown",
      "doctorId": selectedDoctorId,
      "doctorName": selectedDoctor,
      "serviceId": selectedService,
      "serviceName": selectedService,
      "fee": servicePrice, // 👈 Service price save කරනවා
      "date":
          "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
      "time": selectedTime!.format(context),
      "queueNumber": formattedQueue,
      "serviceQueueNumber": latestNumber,
      "status": "Pending",
      "createdAt": Timestamp.now(),
    });

    setState(() {
      selectedService = null;
      selectedDoctor = null;
      selectedDoctorId = null;
      selectedDate = null;
      selectedTime = null;
      doctorFee = "";
      serviceFee = ""; // 👈 Reset
      filteredDoctors = [];
      queuePreview = "";
      nextServiceQueueNumber = 1;
      selectedDoctorSchedule = "everyday";
      doctorWorkingDays = [];
      doctorTimeSlots = {"start": "09:00", "end": "17:00"};
      doctorBlockedDates = [];
      doctorStatus = "Available";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Appointment Booked Successfully"),
        backgroundColor: Color(0xFF00D9A3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF063C3D),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00D9A3)),
        ),
      );
    }

    bool canBook =
        selectedService != null &&
        selectedDoctor != null &&
        selectedDate != null &&
        selectedTime != null &&
        isDoctorAvailableOnDate(selectedDate!) &&
        isDoctorAvailableAtTime(selectedTime!);

    return Scaffold(
      backgroundColor: const Color(0xFF063C3D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF063C3D),
        elevation: 0,
        title: const Text(
          "Book Appointment",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _dropdown("Service", services, selectedService, (val) {
              if (val != null) filterDoctors(val);
            }),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: const Color(0xFF00D9A3).withOpacity(0.3),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedDoctor,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF0A3F),
                  hint: const Text(
                    "Select Doctor",
                    style: TextStyle(color: Colors.white70),
                  ),
                  items: filteredDoctors.map((doctor) {
                    return DropdownMenuItem<String>(
                      value: doctor["name"],
                      child: Text(
                        doctor["name"],
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectDoctor(value);
                    }
                  },
                ),
              ),
            ),
            
            if (selectedDoctor != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D9A3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00D9A3).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Doctor Schedule",
                      style: TextStyle(
                        color: Color(0xFF00D9A3),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Color(0xFF00D9A3), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            doctorWorkingDays.isNotEmpty
                                ? doctorWorkingDays.map((d) => d.substring(0, 3)).join(", ")
                                : "Everyday",
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: Color(0xFF00D9A3), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${doctorTimeSlots['start']} - ${doctorTimeSlots['end']}",
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _actionBox(
                    "Date",
                    selectedDate == null
                        ? "-"
                        : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                    Icons.calendar_month,
                    pickDate,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _actionBox(
                    "Time",
                    selectedTime == null ? "-" : selectedTime!.format(context),
                    Icons.access_time,
                    pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _glassCard(),
            const SizedBox(height: 20),
            _buildConfirmButton(canBook),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton(bool canBook) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: canBook
            ? const LinearGradient(
                colors: [Color(0xFF00D9A3), Color(0xFF00B894)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: canBook ? null : Colors.white10,
        boxShadow: canBook
            ? [
                BoxShadow(
                  color: const Color(0xFF00D9A3).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: canBook ? bookAppointment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: canBook ? Colors.white : Colors.white38,
            ),
            const SizedBox(width: 10),
            Text(
              "Confirm Booking",
              style: TextStyle(
                color: canBook ? Colors.white : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00D9A3).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Appointment Summary",
            style: TextStyle(
              color: Color(0xFF00D9A3),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.teal,
                backgroundImage: doctorImage.isNotEmpty
                    ? NetworkImage(doctorImage)
                    : null,
                child: doctorImage.isEmpty
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  selectedDoctor ?? "-",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _row(Icons.medical_services, "Service", selectedService ?? "-"),
          _row(
            Icons.attach_money,
            "Fee",
            serviceFee.isEmpty ? "-" : "Rs $serviceFee", // 👈 Service price පෙන්නනවා
          ),
          _row(
            Icons.calendar_month,
            "Date",
            selectedDate == null
                ? "-"
                : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
          ),
          _row(
            Icons.access_time,
            "Time",
            selectedTime == null ? "-" : selectedTime!.format(context),
          ),

          if (doctorWorkingDays.isNotEmpty)
            _row(
              Icons.calendar_today,
              "Schedule",
              doctorWorkingDays.map((d) => d.substring(0, 3)).join(", "),
            ),

          const SizedBox(height: 10),

          const Divider(color: Colors.white24),

          _row(Icons.person, "Patient", patientName ?? "-"),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00D9A3).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00D9A3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.confirmation_number,
                    color: Color(0xFF00D9A3)),
                const SizedBox(width: 10),
                Text(
                  "Queue: ${queuePreview.isEmpty ? "-" : queuePreview}",
                  style: const TextStyle(
                    color: Color(0xFF00D9A3),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          if (selectedDate != null && selectedDoctor != null)
            Text(
              isDoctorAvailableOnDate(selectedDate!)
                  ? "✓ Doctor Available"
                  : "✗ Doctor Not Available",
              style: TextStyle(
                color: isDoctorAvailableOnDate(selectedDate!)
                    ? Colors.greenAccent
                    : Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String a, String b) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00D9A3), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(a, style: const TextStyle(color: Colors.white70)),
          ),
          Text(b, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _dropdown(
    String label,
    List<String> items,
    String? value,
    Function(String?) onChanged,
  ) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning, color: Colors.redAccent, size: 18),
            const SizedBox(width: 8),
            Text(
              "No $label available",
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF00D9A3).withOpacity(0.3)),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        dropdownColor: const Color(0xFF0A3F3F),
        hint: Text(label, style: const TextStyle(color: Colors.white70)),
        underline: const SizedBox(),
        style: const TextStyle(color: Colors.white),
        items: items
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: const TextStyle(color: Colors.white)),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _actionBox(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF00D9A3).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF00D9A3), size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}