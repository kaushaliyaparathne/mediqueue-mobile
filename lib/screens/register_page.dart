import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mediqueue/services/auth_service.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final addressController = TextEditingController();

  final AuthService authService = AuthService();

  bool isHidden = true;
  bool isConfirmHidden = true;
  bool isLoading = false;
  bool autoValidate = false;

  DateTime? selectedDOB;
  String? selectedGender;

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
    final now = DateTime.now();
    final thirteenYearsAgo = DateTime(now.year - 13, now.month, now.day);
    
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: thirteenYearsAgo,
      firstDate: DateTime(1950),
      lastDate: thirteenYearsAgo, // Must be at least 13 years old
      helpText: 'Select Date of Birth',
    );

    if (picked != null) {
      setState(() => selectedDOB = picked);
    }
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final phone = value.trim();
    if (phone.length != 10) {
      return 'Phone must be exactly 10 digits';
    }
    if (!phone.startsWith('07')) {
      return 'Phone must start with 07';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
      return 'Password must contain a letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain a number';
    }
    return null;
  }

  Future<void> register() async {
    setState(() => autoValidate = true);

    final isValid = _formKey.currentState?.validate() ?? false;
    
    if (selectedDOB == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select your date of birth")),
      );
      return;
    }
    
    if (selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select your gender")),
      );
      return;
    }

    if (!isValid) return;

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await authService.registerUser(
        fullName: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        password: passwordController.text.trim(),
        dob: selectedDOB!.toIso8601String(),
        gender: selectedGender!,
        address: addressController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration Successful")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration failed: ${e.toString()}")),
      );
    }

    if (mounted) setState(() => isLoading = false);
  }

  Widget buildField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      autovalidateMode:
          autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white70, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white24,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
        errorMaxLines: 2,
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
                  child: Form(
                    key: _formKey,
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
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Full name is required'
                              : null,
                        ),
                        const SizedBox(height: 15),
                        buildField(
                          hint: "Email",
                          icon: Icons.email,
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: validateEmail,
                        ),
                        const SizedBox(height: 15),
                        buildField(
                          hint: "Phone Number (07XXXXXXXX)",
                          icon: Icons.phone,
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          validator: validatePhone,
                        ),
                        const SizedBox(height: 15),
                        /// DOB
                        GestureDetector(
                          onTap: pickDOB,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(12),
                              border: autoValidate && selectedDOB == null
                                  ? Border.all(color: Colors.redAccent)
                                  : null,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.cake,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    selectedDOB == null
                                        ? "Date of Birth"
                                        : "${selectedDOB!.day.toString().padLeft(2, '0')}/${selectedDOB!.month.toString().padLeft(2, '0')}/${selectedDOB!.year}",
                                    style: TextStyle(
                                      color: selectedDOB == null
                                          ? Colors.white70
                                          : Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.calendar_today,
                                    color: Colors.white, size: 20),
                              ],
                            ),
                          ),
                        ),
                        if (autoValidate && selectedDOB == null)
                          const Padding(
                            padding: EdgeInsets.only(top: 6, left: 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Date of birth is required',
                                style: TextStyle(
                                    color: Colors.redAccent, fontSize: 12),
                              ),
                            ),
                          ),
                        const SizedBox(height: 15),
                        /// GENDER
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                            border: autoValidate && selectedGender == null
                                ? Border.all(color: Colors.redAccent)
                                : null,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              dropdownColor: const Color(0xFF063C3D),
                              icon: const Icon(Icons.arrow_drop_down,
                                  color: Colors.white),
                              value: selectedGender,
                              hint: const Row(
                                children: [
                                  Icon(Icons.wc, color: Colors.white, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    "Gender",
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                  ),
                                ],
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
                        if (autoValidate && selectedGender == null)
                          const Padding(
                            padding: EdgeInsets.only(top: 6, left: 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Gender is required',
                                style: TextStyle(
                                    color: Colors.redAccent, fontSize: 12),
                              ),
                            ),
                          ),
                        const SizedBox(height: 15),
                        buildField(
                          hint: "Address",
                          icon: Icons.home,
                          controller: addressController,
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'Address is required'
                              : null,
                        ),
                        const SizedBox(height: 15),
                        buildField(
                          hint: "Password",
                          icon: Icons.lock,
                          controller: passwordController,
                          obscure: isHidden,
                          validator: validatePassword,
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
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (val != passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
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
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "REGISTER",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Already have an account? ",
                              style: TextStyle(color: Colors.white70),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                  color: Colors.tealAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
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