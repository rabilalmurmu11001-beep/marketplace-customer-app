import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../state/app_state.dart';
import '../theme/brand_theme.dart';

class FunnelStep2Screen extends StatefulWidget {
  const FunnelStep2Screen({super.key});

  @override
  State<FunnelStep2Screen> createState() => _FunnelStep2ScreenState();
}

class _FunnelStep2ScreenState extends State<FunnelStep2Screen> {
  double _swipeProgress = 0.0;
  bool _isBooked = false;

  String _getDateString(int index) {
    switch (index) {
      case 0:
        return 'May 24, 2026';
      case 1:
        return 'May 25, 2026';
      case 2:
        return 'May 26, 2026';
      default:
        return 'May 25, 2026';
    }
  }

  void _onSwipeComplete() {
    if (_isBooked) return;
    setState(() {
      _isBooked = true;
    });

    final appState = AppState();
    appState.bookFulfillment();

    // Show success dialog or snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎉 Booking Manifest Dispatched Successfully!'),
        backgroundColor: BrandColors.accent,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        context.go('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppState();
    final address = appState.activeAddress;

    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => context.pop(),
          child: Text(
            '← Back',
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
        leadingWidth: 80,
        title: Text(
          'FUNNELS: MANIFEST',
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Card 1: Professional details
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
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE6F4F2),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                'JH',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
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
                                  'John Hanson Professional',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Sofa Deep Wash Package',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 2: Summary details
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow('Target Date:', _getDateString(appState.chosenDateIndex), theme, valueColor: theme.textTheme.bodyLarge?.color),
                          const SizedBox(height: 10),
                          _buildSummaryRow('Window Arrival:', appState.chosenTimeSlot, theme, valueColor: BrandColors.accent),
                          const SizedBox(height: 10),
                          _buildSummaryRow('Address Target:', address.street, theme, valueColor: theme.textTheme.bodyLarge?.color),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 3: Transparent receipt details
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow('Base Rate Quote:', '\$49.00', theme),
                          const SizedBox(height: 8),
                          _buildSummaryRow('Sanitization Materials Fee:', '\$5.00', theme),
                          const SizedBox(height: 8),
                          _buildSummaryRow('Ecosystem Regulatory Taxes:', '\$2.40', theme),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Price Aggregation:',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const Text(
                                '\$56.40',
                                style: TextStyle(
                                  color: BrandColors.accent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Swipe to Confirm Bar
            LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                final double sliderWidth = 52.0;
                final double maxSlideDistance = width - sliderWidth - 8.0;

                return Container(
                  height: 60,
                  width: double.infinity,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Background Track Text
                      Center(
                        child: Text(
                          _isBooked ? 'BOOKING DISPATCHED' : 'SWIPE TO CONFIRM BOOKING',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: BrandColors.accent,
                          ),
                        ),
                      ),
                      // Swipe Handle
                      AnimatedPositioned(
                        duration: _swipeProgress == 0.0 || _swipeProgress == 1.0
                            ? const Duration(milliseconds: 200)
                            : Duration.zero,
                        left: _swipeProgress * maxSlideDistance,
                        child: GestureDetector(
                          onHorizontalDragUpdate: (details) {
                            if (_isBooked) return;
                            setState(() {
                              _swipeProgress += details.primaryDelta! / maxSlideDistance;
                              if (_swipeProgress < 0.0) _swipeProgress = 0.0;
                              if (_swipeProgress > 1.0) _swipeProgress = 1.0;
                            });
                          },
                          onHorizontalDragEnd: (details) {
                            if (_isBooked) return;
                            if (_swipeProgress >= 0.9) {
                              setState(() {
                                _swipeProgress = 1.0;
                              });
                              _onSwipeComplete();
                            } else {
                              setState(() {
                                _swipeProgress = 0.0;
                              });
                            }
                          },
                          child: Container(
                            width: sliderWidth,
                            height: 52,
                            decoration: BoxDecoration(
                              color: BrandColors.accent,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: BrandColors.accent.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                '➔',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    ThemeData theme, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: valueColor ?? theme.textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }
}
