import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../firebase_service.dart';
import '../local_database.dart';
import 'customer_signup.dart';
import 'package:therapy_booking_app/customer/enter_code_page.dart';
import 'package:therapy_booking_app/customer/customer_home_page.dart';
import '../providers/session_provider.dart';

class CustomerLoginPage extends StatefulWidget {
  const CustomerLoginPage({super.key});

  @override
  State<CustomerLoginPage> createState() => _CustomerLoginPageState();
}

class _CustomerLoginPageState extends State<CustomerLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = FirebaseService();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('customer_email');
    final rememberMe = prefs.getBool('customer_remember_me') ?? false;

    if (rememberMe && savedEmail != null) {
      setState(() {
        _emailCtrl.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('customer_email', _emailCtrl.text.trim());
      await prefs.setBool('customer_remember_me', true);
    } else {
      await prefs.remove('customer_email');
      await prefs.setBool('customer_remember_me', false);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await _service.loginCustomer(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      await _saveCredentials();
      if (!mounted) return;
      
      // Check if customer has a saved therapist code from previous login
      final prefs = await SharedPreferences.getInstance();
      final savedTherapistCode = prefs.getString('customer_therapist_code');
      
      if (savedTherapistCode != null && savedTherapistCode.isNotEmpty) {
        // Verify the therapist code is still valid
        try {
          final therapistData = await LocalDatabase.findByCode(
            'massagers',
            savedTherapistCode,
          );
          
          if (therapistData != null && (therapistData['setupComplete'] as int?) == 1) {
            // Valid service provider code found - go directly to customer home page
            final therapistName = therapistData['name'] as String? ?? 'Service Provider';
            final therapistEmail = therapistData['email'] as String? ?? '';
            final therapistPhone = therapistData['phone'] as String? ?? '';
            final therapistExperience = therapistData['experience'] as String? ?? '';
            final therapistLocation = therapistData['location'] as String? ?? '';
            
            // Record customer visit
            final customerEmail = _emailCtrl.text.trim();
            final customerData = await LocalDatabase.findByEmail('customers', customerEmail);
            final customerName = customerData?['name'] as String? ?? 'Customer';
            
            await LocalDatabase.recordCustomerVisit(
              therapistCode: savedTherapistCode,
              customerEmail: customerEmail,
              customerName: customerName,
            );
            
            // Store therapist code in session
            if (!mounted) return;
            Provider.of<SessionProvider>(context, listen: false)
                .setTherapistCode(savedTherapistCode);
            
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => CustomerHomePage(
                  therapistCode: savedTherapistCode,
                  therapistName: therapistName,
                  therapistBio: '$therapistExperience years of experience in therapeutic massage',
                  therapistContact: '$therapistEmail | $therapistPhone | $therapistLocation',
                ),
              ),
            );
            return;
          }
        } catch (e) {
          // If verification fails, clear the saved code and continue to code entry
          await prefs.remove('customer_therapist_code');
        }
      }
      
      // No saved code or invalid code - go to code entry page
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => EnterCodePage()),
      );
    } catch (e) {
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
            colors: [Colors.teal.shade400, Colors.teal.shade800],
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
                          Icons.person_outline,
                          size: 80,
                          color: Colors.teal.shade600,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Customer Login',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade800,
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
                              borderSide: BorderSide(color: Colors.teal.shade600, width: 2),
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
                              borderSide: BorderSide(color: Colors.teal.shade600, width: 2),
                            ),
                          ),
                          obscureText: true,
                          validator: (v) =>
                              v != null && v.length >= 6 ? null : 'Min 6 chars',
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
                              activeColor: Colors.teal.shade600,
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
                                  color: Colors.teal.shade600,
                                ))
                              : ElevatedButton(
                                  onPressed: _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal.shade600,
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
                                builder: (_) => const CustomerSignupPage(),
                              ),
                            );
                          },
                          child: Text(
                            "Don't have an account? Sign up",
                            style: TextStyle(
                              color: Colors.teal.shade700,
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
