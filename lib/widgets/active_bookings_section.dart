import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../store/use_app_store.dart';
import '../theme/brand_theme.dart';

class ActiveBookingsSection extends ConsumerWidget {
  const ActiveBookingsSection({super.key});

  String _getStatusBadgeText(String status) {
    switch (status.toLowerCase()) {
      case 'requested':
        return 'REQUEST DISPATCHED';
      case 'accepted':
        return 'TECHNICIAN ASSIGNED';
      case 'in_progress':
        return 'SERVICE IN PROGRESS';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allBookings = ref.watch(customerBookingsProvider);

    if (allBookings == null || allBookings.isEmpty) {
      return const SizedBox.shrink();
    }

    final activeBookings = allBookings.where((item) {
      final status =
          item['booking']?['bookingStatus']?.toString().toLowerCase() ?? '';
      return status == 'requested' ||
          status == 'accepted' ||
          status == 'in_progress';
    }).toList();

    if (activeBookings.isEmpty) {
      return const SizedBox.shrink();
    }

    final activeBooking = activeBookings.first;
    final booking =
        activeBooking['booking'] as Map<String, dynamic>? ?? activeBooking;
    final service = activeBooking['service'] as Map<String, dynamic>? ?? {};

    final status = booking['bookingStatus']?.toString() ?? 'requested';
    final serviceTitle = service['name']?.toString() ?? 'Service Appointment';
    final timeSlot = booking['scheduledTime']?.toString() ?? 'Scheduled Window';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Active Bookings',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => context.go('/bookings'),
              child: const Text(
                'View All',
                style: TextStyle(
                  color: BrandColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => context.push('/booking-detail', extra: activeBooking),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0F766E),
                  BrandColors.primary,
                  Color(0xFF1E1B4B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: BrandColors.accent.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: BrandColors.accent.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.teal.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        _getStatusBadgeText(status),
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.directions_bike,
                          size: 14,
                          color: Colors.tealAccent,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Tracking Live',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.tealAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  serviceTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Arrival Target: ',
                      style: TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        timeSlot,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
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
      ],
    );
  }
}
