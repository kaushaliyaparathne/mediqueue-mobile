import 'package:flutter/material.dart';
import 'package:mediqueue/services/auth_service.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final addressController = TextEditingController(); // ✅ NEW

  final AuthService authService = AuthService();

  bool isHidden = true;
  bool isConfirmHidden = true;
  bool isLoading = false;

  DateTime? selectedDOB; // ✅ NEW
  String? selectedGender; // ✅ NEW

  final List<String> genders = ["Male", "Female", "Other"];

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    addressController.dispose();
    super.dispose();
  }

  /// DOB PICKER
  Future<void> pickDOB() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => selectedDOB = picked);
    }
  }

  Future<void> register() async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String phone = phoneController.text.trim();
    String password = passwordController.text.trim();
    String confirm = confirmPasswordController.text.trim();
    String address = addressController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirm.isEmpty ||
        address.isEmpty ||
        selectedDOB == null ||
        selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await authService.registerUser(
        fullName: name,
        email: email,
        phone: phone,
        password: password,
        dob: selectedDOB.toString(),
        gender: selectedGender!,
        address: address,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration Successful")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration failed: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  Widget buildField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool obscure = false,
    Widget? suffix,
  }) {
    return SizedBox(
      height: 45,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white70, fontSize: 13),
          prefixIcon: Icon(icon, color: Colors.white, size: 20),
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.white24,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
            const SizedBox(height: 80),

            /// LOGO
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.teal, Colors.white],
                  
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  "assets/logo.jpg",
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "MediQueue",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const Text(
              "Smart Queue. Better Care.",
              style: TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 25),
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
                    children: [
                      const SizedBox(height: 20),

                      const Text(
                        "Create Account",
                        style: TextStyle(color: Colors.white70),
                      ),

                      const SizedBox(height: 15),

                      buildField(
                        hint: "Full Name",
                        icon: Icons.person,
                        controller: nameController,
                      ),

                      const SizedBox(height: 15),

                      buildField(
                        hint: "Email",
                        icon: Icons.email,
                        controller: emailController,
                      ),

                      const SizedBox(height: 15),

                      buildField(
                        hint: "Phone Number",
                        icon: Icons.phone,
                        controller: phoneController,
                      ),

                      const SizedBox(height: 15),

                      /// DOB
                      Container(
                        height: 45,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cake, color: Colors.white),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                selectedDOB == null
                                    ? "Date of Birth"
                                    : "${selectedDOB!.year}-${selectedDOB!.month}-${selectedDOB!.day}",
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.calendar_today,
                                  color: Colors.white),
                              onPressed: pickDOB,
                            )
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      /// GENDER
                      Container(
                        height: 45,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: Colors.black,
                            value: selectedGender,
                            hint: const Text(
                              "Gender",
                              style: TextStyle(color: Colors.white70),
                            ),
                            items: genders
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(
                                      e,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => selectedGender = value);
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      buildField(
                        hint: "Address",
                        icon: Icons.home,
                        controller: addressController,
                      ),

                      const SizedBox(height: 15),

                      buildField(
                        hint: "Password",
                        icon: Icons.lock,
                        controller: passwordController,
                        obscure: isHidden,
                        suffix: IconButton(
                          icon: Icon(
                            isHidden
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white,
                          ),
                          onPressed: () =>
                              setState(() => isHidden = !isHidden),
                        ),
                      ),

                      const SizedBox(height: 15),

                      buildField(
                        hint: "Confirm Password",
                        icon: Icons.lock_outline,
                        controller: confirmPasswordController,
                        obscure: isConfirmHidden,
                        suffix: IconButton(
                          icon: Icon(
                            isConfirmHidden
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white,
                          ),
                          onPressed: () => setState(
                              () => isConfirmHidden = !isConfirmHidden),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.tealAccent,
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.black,
                                )
                              : const Text("REGISTER"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}