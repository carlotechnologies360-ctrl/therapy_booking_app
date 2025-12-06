import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  List<String> _recentCodes = [];
  bool _saveCode = true;

  @override
  void initState() {
    super.initState();
    _loadRecentCodes();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentCodes() async {
    final prefs = await SharedPreferences.getInstance();
    final codes = prefs.getStringList('recent_therapist_codes') ?? [];
    setState(() {
      _recentCodes = codes;
    });
  }

  Future<void> _saveRecentCode(String code) async {
    if (!_saveCode) return;
    
    final prefs = await SharedPreferences.getInstance();
    List<String> codes = prefs.getStringList('recent_therapist_codes') ?? [];
    
    // Remove if already exists (to move to top)
    codes.remove(code);
    
    // Add to beginning
    codes.insert(0, code);
    
    // Keep only last 5 codes
    if (codes.length > 5) {
      codes = codes.sublist(0, 5);
    }
    
    await prefs.setStringList('recent_therapist_codes', codes);
    
    setState(() {
      _recentCodes = codes;
    });
  }

  Future<void> _removeRecentCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> codes = prefs.getStringList('recent_therapist_codes') ?? [];
    codes.remove(code);
    await prefs.setStringList('recent_therapist_codes', codes);
    
    setState(() {
      _recentCodes = codes;
    });
  }

  Future<void> _submit() async {
    if (_codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a service provider code")),
      );
      return;
    }

    setState(() => _loading = true);

    final enteredCode = _codeController.text.trim();

    try {
      // Search for therapist in local database
      final therapistData = await LocalDatabase.findByCode(
        'massagers',
        enteredCode,
      );

      setState(() => _loading = false);

      if (therapistData == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid service provider code. Please check and try again."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check if therapist has completed setup
      final setupComplete = (therapistData['setupComplete'] as int?) == 1;
      
      if (!setupComplete) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("This service provider hasn't completed their setup yet."),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Get service provider info
      final therapistName = therapistData['name'] as String? ?? 'Service Provider';
      final therapistEmail = therapistData['email'] as String? ?? '';
      final therapistPhone = therapistData['phone'] as String? ?? '';
      final therapistExperience = therapistData['experience'] as String? ?? '';
      final therapistLocation = therapistData['location'] as String? ?? '';

      // Save code to recent list
      await _saveRecentCode(enteredCode);

      // Get customer details from local database
      final prefs = await SharedPreferences.getInstance();
      final customerEmail = prefs.getString('customer_email') ?? '';
      
      // Save this as the customer's default therapist code for future logins (per customer)
      if (customerEmail.isNotEmpty) {
        await prefs.setString('customer_therapist_code_$customerEmail', enteredCode);
      }
      String customerName = 'Customer';
      if (customerEmail.isNotEmpty) {
        final customerData = await LocalDatabase.findByEmail('customers', customerEmail);
        customerName = customerData?['name'] as String? ?? customerName;
        // Record customer visit only if we have an email
        await LocalDatabase.recordCustomerVisit(
          therapistCode: enteredCode,
          customerEmail: customerEmail,
          customerName: customerName,
        );
      }

      // Store therapist code in session
      if (!mounted) return;
      Provider.of<SessionProvider>(context, listen: false)
          .setTherapistCode(enteredCode);

      // Navigate to customer home page with therapist details
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CustomerHomePage(
            therapistCode: enteredCode,
            therapistName: therapistName,
            therapistBio: '$therapistExperience years of experience in therapeutic massage',
            therapistContact: '$therapistEmail | $therapistPhone | $therapistLocation',
          ),
        ),
      );
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitRecentCode(String code) async {
    _codeController.text = code;
    await _submit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Find Your Service Provider"),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal.shade700,
              Colors.teal.shade50,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'Enter Service Provider Code',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Get the code from your service provider to continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                
                // Code Input Card
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                          decoration: InputDecoration(
                            labelText: "Service Provider Code",
                            hintText: "PROVIDER_XXXXXX",
                            prefixIcon: Icon(Icons.key, color: Colors.teal.shade600),
                            suffixIcon: _codeController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _codeController.clear();
                                      });
                                    },
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.content_paste),
                                    onPressed: () async {
                                      final data = await Clipboard.getData('text/plain');
                                      if (data?.text != null) {
                                        setState(() {
                                          _codeController.text = data!.text!;
                                        });
                                      }
                                    },
                                  ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.teal.shade600,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (value) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        
                        // Save Code Checkbox
                        Row(
                          children: [
                            Checkbox(
                              value: _saveCode,
                              onChanged: (value) {
                                setState(() {
                                  _saveCode = value ?? true;
                                });
                              },
                              activeColor: Colors.teal.shade600,
                            ),
                            Expanded(
                              child: Text(
                                'Save this code for quick access later',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Continue Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: _loading
                              ? Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.teal.shade600,
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: _codeController.text.isEmpty
                                      ? null
                                      : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal.shade600,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                    disabledBackgroundColor: Colors.grey.shade300,
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Continue',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Recent Codes Section
                if (_recentCodes.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text(
                    'Recent Service Providers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentCodes.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: Colors.grey.shade200,
                      ),
                      itemBuilder: (context, index) {
                        final code = _recentCodes[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal.shade100,
                            child: Icon(
                              Icons.history,
                              color: Colors.teal.shade700,
                            ),
                          ),
                          title: Text(
                            code,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          subtitle: Text(
                            'Tap to use this code',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Colors.grey.shade400,
                            ),
                            onPressed: () => _removeRecentCode(code),
                          ),
                          onTap: () => _submitRecentCode(code),
                        );
                      },
                    ),
                  ),
                ],
                
                // Help Section
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ask your service provider for their unique code to view their services and book appointments',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
