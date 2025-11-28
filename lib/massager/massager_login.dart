import 'package:flutter/material.dart';
import 'package:therapy_booking_app/local_database.dart';


class MassagerLoginPage extends StatefulWidget {
  const MassagerLoginPage({super.key});

  @override
  State<MassagerLoginPage> createState() => _MassagerLoginPageState();
}

class _MassagerLoginPageState extends State<MassagerLoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // 🔍 1. Find massager by email in SQLite DB
      final massager = await LocalDatabase.findByEmail(
        'massagers',
        _emailCtrl.text.trim(),
      );

      if (massager == null) {
        throw "No massager found with this email";
      }

      // 🔐 2. Check password
      if (massager['password'] != _passwordCtrl.text.trim()) {
        throw "Incorrect password";
      }

      // 🎉 3. Login success
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Massager logged in')),
      );

      // TODO: Navigate to massager dashboard here

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Massager Login')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) =>
                    v != null && v.contains('@') ? null : 'Enter valid email',
              ),
              TextFormField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) =>
                    v != null && v.length >= 6 ? null : 'Min 6 characters',
              ),
              const SizedBox(height: 24),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      child: const Text('Login'),
                    ),
              const SizedBox(height: 16),

              Text(
                "Don't have an account?\nPlease apply first. Admin will contact you.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
