import 'package:flutter/material.dart';
import '../local_database.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  List<Map<String, dynamic>> _massagers = [];

  @override
  void initState() {
    super.initState();
    _loadMassagers();
  }

  Future<void> _loadMassagers() async {
    final data = await LocalDatabase.getAll("massagers");
    setState(() {
      _massagers = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Available Massagers")),
      body: _massagers.isEmpty
          ? const Center(
              child: Text(
                "No massagers available.",
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: _massagers.length,
              itemBuilder: (context, index) {
                final m = _massagers[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(m['name']),
                    subtitle: Text(
                        "Experience: ${m['experience']}\nLocation: ${m['location']}"),
                    isThreeLine: true,
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // TODO: Navigate to massager detail page later
                    },
                  ),
                );
              },
            ),
    );
  }
}
