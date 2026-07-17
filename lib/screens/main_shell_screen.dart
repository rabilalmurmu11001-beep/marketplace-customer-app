import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/brand_theme.dart';

class MainShellScreen extends StatelessWidget {
  final Widget child;

  const MainShellScreen({
    super.key,
    required this.child,
  });

  int _getSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/bookings')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/bookings');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedIndex = _getSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(
            top: BorderSide(color: theme.dividerColor, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context: context,
              index: 0,
              selectedIndex: selectedIndex,
              icon: '🏠',
              label: 'Explore',
            ),
            _buildNavItem(
              context: context,
              index: 1,
              selectedIndex: selectedIndex,
              icon: '🔍',
              label: 'Discovery',
            ),
            _buildNavItem(
              context: context,
              index: 2,
              selectedIndex: selectedIndex,
              icon: '📅',
              label: 'Pipelines',
            ),
            _buildNavItem(
              context: context,
              index: 3,
              selectedIndex: selectedIndex,
              icon: '👤',
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required int selectedIndex,
    required String icon,
    required String label,
  }) {
    final isSelected = index == selectedIndex;
    final theme = Theme.of(context);

    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index, context),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedScale(
          scale: isSelected ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? BrandColors.accent : theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
