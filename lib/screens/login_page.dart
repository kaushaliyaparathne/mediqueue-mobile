import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:mediqueue/screens/layout.dart';
import 'package:mediqueue/screens/register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isHidden = true;
  bool isLoading = false;

  /// ================= SHOW MESSAGE =================

  void showMsg(String msg, {bool error = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  /// ================= LOGIN FUNCTION =================

  Future<void> login() async {
    /// EMPTY CHECK
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      showMsg("Please fill all fields");
      return;
    }

    setState(() => isLoading = true);

    try {
      /// 🔐 FIREBASE AUTH LOGIN
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;

      if (user == null) {
        showMsg("Login failed");

        setState(() => isLoading = false);
        return;
      }

      /// 🔥 FIRESTORE USER CHECK
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      /// ❌ USER NOT FOUND
      if (!doc.exists) {
        await FirebaseAuth.instance.signOut();

        showMsg("User data not found");

        setState(() => isLoading = false);
        return;
      }

      final data = doc.data() as Map<String, dynamic>;

      /// ✅ ROLE CHECK
      final String role = data["role"] ?? "patient";

      /// ✅ BLOCK CHECK
      final bool blocked =
          data["isBlocked"] == true ||
          data["blocked"] == true;

      /// 🚫 BLOCKED USER
      if (blocked) {
        await FirebaseAuth.instance.signOut();

        showMsg("Account blocked by admin");

        setState(() => isLoading = false);
        return;
      }

      /// 🚫 ONLY PATIENT LOGIN
      if (role != "patient") {
        await FirebaseAuth.instance.signOut();

        showMsg("Access denied. Patients only");

        setState(() => isLoading = false);
        return;
      }

      /// ✅ SUCCESS LOGIN
      showMsg("Login successful", error: false);

      Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => LayoutPage(
      patientId: user.uid, // ✅ FIX HERE
      startIndex: 0,
    ),
  ),
);
    } on FirebaseAuthException catch (e) {
      String msg = "Login failed";

      switch (e.code) {
        case "user-not-found":
          msg = "User not found";
          break;

        case "wrong-password":
          msg = "Wrong password";
          break;

        case "invalid-email":
          msg = "Invalid email";
          break;

        case "invalid-credential":
          msg = "Invalid email or password";
          break;

        case "too-many-requests":
          msg = "Too many login attempts";
          break;
      }

      showMsg(msg);
    } catch (e) {
      showMsg(e.toString());
    }

    setState(() => isLoading = false);
  }

  /// ================= TEXTFIELD =================

  Widget buildField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool obscure = false,
    Widget? suffix,
  }) {
    return SizedBox(
      height: 50,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.white24,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF063C3D),
              Color(0xFF0F9D9A),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: Column(
          children: [
            const SizedBox(height: 80),

            /// 🔵 LOGO
            Container(
              padding: const EdgeInsets.all(18),

              decoration: const BoxDecoration(
                shape: BoxShape.circle,

                gradient: LinearGradient(
                  colors: [
                    Colors.teal,
                    Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
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

            /// 🔵 TITLE
            const Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "Medi",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  TextSpan(
                    text: "Queue",
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                      color: Colors.tealAccent,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              "Smart Queue. Better Care.",
              style: TextStyle(
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 25),

            /// 🔵 LOGIN CARD
            Expanded(
              child: Container(
                width: double.infinity,

                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                ),

                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.teal,
                      Colors.black87,
                    ],
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
                      const SizedBox(height: 35),

                      const Text(
                        "Welcome Back!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      Container(
                        width: 100,
                        height: 2,
                        color: Colors.tealAccent,
                      ),

                      const SizedBox(height: 40),

                      /// EMAIL
                      buildField(
                        hint: "Email",
                        icon: Icons.email,
                        controller: emailController,
                      ),

                      const SizedBox(height: 25),

                      /// PASSWORD
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

                          onPressed: () {
                            setState(() {
                              isHidden = !isHidden;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 35),

                      /// LOGIN BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 48,

                        child: ElevatedButton(
                          onPressed:
                              isLoading ? null : login,

                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.tealAccent,

                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                          ),

                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.black,
                                )
                              : const Text(
                                  "LOGIN",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight:
                                        FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      /// REGISTER
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,

                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: Colors.white70,
                            ),
                          ),

                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,

                                MaterialPageRoute(
                                  builder: (_) =>
                                      const RegisterPage(),
                                ),
                              );
                            },

                            child: const Text(
                              "Register",
                              style: TextStyle(
                                color: Colors.tealAccent,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
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