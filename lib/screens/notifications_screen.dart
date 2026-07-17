import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/brand_theme.dart';

class NotificationItem {
  final int id;
  final String title;
  final String description;
  final String time;
  final IconData icon;
  final bool isPromo;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    this.isPromo = false,
    this.isRead = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: 1,
      title: 'Technician En Route 🏍️',
      description: 'Operator John Hanson Pro has initialized transit to your coordinates anchor.',
      time: '10 mins ago',
      icon: Icons.directions_bike_outlined,
    ),
    NotificationItem(
      id: 2,
      title: 'Booking Dispatch Success',
      description: 'Your Sofa Deep Chemical Wash booking request has been confirmed and scheduled.',
      time: '1 hr ago',
      icon: Icons.assignment_turned_in_outlined,
    ),
    NotificationItem(
      id: 3,
      title: 'Promotional Sanitization Pass',
      description: 'Apply voucher sanitization code SANITIZE30 to receive 30% discount adjustments on your next AC Jet Wash.',
      time: 'Yesterday',
      icon: Icons.local_offer_outlined,
      isPromo: true,
    ),
    NotificationItem(
      id: 4,
      title: 'Ecosystem Security Verification',
      description: 'Emma, your ledger identity verification status has been fully authenticated to premium level.',
      time: '2 days ago',
      icon: Icons.verified_user_outlined,
      isRead: true,
    ),
  ];

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read.'),
        duration: Duration(seconds: 2),
        backgroundColor: BrandColors.accent,
      ),
    );
  }

  void _toggleRead(int id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index].isRead = !_notifications[index].isRead;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark read',
                style: TextStyle(
                  color: BrandColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _notifications.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 48,
                      color: theme.dividerColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Notifications Yet',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Any logistics updates or promos will be routed here.',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notif = _notifications[index];

                  return GestureDetector(
                    onTap: () => _toggleRead(notif.id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: notif.isRead
                              ? theme.dividerColor
                              : BrandColors.accent.withValues(alpha: 0.3),
                          width: notif.isRead ? 1.0 : 1.5,
                        ),
                        boxShadow: notif.isRead
                            ? null
                            : [
                                BoxShadow(
                                  color: BrandColors.accent.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Icon Container
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: notif.isPromo
                                  ? Colors.amber.withValues(alpha: 0.1)
                                  : BrandColors.accent.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              notif.icon,
                              size: 20,
                              color: notif.isPromo ? Colors.amber : BrandColors.accent,
                            ),
                          ),
                          const SizedBox(width: 14),
                          
                          // Notification Texts
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notif.title,
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: notif.isRead
                                              ? theme.textTheme.bodyLarge?.color
                                              : (isDark ? Colors.white : Colors.black),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      notif.time,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontSize: 9,
                                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  notif.description,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 11.5,
                                    height: 1.4,
                                    color: notif.isRead
                                        ? theme.textTheme.bodyMedium?.color
                                        : (isDark ? BrandColors.darkTextPrimary : BrandColors.lightTextPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
