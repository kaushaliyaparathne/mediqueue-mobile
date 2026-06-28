import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> registerUser({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String dob,
    required String gender,
    required String address,
  }) async {
    try {
      // 🔐 Create Firebase Auth user
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user == null) {
        throw Exception("User creation failed");
      }

      // 🔥 Save user data in Firestore
      await _firestore.collection("users").doc(user.uid).set({
        "uid": user.uid,
        "fullName": fullName,
        "email": email,
        "phone": phone,
        "dob": dob, // ✅ FIXED
        "gender": gender, // ✅ FIXED
        "address": address, // ✅ FIXED

        // 🚨 system fields
        "role": "patient",
        "blocked": false,

        "createdAt": FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception("Something went wrong: $e");
    }
  }
}