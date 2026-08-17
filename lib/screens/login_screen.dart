import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../network/services/authServices.dart';
import '../theme/brand_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: 'emma.watson@gmail.com');
  final _passwordController = TextEditingController(text: 'password123');
  final _phoneController = TextEditingController(text: '+1 (555) 234-5678');
  final _otpController = TextEditingController();

  bool _isEmail = true;
  bool _isPassword = true;
  bool _obscurePassword = true;
  bool _otpSent = false;
  bool _isLoading = false;
  int _countdown = 0;
  Timer? _timer;
  String identifireToken = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _otpSent = true;
      _countdown = 30;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 0) {
        timer.cancel();
      } else {
        setState(() {
          _countdown--;
        });
      }
    });
  }

  void _sendOtp() async {
    final identifier = _isEmail ? _emailController.text : _phoneController.text;
    if (identifier.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter your ${_isEmail ? 'email address' : 'mobile number'} first.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final res = await authService.requestOtp(identifier);

      if (mounted) {
        setState(() {
          _isLoading = false;
          identifireToken = res.data["otpToken"];
        });
        _startCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res.data['message'] ?? 'Security code sent successfully.',
            ),
            backgroundColor: BrandColors.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        String errorMsg = 'Failed to send OTP. Please check your credentials.';
        if (e is DioException) {
          final data = e.response?.data;
          if (data is Map) {
            errorMsg = data['message'] ?? e.message ?? errorMsg;
          } else if (data is String && data.isNotEmpty) {
            if (data.contains('<!DOCTYPE html>') || data.contains('<html')) {
              errorMsg = e.message ?? errorMsg;
            } else {
              errorMsg = data;
            }
          } else {
            errorMsg = e.message ?? errorMsg;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _handleLogin() async {
    final identifier = _isEmail ? _emailController.text : _phoneController.text;
    final secret = _isPassword ? _passwordController.text : _otpController.text;

    if (identifier.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter your ${_isEmail ? 'email address' : 'mobile number'}.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (secret.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter your ${_isPassword ? 'password' : 'one-time passcode'}.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      if (_isPassword) {
        if (_isEmail) {
          await authService.emaillogin(identifier, secret);
        } else {
          await authService.phonelogin(identifier, secret);
        }
      } else {
        await authService.verifyOtp(identifireToken, secret);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        String errorMsg = 'Authentication failed. Please verify credentials.';
        if (e is DioException) {
          final data = e.response?.data;
          if (data is Map) {
            errorMsg = data['message'] ?? e.message ?? errorMsg;
          } else if (data is String && data.isNotEmpty) {
            if (data.contains('<!DOCTYPE html>') || data.contains('<html')) {
              errorMsg = e.message ?? errorMsg;
            } else {
              errorMsg = data;
            }
          } else {
            errorMsg = e.message ?? errorMsg;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Widget _buildSegmentedControl<T>({
    required List<T> values,
    required List<String> labels,
    required List<IconData> icons,
    required T selectedValue,
    required ValueChanged<T> onSelected,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: List.generate(values.length, (index) {
          final isSelected = values[index] == selectedValue;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(values[index]),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                            ? BrandColors.accent.withValues(alpha: 0.12)
                            : const Color(0xFFE6F4F2))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? Border.all(
                          color: BrandColors.accent.withValues(alpha: 0.2),
                        )
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icons[index],
                      size: 14,
                      color: isSelected
                          ? BrandColors.accent
                          : theme.textTheme.bodyMedium?.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      labels[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? BrandColors.accent
                            : theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Welcome Guest ✨',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to initialize secure operations.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 32),

                      // Segmented selectors
                      const Text(
                        'IDENTIFIER ENDPOINT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSegmentedControl<bool>(
                        values: [true, false],
                        labels: ['Email Address', 'Mobile Number'],
                        icons: [
                          Icons.email_outlined,
                          Icons.phone_android_outlined,
                        ],
                        selectedValue: _isEmail,
                        onSelected: (val) => setState(() => _isEmail = val),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'SECURITY CREDENTIAL TYPE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSegmentedControl<bool>(
                        values: [true, false],
                        labels: ['Security Password', 'One-Time Passcode'],
                        icons: [Icons.lock_outline, Icons.sms_outlined],
                        selectedValue: _isPassword,
                        onSelected: (val) => setState(() => _isPassword = val),
                      ),

                      const SizedBox(height: 32),

                      // Credentials form fields
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Identifier Field (Email or Mobile)
                          Text(
                            _isEmail
                                ? 'ACCOUNT EMAIL ENDPOINT'
                                : 'MOBILE SECURE NUMBER',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _isEmail
                                ? _emailController
                                : _phoneController,
                            keyboardType: _isEmail
                                ? TextInputType.emailAddress
                                : TextInputType.phone,
                            enabled: !_isLoading,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: theme.cardColor,
                              hintText: _isEmail
                                  ? 'Enter your email'
                                  : 'Enter phone number',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: theme.dividerColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: BrandColors.accent,
                                ),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: theme.dividerColor.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Verification Field (Password or OTP)
                          Text(
                            _isPassword
                                ? 'PASSWORD SECURITY TOKEN'
                                : 'ONE-TIME PASSCODE (OTP)',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _isPassword
                                ? _passwordController
                                : _otpController,
                            obscureText: _isPassword ? _obscurePassword : false,
                            keyboardType: _isPassword
                                ? TextInputType.visiblePassword
                                : TextInputType.number,
                            enabled: !_isLoading,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: theme.cardColor,
                              hintText: _isPassword
                                  ? '••••••••'
                                  : 'Enter 6-digit code',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: theme.dividerColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: BrandColors.accent,
                                ),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: theme.dividerColor.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              suffixIcon: _isPassword
                                  ? IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 18,
                                        color:
                                            theme.textTheme.bodyMedium?.color,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    )
                                  : Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8.0,
                                      ),
                                      child: TextButton(
                                        onPressed:
                                            (_isLoading || _countdown > 0)
                                            ? null
                                            : _sendOtp,
                                        child: Text(
                                          _countdown > 0
                                              ? 'Resend (${_countdown}s)'
                                              : (_otpSent
                                                    ? 'Resend'
                                                    : 'Send Code'),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                (_isLoading || _countdown > 0)
                                                ? theme.disabledColor
                                                : BrandColors.accent,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),
                      const SizedBox(height: 32),

                      // Action Buttons
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: BrandColors.accent,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: BrandColors.accent
                                    .withValues(alpha: 0.6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                                shadowColor: BrandColors.accent.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Authorize Access',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'New client? ',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                              GestureDetector(
                                onTap: _isLoading
                                    ? null
                                    : () {
                                        context.go('/signup');
                                      },
                                child: const Text(
                                  'Register Here',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: BrandColors.accent,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
