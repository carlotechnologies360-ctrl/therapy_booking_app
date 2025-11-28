import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ---------- CUSTOMER ----------

  Future<User?> signupCustomer({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {

    // Create account (Firebase Authentication)
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // No Firestore storage (You will store in SQLite locally)
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

  // ---------- MASSAGER LOGIN ----------

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
  // This will no longer send data to Firestore.
  // You will later save these details in SQLite.

  Future<void> submitApplication({
    required String name,
    required String phone,
    required String experience,
    required String location,
    String? notes,
  }) async {
    // No Firestore — will use SQLite later
    return;
  }
}
