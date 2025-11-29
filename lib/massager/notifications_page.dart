import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../local_database.dart';

class NotificationsPage extends StatefulWidget {
  final String userEmail;

  const NotificationsPage({super.key, required this.userEmail});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    try {
      final notifications =
          await LocalDatabase.getNotificationsByEmail(widget.userEmail);
      setState(() {
        _notifications = notifications;
        _loading = false;
      });

      // Mark all as read
      await LocalDatabase.markAllNotificationsAsRead(widget.userEmail);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteNotification(int notificationId) async {
    try {
      await LocalDatabase.deleteNotification(notificationId);
      await _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return _buildNotificationCard(notification);
                  },
                ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final type = notification['type'] ?? 'info';
    final isRead = notification['isRead'] == 1;
    final createdAt = notification['createdAt'] != null
        ? DateTime.parse(notification['createdAt'])
        : DateTime.now();
    final dateStr = DateFormat('MMM dd, yyyy - hh:mm a').format(createdAt);

    IconData icon;
    Color iconColor;

    switch (type) {
      case 'approval':
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'rejection':
        icon = Icons.cancel;
        iconColor = Colors.red;
        break;
      case 'info':
      default:
        icon = Icons.info;
        iconColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 1 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isRead
            ? BorderSide.none
            : BorderSide(color: Colors.purple.shade200, width: 2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          notification['title'] ?? 'Notification',
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              notification['message'] ?? '',
              style: const TextStyle(fontSize: 14),
            ),
            if (notification['therapistCode'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.vpn_key,
                      size: 16,
                      color: Colors.purple.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      notification['therapistCode'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              dateStr,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          color: Colors.red.shade300,
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Notification'),
                content:
                    const Text('Are you sure you want to delete this notification?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              _deleteNotification(notification['id']);
            }
          },
        ),
      ),
    );
  }
}
