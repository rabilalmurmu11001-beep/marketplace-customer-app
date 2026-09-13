import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../network/services/socketService.dart';
import '../security/secureStorage.dart';
import '../theme/brand_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Animation states
  bool _logoAnimated = false;
  bool _textAnimated = false;

  @override
  void initState() {
    super.initState();
    _startAnimationsAndNavigation();
  }

  Future<void> _startAnimationsAndNavigation() async {
    // 1. Trigger Logo scale & pop
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() => _logoAnimated = true);

    // 2. Trigger Text fade-in slightly after
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _textAnimated = true);

    // 3. Wait for the remainder of the splash time, then check auth
    await Future.delayed(const Duration(milliseconds: 1500));
    _checkTokenAndNavigate();
  }

  Future<void> _checkTokenAndNavigate() async {
    if (!mounted) return;

    try {
      final token = await TokenRepository().readToken();
      if (token != null && token.isNotEmpty) {
        SocketService.instance.connect(token);
        if (mounted) context.go('/home');
      } else {
        if (mounted) context.go('/onboarding');
      }
    } catch (_) {
      if (mounted) context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient Mesh
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  BrandColors.accent.withValues(alpha: isDark ? 0.15 : 0.08),
                  theme.scaffoldBackgroundColor,
                ],
              ),
            ),
          ),

          // Ambient Glow Circle behind the logo
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            left: MediaQuery.of(context).size.width * 0.15,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 1000),
              opacity: _logoAnimated ? 1.0 : 0.0,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BrandColors.accent.withValues(
                    alpha: isDark ? 0.15 : 0.06,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: BrandColors.accent.withValues(
                        alpha: isDark ? 0.25 : 0.12,
                      ),
                      blurRadius: 120,
                      spreadRadius: 30,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Central Animated Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Premium Brand Logo Container
                AnimatedScale(
                  scale: _logoAnimated ? 1.0 : 0.6,
                  duration: const Duration(milliseconds: 800),
                  curve:
                      Curves.elasticOut, // Gives that premium, organic bounce
                  child: AnimatedOpacity(
                    opacity: _logoAnimated ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          colors: [BrandColors.primary, BrandColors.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: BrandColors.accent.withValues(alpha: 0.4),
                            blurRadius: 40,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'P',
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Animated Text Elements
                AnimatedOpacity(
                  opacity: _textAnimated ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 600),
                  child: AnimatedSlide(
                    offset: _textAnimated ? Offset.zero : const Offset(0, 0.2),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    child: Column(
                      children: [
                        Text(
                          'ProtoServe',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontSize: 34,
                            letterSpacing: -1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Premium Local Service Network',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: BrandColors.accent,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Subtle Bottom Loading indicator (Optional, replaces the manual button)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: _textAnimated ? 0.7 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      BrandColors.accent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
