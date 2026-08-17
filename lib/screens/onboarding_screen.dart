import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/brand_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Frictionless Local Discovery',
      'desc': 'Access local certified service operators itemized by background checks and upfront price models instantly.',
      'emoji': '🔍',
    },
    {
      'title': 'Transparent Fee Mechanics',
      'desc': 'No masked line items. Review explicit subtotal allocations containing real-time asset costs accurately.',
      'emoji': '🛡️',
    },
    {
      'title': 'Encrypted Safety Arrays',
      'desc': 'Lock details through protective swipe interaction guards engineered to avoid accidental bookings.',
      'emoji': '💳',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Discovery Guide',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: BrandColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              // Slide Content (PageView)
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Emoji Container
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: isDark ? BrandColors.accent.withOpacity(0.12) : const Color(0xFFE6F4F2),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: theme.dividerColor,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              slide['emoji']!,
                              style: const TextStyle(fontSize: 36),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          slide['title']!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            slide['desc']!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              // Page Indicators & Button
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (index) {
                      final isActive = index == _currentIndex;
                      return GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          width: isActive ? 20.0 : 8.0,
                          height: 8.0,
                          decoration: BoxDecoration(
                            color: isActive ? BrandColors.accent : theme.dividerColor,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentIndex < _slides.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          context.go('/login');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BrandColors.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: BrandColors.accent.withOpacity(0.3),
                      ),
                      child: Text(
                        _currentIndex == _slides.length - 1 ? 'Get Started' : 'Continue',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
