import 'package:flutter/material.dart';
import '../local_database.dart';
import 'massager_details.dart';

class EnterCodePage extends StatefulWidget {
  const EnterCodePage({super.key});

  @override
  State<EnterCodePage> createState() => _EnterCodePageState();
}

class _EnterCodePageState extends State<EnterCodePage> {
  final _codeController = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);

    // search in SQLite
    final result = await LocalDatabase.findByEmail(
      'massagers',
      _codeController.text.trim(),
    );

    // wait—findByEmail uses email. We need findByCode instead.
    // So we will use custom query:
    final db = await LocalDatabase.database;
    final rows = await db.query(
      "massagers",
      where: "code = ?",
      whereArgs: [_codeController.text.trim()],
    );

    setState(() => _loading = false);

    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid code. Try again.")),
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
      appBar: AppBar(title: const Text("Enter Therapist Code")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: "Therapist Code",
                hintText: "Enter the code shared by your therapist",
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
