import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SessionProvider extends ChangeNotifier {
  String _therapistCode = '';
  String _customerEmail = '';
  String _customerName = '';

  String get therapistCode => _therapistCode;
  String get customerEmail => _customerEmail;
  String get customerName => _customerName;

  void setTherapistCode(String code) {
    _therapistCode = code;
    notifyListeners();
  }

  void setCustomerInfo(String email, String name) {
    _customerEmail = email;
    _customerName = name;
    notifyListeners();
  }

  void clear() {
    _therapistCode = '';
    _customerEmail = '';
    _customerName = '';
    notifyListeners();
  }

  // Get current user email from Firebase
  String getCurrentUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email ?? _customerEmail;
  }

  // Get current user display name from Firebase
  String getCurrentUserName() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.displayName ?? user?.email?.split('@')[0] ?? _customerName;
  }
}
