import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------- CUSTOMER ----------

  Future<User?> signupCustomer({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _db.collection('customers').doc(cred.user!.uid).set({
      'name': name,
      'phone': phone,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return cred.user;
  }

  Future<User?> loginCustomer({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  // ---------- MASSAGER ----------

 Future<User?> loginMassager({
  required String email,
  required String password,
}) async {
  final cred = await _auth.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
  return cred.user;
}


  // ---------- APPLY FORM ----------

  Future<void> submitApplication({
    required String name,
    required String phone,
    required String experience,
    required String location,
    String? notes,
  }) async {
    await _db.collection('applications').add({
      'name': name,
      'phone': phone,
      'experience': experience,
      'location': location,
      'notes': notes ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
