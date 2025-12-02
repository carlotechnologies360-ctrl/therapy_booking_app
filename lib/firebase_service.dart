import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<User?> signupMassager({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
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

  // ---------- GET APPLICATION BY EMAIL ----------
  // Check Firestore for application status
  Future<Map<String, dynamic>?> getApplicationByEmail(String email) async {
    try {
      final firestore = FirebaseFirestore.instance;
      // First try without orderBy to avoid index issues
      final snapshot = await firestore
          .collection('applications')
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isEmpty) {
        print('No application found for email: $email');
        return null;
      }

      // Get the most recent one manually if multiple exist
      var mostRecent = snapshot.docs.first;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final mostRecentData = mostRecent.data();
        
        if (data['submittedAt'] != null && mostRecentData['submittedAt'] != null) {
          final currentTimestamp = data['submittedAt'] as Timestamp;
          final mostRecentTimestamp = mostRecentData['submittedAt'] as Timestamp;
          
          if (currentTimestamp.compareTo(mostRecentTimestamp) > 0) {
            mostRecent = doc;
          }
        }
      }

      final data = mostRecent.data();
      data['id'] = mostRecent.id;
      print('Application found: status=${data['status']}, code=${data['therapistCode']}');
      return data;
    } catch (e) {
      print('Error fetching application: $e');
      return null;
    }
  }
}
