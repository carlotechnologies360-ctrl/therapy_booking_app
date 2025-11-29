import 'package:flutter/material.dart';
import '../../local_database.dart';

class CustomerBookingsTab extends StatefulWidget {
  const CustomerBookingsTab({super.key});

  @override
  State<CustomerBookingsTab> createState() => _CustomerBookingsTabState();
}

class _CustomerBookingsTabState extends State<CustomerBookingsTab> {
  List<Map<String, dynamic>> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    // In a real app, filter by current customer ID
    final data = await LocalDatabase.getAll("bookings");
    if (mounted) {
      setState(() {
        _bookings = List.from(data.reversed); // Show newest first
        _loading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_bookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No bookings yet.",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bookings.length,
      itemBuilder: (context, index) {
        final b = _bookings[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.teal.shade50,
              child: const Icon(Icons.spa, color: Colors.teal),
            ),
            title: Text(
              b['massager_name'] ?? 'Unknown Massager',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("${b['date']} at ${b['time']}"),
            trailing: Chip(
              label: Text(
                b['status'] ?? 'Pending',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: _getStatusColor(b['status'] ?? 'pending'),
              padding: EdgeInsets.zero,
            ),
          ),
        );
      },
    );
  }
}
