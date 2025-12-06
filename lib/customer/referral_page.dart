import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../local_database.dart';

class ReferralPage extends StatefulWidget {
  const ReferralPage({super.key});

  @override
  State<ReferralPage> createState() => _ReferralPageState();
}

class _ReferralPageState extends State<ReferralPage> {
  String? _myReferralCode;
  int _myPoints = 0;
  int _lifetimePoints = 0;
  List<Map<String, dynamic>> _myReferrals = [];
  List<Map<String, dynamic>> _pointsHistory = [];
  bool _loading = true;
  String? _customerEmail;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _customerEmail = prefs.getString('customer_email');
      
      if (_customerEmail == null) {
        setState(() => _loading = false);
        return;
      }

      // Initialize loyalty account if it doesn't exist
      await LocalDatabase.initializeLoyaltyAccount(_customerEmail!);

      // Get loyalty points data
      final loyaltyData = await LocalDatabase.getLoyaltyPoints(_customerEmail!);
      
      // Get my referrals
      final referrals = await LocalDatabase.getMyReferrals(_customerEmail!);
      
      // Get points history
      final history = await LocalDatabase.getPointsHistory(_customerEmail!);

      setState(() {
        _myReferralCode = loyaltyData?['referral_code'] as String?;
        _myPoints = loyaltyData?['points'] as int? ?? 0;
        _lifetimePoints = loyaltyData?['lifetime_points'] as int? ?? 0;
        _myReferrals = referrals;
        _pointsHistory = history;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void _copyReferralCode() {
    if (_myReferralCode != null) {
      Clipboard.setData(ClipboardData(text: _myReferralCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Referral code copied to clipboard!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _shareReferralCode() {
    if (_myReferralCode != null) {
      Share.share(
        'Join me on Therapy Booking App! Use my referral code $_myReferralCode to get 25 bonus points when you sign up. Download now and book your first massage!',
        subject: 'Get 25 points with my referral code!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Refer & Earn'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Header with gradient
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.teal.shade700,
                            Colors.teal.shade400,
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.card_giftcard,
                            size: 80,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Share the Love!',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Invite friends and earn points on every booking they make',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Points Display Cards
                          Row(
                            children: [
                              Expanded(
                                child: Card(
                                  elevation: 4,
                                  color: Colors.amber.shade50,
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.stars,
                                          size: 40,
                                          color: Colors.amber.shade700,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '$_myPoints',
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber.shade900,
                                          ),
                                        ),
                                        const Text(
                                          'Available Points',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Card(
                                  elevation: 4,
                                  color: Colors.purple.shade50,
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.people,
                                          size: 40,
                                          color: Colors.purple.shade700,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${_myReferrals.length}',
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.purple.shade900,
                                          ),
                                        ),
                                        const Text(
                                          'Friends Referred',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Referral Code Card
                          Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.qr_code,
                                        color: Colors.teal.shade700,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Your Referral Code',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.teal.shade200,
                                        width: 2,
                                      ),
                                    ),
                                    child: Text(
                                      _myReferralCode ?? 'Loading...',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                        color: Colors.teal.shade900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: _copyReferralCode,
                                          icon: const Icon(Icons.copy),
                                          label: const Text('Copy Code'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.teal.shade600,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: _shareReferralCode,
                                          icon: const Icon(Icons.share),
                                          label: const Text('Share'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange.shade600,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // How it Works
                          Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'How It Works',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildHowItWorksStep(
                                    '1',
                                    'Share your code',
                                    'Send your referral code to friends',
                                    Icons.share,
                                  ),
                                  _buildHowItWorksStep(
                                    '2',
                                    'Friend signs up',
                                    'They use your code during signup',
                                    Icons.person_add,
                                  ),
                                  _buildHowItWorksStep(
                                    '3',
                                    'Earn points',
                                    'Get 10% points on every booking they make',
                                    Icons.monetization_on,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // My Referrals Section
                          if (_myReferrals.isNotEmpty) ...[
                            Text(
                              'My Referrals (${_myReferrals.length})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Card(
                              elevation: 2,
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _myReferrals.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final referral = _myReferrals[index];
                                  final email = referral['referred_email'] as String;
                                  final date = DateTime.parse(referral['referral_date'] as String);
                                  
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.teal.shade100,
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.teal.shade700,
                                      ),
                                    ),
                                    title: Text(
                                      email.split('@')[0],
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      'Joined ${_formatDate(date)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Icon(
                                      Icons.check_circle,
                                      color: Colors.green.shade600,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Points History
                          if (_pointsHistory.isNotEmpty) ...[
                            Text(
                              'Recent Activity',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Card(
                              elevation: 2,
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _pointsHistory.length > 10 ? 10 : _pointsHistory.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final history = _pointsHistory[index];
                                  final points = history['points_earned'] as int;
                                  final reason = history['reason'] as String;
                                  final date = DateTime.parse(history['earned_date'] as String);
                                  
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: points > 0 
                                          ? Colors.green.shade100 
                                          : Colors.red.shade100,
                                      child: Icon(
                                        points > 0 ? Icons.add : Icons.remove,
                                        color: points > 0 
                                            ? Colors.green.shade700 
                                            : Colors.red.shade700,
                                      ),
                                    ),
                                    title: Text(
                                      reason,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      _formatDate(date),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Text(
                                      '${points > 0 ? '+' : ''}$points',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: points > 0 
                                            ? Colors.green.shade700 
                                            : Colors.red.shade700,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],

                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: _myPoints >= 100
          ? FloatingActionButton.extended(
              onPressed: () {
                // TODO: Navigate to redeem points page
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('You can redeem $_myPoints points = ₹${(_myPoints / 10).toStringAsFixed(0)} discount!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.redeem),
              label: const Text('Redeem Points'),
              backgroundColor: Colors.green.shade600,
            )
          : null,
    );
  }

  Widget _buildHowItWorksStep(String number, String title, String subtitle, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.teal.shade100,
            child: Text(
              number,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: Colors.teal.shade400),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
