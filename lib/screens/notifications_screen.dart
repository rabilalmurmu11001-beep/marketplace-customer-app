import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/brand_theme.dart';
import '../network/services/notification_service.dart';

class NotificationItem {
  final String id;
  final String title;
  final String description;
  final String time;
  final IconData icon;
  final bool isPromo;
  final Map<String, dynamic>? data;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    this.isPromo = false,
    this.isRead = false,
    this.data,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final rawList = await NotificationService.instance.getUserNotifications();
    if (!mounted) return;

    if (rawList.isNotEmpty) {
      final items = rawList.map((m) {
        final type = m['type']?.toString() ?? 'general';
        IconData icon = Icons.notifications_outlined;
        bool isPromo = false;

        if (type == 'booking') {
          icon = Icons.assignment_turned_in_outlined;
        } else if (type == 'chat') {
          icon = Icons.chat_bubble_outline;
        } else if (type == 'promo') {
          icon = Icons.local_offer_outlined;
          isPromo = true;
        } else if (type == 'call') {
          icon = Icons.call_outlined;
        }

        // Format created date
        String timeStr = 'Recently';
        if (m['createdAt'] != null) {
          try {
            final dt = DateTime.parse(m['createdAt'].toString());
            final diff = DateTime.now().difference(dt);
            if (diff.inMinutes < 60) {
              timeStr = '${diff.inMinutes} mins ago';
            } else if (diff.inHours < 24) {
              timeStr = '${diff.inHours} hrs ago';
            } else {
              timeStr = '${diff.inDays} days ago';
            }
          } catch (_) {}
        }

        return NotificationItem(
          id: m['id']?.toString() ?? '',
          title: m['title']?.toString() ?? '',
          description: m['body']?.toString() ?? '',
          time: timeStr,
          icon: icon,
          isPromo: isPromo,
          isRead: m['isRead'] == true,
          data: m['data'] is Map ? Map<String, dynamic>.from(m['data'] as Map) : null,
        );
      }).toList();

      setState(() {
        _notifications = items;
        _isLoading = false;
      });
    } else {
      setState(() {
        _notifications = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final success = await NotificationService.instance.markAllAsRead();
    if (!mounted) return;
    if (success) {
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
  }

  Future<void> _onNotificationTap(NotificationItem notif) async {
    if (!notif.isRead) {
      setState(() => notif.isRead = true);
      await NotificationService.instance.markAsRead(notif.id);
    }

    if (notif.data != null && mounted) {
      final data = notif.data!;
      // 1. Direct route
      if (data.containsKey('route') && data['route'] is String && (data['route'] as String).isNotEmpty) {
        context.push(data['route'] as String);
        return;
      }
      // 2. Booking route
      final bookingId = data['booking_id'] ?? data['bookingId'] ?? data['id'];
      if (data['type'] == 'booking' && bookingId != null) {
        context.push('/booking-detail?booking_id=$bookingId');
        return;
      }
      // 3. Chat route
      final roomId = data['roomId'] ?? data['room_id'];
      if (data['type'] == 'chat' && roomId != null) {
        final recipientName = data['recipientName'] ?? data['senderName'] ?? '';
        context.push('/chat?roomId=$roomId&recipientName=$recipientName');
        return;
      }
    }
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: BrandColors.accent))
            : RefreshIndicator(
                color: BrandColors.accent,
                onRefresh: _loadNotifications,
                child: _notifications.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                          Center(
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
                                  'Booking updates and chat alerts will appear here.',
                                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.all(20.0),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notif = _notifications[index];

                          return GestureDetector(
                            onTap: () => _onNotificationTap(notif),
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
      ),
    );
  }
}
