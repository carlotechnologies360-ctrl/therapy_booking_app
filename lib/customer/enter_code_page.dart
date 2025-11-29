import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../local_database.dart';
import 'massager_details.dart';
import 'customer_home_page.dart';
import '../providers/session_provider.dart';

class EnterCodePage extends StatefulWidget {
  const EnterCodePage({super.key});

  @override
  State<EnterCodePage> createState() => _EnterCodePageState();
}

class _EnterCodePageState extends State<EnterCodePage> {
  final _codeController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);

    final enteredCode = _codeController.text.trim();

    // DUMMY CODE FOR TESTING - Replace with real logic later
    // Dummy therapist codes for quick access to customer dashboard
    const dummyCodes = ['THERAPIST123', 'TEST123', 'DEMO2024'];

    if (dummyCodes.contains(enteredCode.toUpperCase())) {
      setState(() => _loading = false);
      
      // Store therapist code in session
      if (!mounted) return;
      Provider.of<SessionProvider>(context, listen: false)
          .setTherapistCode(enteredCode.toUpperCase());
      
      // Navigate to customer home page (dashboard) with therapist code
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerHomePage(
            therapistCode: enteredCode.toUpperCase(),
          ),
        ),
      );
      return;
    }

    // Try to search in SQLite database (for real therapist codes)
    final db = await LocalDatabase.database;
    final rows = await db.query(
      "massagers",
      where: "code = ?",
      whereArgs: [enteredCode],
    );

    setState(() => _loading = false);

    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid code. Try again.\nHint: Try THERAPIST123 for demo")),
      );
      return;
    }

    final massager = rows.first;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MassagerDetailsPage(
          massager: massager,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Enter Therapist Code"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.characters,
              enableInteractiveSelection: true,
              decoration: const InputDecoration(
                labelText: "Therapist Code",
                hintText: "Enter the code shared by your therapist",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submit,
                    child: const Text("Continue"),
                  ),
          ],
        ),
      ),
    );
  }
}
