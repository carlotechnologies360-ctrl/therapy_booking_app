import 'package:flutter/material.dart';
import 'package:therapy_booking_app/local_database.dart';
import 'firebase_service.dart'; // KEEP this ONLY if needed for anything later

class ApplyPage extends StatefulWidget {
  const ApplyPage({super.key});

  @override
  State<ApplyPage> createState() => _ApplyPageState();
}

class _ApplyPageState extends State<ApplyPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = FirebaseService(); // Not used for Firestore anymore

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // 1️⃣ SAVE APPLICATION TO LOCAL SQLITE DATABASE
      await LocalDatabase.insert("applications", {
        "name": _nameCtrl.text.trim(),
        "phone": _phoneCtrl.text.trim(),
        "experience": _experienceCtrl.text.trim(),
        "location": _locationCtrl.text.trim(),
        "notes": _notesCtrl.text.trim(),
      });

      // 2️⃣ Show success
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Application submitted successfully")),
      );

      // 3️⃣ Clear the form
      _formKey.currentState!.reset();
      _nameCtrl.clear();
      _phoneCtrl.clear();
      _experienceCtrl.clear();
      _locationCtrl.clear();
      _notesCtrl.clear();

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _experienceCtrl,
                decoration: const InputDecoration(labelText: 'Experience (years)'),
              ),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Additional Notes'),
              ),
              const SizedBox(height: 24),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Submit'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
