import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:mediqueue/screens/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  // Cloudinary details
  final String cloudName = "dlquqtk9k";
  final String uploadPreset = "mediqueue_profile"; // Must be UNSIGNED

  bool isLoading = true;
  bool isUploading = false;

  String fullName = "";
  String email = "";
  String phone = "";
  String createdAt = "";
  String profileImageUrl = "";

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> getUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      DocumentSnapshot snapshot =
          await _firestore.collection("users").doc(user.uid).get();

      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        Timestamp? timestamp = data["createdAt"];
        String formattedDate = "";

        if (timestamp!= null) {
          DateTime date = timestamp.toDate();
          formattedDate = "${date.day}/${date.month}/${date.year}";
        }

        if (!mounted) return;
        setState(() {
          fullName = data["fullName"]?? "";
          email = data["email"]?? "";
          phone = data["phone"]?? "";
          profileImageUrl = data["profileImage"]?? "";
          createdAt = formattedDate;
          isLoading = false;
        });
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showSnackBar("Error loading profile: $e");
    }
  }

  Future<void> pickAndUploadImage() async {
  try {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1080,
    );

    if (image == null) return;
    if (!mounted) return;

    setState(() => isUploading = true);

    final file = File(image.path);
    final bytes = await file.length();
    const int maxSizeInBytes = 10 * 1024 * 1024; // 10MB

    if (bytes > maxSizeInBytes) {
      final sizeInMB = (bytes / (1024 * 1024)).toStringAsFixed(2);
      throw Exception('Image size ${sizeInMB}MB. Max 10MB allowed.');
    }

    final url = Uri.parse("https://api.cloudinary.com/v1_1/dlquqtk9k/image/upload");

    final request = http.MultipartRequest('POST', url);
    request.fields['upload_preset'] = uploadPreset;
    // request.fields['folder'] = 'mediqueue_profiles'; // Meka ain kala
    request.files.add(await http.MultipartFile.fromPath('file', image.path));

    debugPrint('Uploading to: $url');
    debugPrint('Using preset: $uploadPreset');
    debugPrint('File size: ${(bytes / 1024 / 1024).toStringAsFixed(2)} MB');

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 60),
      onTimeout: () => throw Exception('Upload timeout'),
    );

    final response = await http.Response.fromStream(streamedResponse);

    debugPrint('Status Code: ${response.statusCode}');
    debugPrint('Response: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final String downloadUrl = data['secure_url'];

      User? user = _auth.currentUser;
      if (user!= null) {
        await _firestore.collection("users").doc(user.uid).update({
          'profileImage': downloadUrl,
        });
      }

      if (!mounted) return;
      setState(() {
        profileImageUrl = downloadUrl;
        isUploading = false;
      });

      await CachedNetworkImage.evictFromCache(downloadUrl);
      _showSnackBar("Profile picture updated!");
    } else {
      final data = json.decode(response.body);
      debugPrint('Full Cloudinary Error: $data');
      String errorMsg = data['error']?['message'] ?? 'Upload failed';
      throw Exception(errorMsg);
    }
  } catch (e) {
    if (!mounted) return;
    setState(() => isUploading = false);
    _showSnackBar("Upload failed: ${e.toString().replaceAll('Exception: ', '')}");
    debugPrint("Full error: $e");
  }
}

  Future<void> logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.teal,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF063C3D), Color(0xFF0F9D9A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading
          ? const Center(
                child: CircularProgressIndicator(color: Colors.tealAccent))
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Colors.tealAccent, Colors.teal],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.tealAccent.withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 55,
                              backgroundColor: Colors.white,
                              child: ClipOval(
                                child: isUploading
                                  ? const SizedBox(
                                        width: 110,
                                        height: 110,
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    : profileImageUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                            imageUrl: profileImageUrl,
                                            key: ValueKey(profileImageUrl),
                                            width: 110,
                                            height: 110,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Container(
                                              width: 110,
                                              height: 110,
                                              color: Colors.grey[300],
                                              child: const Center(
                                                child: CircularProgressIndicator(),
                                              ),
                                            ),
                                            errorWidget: (context, url, error) =>
                                                _buildInitialAvatar(),
                                          )
                                        : _buildInitialAvatar(),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: isUploading? null : pickAndUploadImage,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: isUploading? 0.5 : 1.0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.teal,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Icon(
                                  isUploading? Icons.hourglass_empty : Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        "My Profile",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        "Manage your account details",
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 30),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.12),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.tealAccent.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildLabel("Full Name"),
                            buildValue(fullName),
                            const SizedBox(height: 15),
                            buildLabel("Email"),
                            buildValue(email),
                            const SizedBox(height: 15),
                            buildLabel("Phone"),
                            buildValue(phone),
                            const SizedBox(height: 15),
                            buildLabel("Registered Date"),
                            buildValue(createdAt),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: isUploading? null : logout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            disabledBackgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 10,
                          ),
                          child: const Text(
                            "Logout",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildInitialAvatar() {
    return Container(
      width: 110,
      height: 110,
      color: Colors.teal.withOpacity(0.2),
      child: Center(
        child: Text(
          fullName.isNotEmpty? fullName[0].toUpperCase() : "U",
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
      ),
    );
  }

  Widget buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget buildValue(String text) {
    return Text(
      text.isEmpty? "-" : text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}