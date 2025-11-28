import 'package:flutter/material.dart';

class MassagerDetailsPage extends StatelessWidget {
  final Map<String, dynamic> massager;

  const MassagerDetailsPage({super.key, required this.massager});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(massager['name'])),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: ${massager['name']}", style: const TextStyle(fontSize: 18)),
            Text("Experience: ${massager['experience']}"),
            Text("Location: ${massager['location']}"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: const Text("Book Appointment (coming soon)"),
            ),
          ],
        ),
      ),
    );
  }
}
