import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../state/app_state.dart';
import '../theme/brand_theme.dart';

class BookingDetailScreen extends StatelessWidget {
  const BookingDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Automated Dispatch Progression
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: BrandColors.accent.withOpacity(0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: BrandColors.accent.withOpacity(0.05),
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
              ],
            ),
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
      color: Colors.grey.withOpacity(0.3),
    );
  }
}
