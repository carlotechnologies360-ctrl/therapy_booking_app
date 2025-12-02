import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_service.dart';
import '../local_database.dart';
import '../apply_page.dart';
import 'massager_signup.dart';
import 'massager_home_page.dart';
import 'provider_setup_page.dart';
import 'notifications_page.dart';

class MassagerLoginPage extends StatefulWidget {
  const MassagerLoginPage({super.key});

  @override
  State<MassagerLoginPage> createState() => _MassagerLoginPageState();
}

class _MassagerLoginPageState extends State<MassagerLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = FirebaseService();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _rememberMe = false;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _checkNotifications() async {
    if (_emailCtrl.text.isNotEmpty) {
      final count = await LocalDatabase.getUnreadNotificationCount(
          _emailCtrl.text.trim());
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    }
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('massager_email');
    final savedPassword = prefs.getString('massager_password');
    final rememberMe = prefs.getBool('massager_remember_me') ?? false;

    if (rememberMe && savedEmail != null && savedPassword != null) {
      setState(() {
        _emailCtrl.text = savedEmail;
        _passwordCtrl.text = savedPassword;
        _rememberMe = true;
      });
      // Check for notifications after loading credentials
      await _checkNotifications();
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('massager_email', _emailCtrl.text.trim());
      await prefs.setString('massager_password', _passwordCtrl.text.trim());
      await prefs.setBool('massager_remember_me', true);
    } else {
      await prefs.remove('massager_email');
      await prefs.remove('massager_password');
      await prefs.setBool('massager_remember_me', false);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await _service.loginMassager(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      final providerEmail = _emailCtrl.text.trim();

      // First check Firestore for application status
      final firestoreApp = await _service.getApplicationByEmail(providerEmail);
      
      // Get provider details from local database
      final providerData = await LocalDatabase.findByEmail(
        'massagers',
        providerEmail,
      );

      if (providerData == null) {
        throw Exception('Provider account not found');
      }

      final providerName = providerData['name'] as String? ?? 'Service Provider';
      String? providerCode = providerData['code'] as String?;
      final setupComplete = (providerData['setupComplete'] as int?) == 1;

      // If application is approved in Firestore but local DB doesn't have code, sync it
      if (firestoreApp != null && 
          firestoreApp['status'] == 'approved' && 
          firestoreApp['therapistCode'] != null) {
        providerCode = firestoreApp['therapistCode'] as String;
        
        // Update local database with the code from Firestore
        await LocalDatabase.updateMassagerCode(
          email: providerEmail,
          code: providerCode,
        );
      }

      await _saveCredentials();

      if (!mounted) return;

      // Check provider status and redirect accordingly
      if (providerCode == null || providerCode.isEmpty) {
        // Check if application is pending or rejected
        if (firestoreApp != null) {
          if (firestoreApp['status'] == 'pending') {
            // Application pending approval
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Your application is pending admin approval'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          } else if (firestoreApp['status'] == 'rejected') {
            // Application rejected
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Your application was rejected. Please contact admin.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
        // No code yet - redirect to apply page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ApplyPage(
              providerEmail: providerEmail,
              providerName: providerName,
            ),
          ),
        );
      } else if (!setupComplete) {
        // Has code but setup not complete - redirect to setup page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderSetupPage(
              providerEmail: providerEmail,
              providerName: providerName,
            ),
          ),
        );
      } else {
        // Has code and setup complete - go to dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MassagerHomePage(
              therapistCode: providerCode!,
              therapistName: providerName,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple.shade400, Colors.purple.shade800],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.spa_outlined,
                          size: 80,
                          color: Colors.purple.shade600,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Service Provider Login',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Welcome back!',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (_unreadNotificationCount > 0) ...[
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NotificationsPage(
                                      userEmail: _emailCtrl.text.trim()),
                                ),
                              ).then((_) => _checkNotifications());
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.purple.shade300, width: 2),
                              ),
                              child: Row(
                                children: [
                                  Badge(
                                    label: Text('$_unreadNotificationCount'),
                                    child: Icon(
                                      Icons.notifications_active,
                                      color: Colors.purple.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'You have $_unreadNotificationCount new notification${_unreadNotificationCount > 1 ? 's' : ''}',
                                      style: TextStyle(
                                        color: Colors.purple.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.purple.shade700,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _emailCtrl,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.purple.shade600, width: 2),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              v != null && v.contains('@') ? null : 'Enter valid email',
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordCtrl,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.purple.shade600, width: 2),
                            ),
                          ),
                          obscureText: true,
                          validator: (v) =>
                              v != null && v.length >= 6 ? null : 'Min 6 characters',
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                              activeColor: Colors.purple.shade600,
                            ),
                            const Text('Remember Me'),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: _loading
                              ? Center(child: CircularProgressIndicator(
                                  color: Colors.purple.shade600,
                                ))
                              : ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple.shade600,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MassagerSignupPage(),
                              ),
                            );
                          },
                          child: Text(
                            "Don't have an account? Sign up",
                            style: TextStyle(
                              color: Colors.purple.shade700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
