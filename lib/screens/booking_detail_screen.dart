import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../state/app_state.dart';
import '../theme/brand_theme.dart';
import '../widgets/map_tracking_mock.dart';

class BookingDetailScreen extends StatelessWidget {
  const BookingDetailScreen({super.key});

  String _getDateString(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _showCancelConfirmation(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          title: Text(
            'Cancel Booking?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to cancel this sanitization dispatch? This action cannot be undone.',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 12,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Keep Appointment',
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                appState.cancelBooking();
                Navigator.of(context).pop(); // close dialog
                context.pop(); // return to booking list screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Booking dispatch cancelled successfully.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              child: const Text(
                'Cancel Booking',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => context.pop(),
          child: Text(
            '← Roster',
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
        leadingWidth: 80,
        title: Text(
          'LIVE DISPATCH TRACKER',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: AppState(),
        builder: (context, _) {
          final appState = AppState();
          final address = appState.activeAddress;

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            children: [
              // Mock tracking map
              const MapTrackingMock(),
              const SizedBox(height: 20),

              // Booking Details card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BOOKING LOGISTICS DETAIL',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: BrandColors.accent,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Service row
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            'https://images.unsplash.com/photo-1589405858862-2ac9cbb41321?q=80&w=200&auto=format&fit=crop',
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sofa Deep Chemical Wash',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Premium Sanitization • \$56.40 Total Price',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    // Date & Time
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: BrandColors.accent),
                        const SizedBox(width: 8),
                        Text(
                          _getDateString(appState.chosenDate),
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.access_time_outlined, size: 14, color: BrandColors.accent),
                        const SizedBox(width: 8),
                        Text(
                          appState.chosenTimeSlot,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Target Address
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 14, color: BrandColors.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${address.street}, ${address.apt}, ${address.city}',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),

                    // Special instructions (description)
                    if (appState.bookingDescription.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.description_outlined, size: 14, color: BrandColors.accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Special Request:',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: BrandColors.accent,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  appState.bookingDescription,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Automated Dispatch Progression
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: BrandColors.accent.withValues(alpha: 0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: BrandColors.accent.withValues(alpha: 0.05),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AUTOMATED DISPATCH PROGRESSION',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: BrandColors.accent,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildStepItem(
                      icon: '●',
                      text: 'Operator Dispatched Target Complete',
                      isCompleted: true,
                      theme: theme,
                    ),
                    _buildStepDivider(),
                    _buildStepItem(
                      icon: '●',
                      text: 'Technician Currently En Route',
                      isCompleted: true,
                      theme: theme,
                    ),
                    _buildStepDivider(),
                    _buildStepItem(
                      icon: '○',
                      text: 'Job Operations Setup Pending',
                      isCompleted: false,
                      theme: theme,
                    ),
                    _buildStepDivider(),
                    _buildStepItem(
                      icon: '○',
                      text: 'Fulfillment Review Settlement',
                      isCompleted: false,
                      theme: theme,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Technician assigned details card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE6F4F2),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'JH',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: BrandColors.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'John Hanson Pro',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ecosystem Dispatch Matrix Active',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => context.push('/chat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BrandColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Chat Thread',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Cancel Booking Button
              Center(
                child: TextButton.icon(
                  onPressed: () => _showCancelConfirmation(context, appState),
                  icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 16),
                  label: const Text(
                    'Cancel Dispatch Appointment',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.redAccent, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepItem({
    required String icon,
    required String text,
    required bool isCompleted,
    required ThemeData theme,
  }) {
    return Opacity(
      opacity: isCompleted ? 1.0 : 0.4,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            icon,
            style: TextStyle(
              fontSize: 14,
              color: isCompleted ? BrandColors.accent : theme.textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                color: isCompleted ? BrandColors.accent : theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 3, top: 4, bottom: 4),
      height: 16,
      width: 1.5,
      color: Colors.grey.withValues(alpha: 0.3),
    );
  }
}
