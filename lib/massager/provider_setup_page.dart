import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../local_database.dart';
import 'massager_home_page.dart';

class ProviderSetupPage extends StatefulWidget {
  final String providerEmail;
  final String providerName;

  const ProviderSetupPage({
    super.key,
    required this.providerEmail,
    required this.providerName,
  });

  @override
  State<ProviderSetupPage> createState() => _ProviderSetupPageState();
}

class _ProviderSetupPageState extends State<ProviderSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  
  final List<Map<String, dynamic>> _services = [];
  bool _loading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _experienceCtrl.dispose();
    super.dispose();
  }

  void _addService() {
    showDialog(
      context: context,
      builder: (ctx) => _ServiceDialog(
        onSave: (service) {
          setState(() {
            _services.add(service);
          });
        },
      ),
    );
  }

  void _editService(int index) {
    showDialog(
      context: context,
      builder: (ctx) => _ServiceDialog(
        service: _services[index],
        onSave: (service) {
          setState(() {
            _services[index] = service;
          });
        },
      ),
    );
  }

  void _deleteService(int index) {
    setState(() {
      _services.removeAt(index);
    });
  }

  Future<void> _complete() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (_services.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one service')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // Update provider details
      final db = await LocalDatabase.database;
      await db.update(
        'massagers',
        {
          'phone': _phoneCtrl.text.trim(),
          'location': _locationCtrl.text.trim(),
          'experience': _experienceCtrl.text.trim(),
        },
        where: 'email = ?',
        whereArgs: [widget.providerEmail],
      );

      // Save services
      for (var service in _services) {
        await LocalDatabase.addService(
          providerEmail: widget.providerEmail,
          serviceName: service['name'],
          price: service['price'],
          durationMinutes: service['duration'],
          description: service['description'],
        );
      }

      // Mark setup as complete
      await LocalDatabase.markSetupComplete(widget.providerEmail);

      if (!mounted) return;

      // Show success and navigate to dashboard
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 30),
              const SizedBox(width: 12),
              const Text('Setup Complete!'),
            ],
          ),
          content: const Text(
            'Your profile is ready. You can now receive bookings!',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushReplacementNamed('/massager_login');
              },
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome message
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.waving_hand,
                              color: Colors.purple.shade700, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            'Welcome, ${widget.providerName}!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Let\'s set up your profile and add the services you offer.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Profile Details Section
                    const Text(
                      '📋 Profile Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _locationCtrl,
                      decoration: InputDecoration(
                        labelText: 'Service Location/Area',
                        prefixIcon: const Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _experienceCtrl,
                      decoration: InputDecoration(
                        labelText: 'Years of Experience',
                        prefixIcon: const Icon(Icons.work),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 32),

                    // Services Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '💼 Your Services',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addService,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Service'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade600,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_services.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.add_business,
                                size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No services added yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Add at least one service to continue',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _services.length,
                        itemBuilder: (context, index) {
                          final service = _services[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.purple.shade100,
                                child: Icon(Icons.spa,
                                    color: Colors.purple.shade700),
                              ),
                              title: Text(
                                service['name'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '\$${service['price']} • ${service['duration']} min',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () => _editService(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteService(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 32),

                    // Complete button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _complete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Complete Setup',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// Service Dialog
class _ServiceDialog extends StatefulWidget {
  final Map<String, dynamic>? service;
  final Function(Map<String, dynamic>) onSave;

  const _ServiceDialog({
    this.service,
    required this.onSave,
  });

  @override
  State<_ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<_ServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _durationCtrl;
  late TextEditingController _descriptionCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.service?['name'] ?? '');
    _priceCtrl = TextEditingController(
        text: widget.service?['price']?.toString() ?? '');
    _durationCtrl = TextEditingController(
        text: widget.service?['duration']?.toString() ?? '');
    _descriptionCtrl =
        TextEditingController(text: widget.service?['description'] ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    widget.onSave({
      'name': _nameCtrl.text.trim(),
      'price': double.parse(_priceCtrl.text.trim()),
      'duration': int.parse(_durationCtrl.text.trim()),
      'description': _descriptionCtrl.text.trim(),
    });

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.service == null ? 'Add Service' : 'Edit Service'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Service Name',
                  hintText: 'e.g., Swedish Massage',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Price (\$)',
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid price';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                  suffixText: 'min',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (int.tryParse(v) == null) return 'Invalid duration';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
