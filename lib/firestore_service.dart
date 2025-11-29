import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  static final CollectionReference _applicationsCollection =
      _firestore.collection('applications');
  static final CollectionReference _codesCollection =
      _firestore.collection('codes');

  // Submit application (from apply page)
  static Future<String> submitApplication({
    required String name,
    required String email,
    required String phone,
    required String experience,
    required String location,
  }) async {
    try {
      final docRef = await _applicationsCollection.add({
        'name': name,
        'email': email,
        'phone': phone,
        'experience': experience,
        'location': location,
        'status': 'pending', // pending, approved, rejected
        'submittedAt': FieldValue.serverTimestamp(),
        'therapistCode': null, // Will be set when approved
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to submit application: $e');
    }
  }

  // Get all applications (for admin dashboard)
  static Stream<QuerySnapshot> getApplicationsStream() {
    return _applicationsCollection
        .orderBy('submittedAt', descending: true)
        .snapshots();
  }

  // Get pending applications only
  static Stream<QuerySnapshot> getPendingApplicationsStream() {
    return _applicationsCollection
        .where('status', isEqualTo: 'pending')
        .orderBy('submittedAt', descending: true)
        .snapshots();
  }

  // Get applications by status
  static Future<List<Map<String, dynamic>>> getApplicationsByStatus(
      String status) async {
    try {
      final snapshot = await _applicationsCollection
          .where('status', isEqualTo: status)
          .orderBy('submittedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get applications: $e');
    }
  }

  // Approve application and generate code
  static Future<String> approveApplication({
    required String applicationId,
    required String therapistCode,
  }) async {
    try {
      // Update application status
      await _applicationsCollection.doc(applicationId).update({
        'status': 'approved',
        'therapistCode': therapistCode,
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // Get application data
      final appDoc = await _applicationsCollection.doc(applicationId).get();
      final appData = appDoc.data() as Map<String, dynamic>;

      // Save code to codes collection
      await _codesCollection.doc(therapistCode).set({
        'code': therapistCode,
        'massagerEmail': appData['email'],
        'massagerName': appData['name'],
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      return therapistCode;
    } catch (e) {
      throw Exception('Failed to approve application: $e');
    }
  }

  // Reject application
  static Future<void> rejectApplication(String applicationId) async {
    try {
      await _applicationsCollection.doc(applicationId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to reject application: $e');
    }
  }

  // Generate unique therapist code
  static Future<String> generateUniqueCode() async {
    String code;
    bool isUnique = false;

    while (!isUnique) {
      // Generate random code like THERAPIST_ABC123
      final random = DateTime.now().millisecondsSinceEpoch.toString();
      final suffix = random.substring(random.length - 6);
      code = 'THERAPIST_$suffix';

      // Check if code already exists
      final existingCode = await _codesCollection.doc(code).get();
      if (!existingCode.exists) {
        isUnique = true;
        return code;
      }
    }

    throw Exception('Failed to generate unique code');
  }

  // Check if code exists and is valid
  static Future<bool> validateTherapistCode(String code) async {
    try {
      final doc = await _codesCollection.doc(code).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['isActive'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Get code details
  static Future<Map<String, dynamic>?> getCodeDetails(String code) async {
    try {
      final doc = await _codesCollection.doc(code).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['code'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get application by email
  static Future<Map<String, dynamic>?> getApplicationByEmail(
      String email) async {
    try {
      final snapshot = await _applicationsCollection
          .where('email', isEqualTo: email)
          .orderBy('submittedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
