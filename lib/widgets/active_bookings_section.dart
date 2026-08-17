import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../state/app_state.dart';
import '../theme/brand_theme.dart';

class ActiveBookingsSection extends StatelessWidget {
  final AppState appState;

  const ActiveBookingsSection({
    super.key,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!appState.isFulfillmentPipelineRunning) {
      return const SizedBox.shrink();
    }

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
          onTap: () => context.push('/booking-detail'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), BrandColors.primary, Color(0xFF1E1B4B)],
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
              border: Border.all(color: BrandColors.accent.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
                      ),
                      child: const Text(
                        'TECHNICIAN EN ROUTE',
                        style: TextStyle(
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
                        Icon(Icons.directions_bike, size: 14, color: Colors.tealAccent),
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
                const Text(
                  'Sofa Deep Chemical Wash',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    const Text(
                      'Arrival Target: ',
                      style: TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        appState.chosenTimeSlot,
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
