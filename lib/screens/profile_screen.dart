import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../network/services/socketService.dart';
import '../security/secureStorage.dart';
import '../store/use_app_store.dart';
import '../state/app_state.dart';
import '../theme/brand_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final customerProfile = ref.watch(customerProfileProvider);
    final customerAddresses = ref.watch(customerAddressProvider);

    final username = customerProfile?['username']?.toString() ?? 'User Profile';
    final initials = username.isNotEmpty
        ? username.trim().split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase()
        : 'EW';

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
                // Avatar
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4F2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initials.isNotEmpty ? initials : 'U',
                      style: const TextStyle(
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
                  username,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: BrandColors.accent.withValues(alpha: 0.1),
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
                      // Theme Selector Dropdown
                      ListTile(
                        leading: const Icon(Icons.palette_outlined, size: 18, color: BrandColors.accent),
                        title: const Text(
                          'Appearance Theme',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        trailing: DropdownButtonHideUnderline(
                          child: DropdownButton<ThemeMode>(
                            value: appState.currentThemeMode,
                            dropdownColor: theme.cardColor,
                            icon: Icon(Icons.arrow_drop_down, color: theme.textTheme.bodyMedium?.color),
                            items: const [
                              DropdownMenuItem(
                                value: ThemeMode.system,
                                child: Text('System', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.light,
                                child: Text('Light', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.dark,
                                child: Text('Dark', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                            ],
                            onChanged: (mode) {
                              if (mode != null) {
                                appState.setThemeMode(mode);
                              }
                            },
                          ),
                        ),
                      ),
                      Divider(height: 1, color: theme.dividerColor),
                      // Delivery Coordinates
                      _buildProfileOption(
                        leadingIcon: Icons.location_on_outlined,
                        title: 'Managed Delivery Coordinates',
                        trailingText: '${customerAddresses?.length ?? 0} saved',
                        theme: theme,
                        onTap: () => context.push('/addresses'),
                      ),
                      Divider(height: 1, color: theme.dividerColor),
                      // Payment Modules
                      _buildProfileOption(
                        leadingIcon: Icons.payment_outlined,
                        title: 'Encrypted Payment Modules',
                        trailingText: 'Visa ••••',
                        theme: theme,
                      ),
                      Divider(height: 1, color: theme.dividerColor),
                      // Help Support
                      _buildProfileOption(
                        leadingIcon: Icons.shield_outlined,
                        title: 'Trust & Help Support Matrix',
                        trailingText: '›',
                        theme: theme,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Terminate session logout button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      await TokenRepository().deleteToken();
                      ref.read(socketServiceProvider).disconnect();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
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
    required IconData leadingIcon,
    required String title,
    required String trailingText,
    required ThemeData theme,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(leadingIcon, size: 18, color: BrandColors.accent),
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
      onTap: onTap,
    );
  }
}
