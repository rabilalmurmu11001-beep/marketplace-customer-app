import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../state/app_state.dart';
import '../theme/brand_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Asset Control Center',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListenableBuilder(
        listenable: AppState(),
        builder: (context, _) {
          final appState = AppState();

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                // EW Avatar
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4F2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'EW',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: BrandColors.accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // User Details
                Text(
                  'Emma Watson',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: BrandColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'PREMIUM ELITE MEMBER',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: BrandColors.accent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Settings List
                Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    children: [
                      // Dark Mode Switch
                      ListTile(
                        leading: const Text('🌓', style: TextStyle(fontSize: 16)),
                        title: const Text(
                          'Dark Mode Active',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        trailing: Switch(
                          value: appState.currentThemeMode == ThemeMode.dark,
                          activeColor: BrandColors.accent,
                          onChanged: (val) {
                            appState.toggleTheme(val);
                          },
                        ),
                      ),
                      Divider(height: 1, color: theme.dividerColor),
                      // Delivery Coordinates
                      _buildProfileOption(
                        leadingIcon: '📍',
                        title: 'Managed Delivery Coordinates',
                        trailingText: '${appState.customerAddresses.length} saved',
                        theme: theme,
                      ),
                      Divider(height: 1, color: theme.dividerColor),
                      // Payment Modules
                      _buildProfileOption(
                        leadingIcon: '💳',
                        title: 'Encrypted Payment Modules',
                        trailingText: 'Visa ••••',
                        theme: theme,
                      ),
                      Divider(height: 1, color: theme.dividerColor),
                      // Help Support
                      _buildProfileOption(
                        leadingIcon: '🛡️',
                        title: 'Trust & Help Support Matrix',
                        trailingText: '›',
                        theme: theme,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Reset Journey
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      appState.resetJourney();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🔄 Journey Cycle Reset Successful!'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 1),
                        ),
                      );
                      context.go('/splash');
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: BrandColors.accent, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Reset Journey Cycle',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: BrandColors.accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Terminate session logout button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      context.go('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.red,
                      elevation: 0,
                      side: BorderSide(color: Colors.red.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Terminate Session Logout',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileOption({
    required String leadingIcon,
    required String title,
    required String trailingText,
    required ThemeData theme,
  }) {
    return ListTile(
      leading: Text(leadingIcon, style: const TextStyle(fontSize: 16)),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            trailingText,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
          ),
          const SizedBox(width: 4),
          if (trailingText == '›')
            Text(
              '',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
        ],
      ),
      onTap: () {},
    );
  }
}
