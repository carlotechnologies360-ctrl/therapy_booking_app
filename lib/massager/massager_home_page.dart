import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../local_database.dart';
import '../models/booking_model.dart';
import 'manage_services_page.dart';

class MassagerHomePage extends StatefulWidget {
  final String therapistCode;
  final String therapistName;

  const MassagerHomePage({
    super.key,
    required this.therapistCode,
    this.therapistName = 'Therapist',
  });

  @override
  State<MassagerHomePage> createState() => _MassagerHomePageState();
}

class _MassagerHomePageState extends State<MassagerHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<BookingModel> _allBookings = [];
  List<BookingModel> _upcomingBookings = [];
  List<BookingModel> _historyBookings = [];
  Map<String, dynamic> _customerStats = {};
  int _customerCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);

    try {
      final bookingsData =
          await LocalDatabase.getBookingsByTherapistCode(widget.therapistCode);
      final customerCount =
          await LocalDatabase.getCustomerCountByTherapistCode(widget.therapistCode);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final List<BookingModel> upcoming = [];
      final List<BookingModel> history = [];
      final Map<String, Map<String, dynamic>> customers = {};

      for (var data in bookingsData) {
        final booking = BookingModel.fromMap(data);
        final bookingDay = DateTime(
          booking.bookingDate.year,
          booking.bookingDate.month,
          booking.bookingDate.day,
        );

        // Categorize bookings
        if (bookingDay.isAfter(today) ||
            bookingDay.isAtSameMomentAs(today)) {
          upcoming.add(booking);
        } else {
          history.add(booking);
        }

        // Track customer stats
        if (!customers.containsKey(booking.customerEmail)) {
          customers[booking.customerEmail] = {
            'name': booking.customerName,
            'email': booking.customerEmail,
            'bookingCount': 0,
            'totalSpent': 0.0,
            'lastBooking': booking.bookingDate,
          };
        }
        customers[booking.customerEmail]!['bookingCount'] =
            (customers[booking.customerEmail]!['bookingCount'] as int) + 1;
        customers[booking.customerEmail]!['totalSpent'] =
            (customers[booking.customerEmail]!['totalSpent'] as double) +
                booking.totalPrice;

        final lastBooking =
            customers[booking.customerEmail]!['lastBooking'] as DateTime;
        if (booking.bookingDate.isAfter(lastBooking)) {
          customers[booking.customerEmail]!['lastBooking'] = booking.bookingDate;
        }
      }

      setState(() {
        _allBookings =
            bookingsData.map((data) => BookingModel.fromMap(data)).toList();
        _upcomingBookings = upcoming;
        _historyBookings = history;
        _customerStats = customers;
        _customerCount = customerCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bookings: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'pending':
        return Icons.pending;
      default:
        return Icons.info;
    }
  }

  Future<String?> _getProviderEmail() async {
    try {
      final db = await LocalDatabase.database;
      final result = await db.query(
        'massagers',
        columns: ['email'],
        where: 'code = ?',
        whereArgs: [widget.therapistCode],
        limit: 1,
      );
      if (result.isNotEmpty) {
        return result.first['email'] as String;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Service Provider Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.people),
              text: 'Customers (${_customerCount})',
            ),
            Tab(
              icon: const Icon(Icons.upcoming),
              text: 'Upcoming (${_upcomingBookings.length})',
            ),
            Tab(
              icon: const Icon(Icons.history),
              text: 'History (${_historyBookings.length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Dashboard Header
                Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade400, Colors.teal.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, size: 50, color: Colors.teal),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.therapistName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.key,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.therapistCode,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 18),
                                  color: Colors.white,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    // Copy code to clipboard
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Code copied to clipboard!'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Share this code with customers',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatCard(
                                'Total Bookings',
                                _allBookings.length.toString(),
                                Icons.calendar_today,
                              ),
                              _buildStatCard(
                                'Customers',
                                _customerCount.toString(),
                                Icons.people,
                              ),
                              _buildStatCard(
                                'Upcoming',
                                _upcomingBookings.length.toString(),
                                Icons.upcoming,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final email = await _getProviderEmail();
                              if (mounted && email != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ManageServicesPage(
                                      providerEmail: email,
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.settings),
                            label: const Text('Manage Services'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.teal.shade700,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tabs Content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildCustomersList(),
                          _buildBookingsList(_upcomingBookings, isUpcoming: true),
                          _buildBookingsList(_historyBookings, isUpcoming: false),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildCustomersList() {
    if (_customerStats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'No customers yet',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Customers will appear here after booking',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final customerList = _customerStats.values.toList();
    customerList.sort((a, b) =>
        (b['bookingCount'] as int).compareTo(a['bookingCount'] as int));

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: customerList.length,
        itemBuilder: (context, index) {
          final customer = customerList[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.teal.shade100,
                child: Text(
                  (customer['name'] as String).substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade700,
                  ),
                ),
              ),
              title: Text(
                customer['name'] as String,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    customer['email'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.event, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${customer['bookingCount']} bookings',
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '\$${(customer['totalSpent'] as double).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last: ${DateFormat('MMM d, yyyy').format(customer['lastBooking'] as DateTime)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingsList(List<BookingModel> bookings,
      {required bool isUpcoming}) {
    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isUpcoming ? Icons.event_available : Icons.history,
                size: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                isUpcoming ? 'No upcoming bookings' : 'No booking history',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isUpcoming
                    ? 'New bookings will appear here'
                    : 'Past bookings will appear here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.customerName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              booking.customerEmail,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(booking.status)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(booking.status),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(booking.status),
                              size: 16,
                              color: _getStatusColor(booking.status),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              booking.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(booking.status),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEEE, MMMM d, yyyy')
                            .format(booking.bookingDate),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        booking.timeSlot,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.timer, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${booking.totalDuration} min',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Services:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...booking.serviceNames.map(
                    (service) => Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.check, size: 16, color: Colors.teal[700]),
                          const SizedBox(width: 4),
                          Text(
                            service,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Booked: ${DateFormat('MMM d, yyyy').format(booking.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '\$${booking.totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
