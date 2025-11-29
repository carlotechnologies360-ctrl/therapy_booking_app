import 'package:flutter/material.dart';
import '../local_database.dart';

class MassagerDetailPage extends StatefulWidget {
  final Map<String, dynamic> massager;

  const MassagerDetailPage({super.key, required this.massager});

  @override
  State<MassagerDetailPage> createState() => _MassagerDetailPageState();
}

class _MassagerDetailPageState extends State<MassagerDetailPage> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _loading = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await LocalDatabase.insert('bookings', {
        'customer_id': 1, // Hardcoded for now, replace with real ID
        'massager_id': widget.massager['id'],
        'massager_name': widget.massager['name'],
        'date': "${_selectedDate!.toLocal()}".split(' ')[0],
        'time': _selectedTime!.format(context),
        'status': 'Pending',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment Booked Successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.massager;
    return Scaffold(
      appBar: AppBar(title: Text(m['name'])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                child: Text(
                  m['name'][0].toUpperCase(),
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text("About", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Experience: ${m['experience'] ?? 'N/A'}"),
            Text("Location: ${m['location'] ?? 'N/A'}"),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text("Book Appointment", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_selectedDate == null
                        ? 'Select Date'
                        : "${_selectedDate!.toLocal()}".split(' ')[0]),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectTime(context),
                    icon: const Icon(Icons.access_time),
                    label: Text(_selectedTime == null
                        ? 'Select Time'
                        : _selectedTime!.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _bookAppointment,
                      child: const Text('Confirm Booking'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
