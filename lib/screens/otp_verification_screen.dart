import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../network/services/authServices.dart';
import '../network/services/socketService.dart';
import '../store/use_app_store.dart';
import '../theme/brand_theme.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String? signupToken;
  final String email;
  final String? mobile;
  final bool requiresPhoneVerification;

  const OtpVerificationScreen({
    super.key,
    this.signupToken,
    required this.email,
    this.mobile,
    this.requiresPhoneVerification = false,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final TextEditingController _emailOtpController = TextEditingController();
  final TextEditingController _phoneOtpController = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isResending = false;
  bool _isEmailVerified = false;
  bool _isPhoneVerified = false;

  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _emailOtpController.dispose();
    _phoneOtpController.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown([int seconds = 60]) {
    setState(() {
      _countdown = seconds;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown <= 1) {
        timer.cancel();
        setState(() {
          _countdown = 0;
        });
      } else {
        setState(() {
          _countdown--;
        });
      }
    });
  }

  Future<void> _handleResendOtp({String type = 'all'}) async {
    if (_countdown > 0 || _isResending) return;

    setState(() {
      _isResending = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final res = await authService.resendSignupOtp(
        signupToken: widget.signupToken,
        email: widget.email,
        type: type,
      );

      if (mounted) {
        setState(() {
          _isResending = false;
        });
        _startCountdown(60);

        final message = res.data is Map && res.data['message'] != null
            ? res.data['message']
            : 'Verification code resent successfully.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: BrandColors.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
        String errorMsg = 'Failed to resend verification code.';
        if (e is DioException) {
          final data = e.response?.data;
          if (data is Map && data['message'] != null) {
            errorMsg = data['message'].toString();
          } else if (e.message != null) {
            errorMsg = e.message!;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _handleVerify() async {
    final emailOtp = _emailOtpController.text.trim();
    final phoneOtp = _phoneOtpController.text.trim();

    // Validation
    if (!_isEmailVerified && emailOtp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 6-digit email verification code.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      _emailFocusNode.requestFocus();
      return;
    }

    if (widget.requiresPhoneVerification &&
        !_isPhoneVerified &&
        phoneOtp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 6-digit mobile verification code.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      _phoneFocusNode.requestFocus();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final res = await authService.verifySignupOtp(
        signupToken: widget.signupToken,
        email: widget.email,
        emailOtp: _isEmailVerified ? null : emailOtp,
        phoneOtp: (!widget.requiresPhoneVerification || _isPhoneVerified)
            ? null
            : phoneOtp,
      );

      final data = res.data is Map ? res.data : <String, dynamic>{};
      final bool isFullyVerified = data['verified'] == true;

      if (isFullyVerified) {
        // Socket connection and profile update
        final String? token = data['token'];
        if (token != null) {
          await ref.read(socketServiceProvider).connect(token);
        }

        if (data['user'] is Map<String, dynamic>) {
          ref
              .read(customerProfileProvider.notifier)
              .setProfile(data['user'] as Map<String, dynamic>);
        }

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account verified and registered successfully!'),
              backgroundColor: BrandColors.accent,
            ),
          );
          context.go('/home');
        }
      } else {
        // Partial verification state (e.g., email verified, phone still pending)
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isEmailVerified = data['emailVerified'] == true;
            _isPhoneVerified = data['phoneVerified'] == true;
          });

          final message = data['message'] ??
              'Partial verification complete. Please enter the remaining code.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: BrandColors.accent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        String errorMsg = 'Verification failed. Please check the code.';
        if (e is DioException) {
          final data = e.response?.data;
          if (data is Map && data['message'] != null) {
            errorMsg = data['message'].toString();
          } else if (e.message != null) {
            errorMsg = e.message!;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMobile = widget.requiresPhoneVerification &&
        widget.mobile != null &&
        widget.mobile!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: theme.textTheme.titleLarge?.color,
          ),
          onPressed: _isLoading ? null : () => context.pop(),
        ),
        title: Text(
          'Verification',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Security Badge Icon & Header
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: BrandColors.accent.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_user_rounded,
                            size: 32,
                            color: BrandColors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Center(
                        child: Text(
                          hasMobile ? 'Verify Email & Mobile' : 'Verify Email Address',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Center(
                        child: Text(
                          hasMobile
                              ? 'Enter the 6-digit verification codes sent to your registered email and mobile number.'
                              : 'Enter the 6-digit verification code sent to your registered email address.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Email OTP Section
                      _buildOtpSection(
                        title: 'EMAIL VERIFICATION CODE',
                        destination: widget.email,
                        icon: Icons.email_outlined,
                        controller: _emailOtpController,
                        focusNode: _emailFocusNode,
                        isVerified: _isEmailVerified,
                        theme: theme,
                      ),

                      // Mobile OTP Section (Only visible if mobile is provided)
                      if (hasMobile) ...[
                        const SizedBox(height: 24),
                        _buildOtpSection(
                          title: 'MOBILE SMS CODE',
                          destination: widget.mobile!,
                          icon: Icons.phone_android_rounded,
                          controller: _phoneOtpController,
                          focusNode: _phoneFocusNode,
                          isVerified: _isPhoneVerified,
                          theme: theme,
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Resend Code Section
                      _buildResendSection(theme, hasMobile),

                      const Spacer(),
                      const SizedBox(height: 32),

                      // Submit Verification Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleVerify,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BrandColors.accent,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                BrandColors.accent.withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor:
                                BrandColors.accent.withValues(alpha: 0.3),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.2,
                                  ),
                                )
                              : const Text(
                                  'Verify & Complete Registration',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Back to Edit Info
                      Center(
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  context.pop();
                                },
                          child: Text(
                            'Entered wrong details? Change them',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              color: BrandColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
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

  Widget _buildOtpSection({
    required String title,
    required String destination,
    required IconData icon,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isVerified,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isVerified
              ? Colors.green.withValues(alpha: 0.5)
              : theme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: BrandColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (isVerified)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 13, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            destination,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          if (isVerified)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Code successfully verified ✓',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
            )
          else
            _PinCodeInputField(
              controller: controller,
              focusNode: focusNode,
              length: 6,
              theme: theme,
              onChanged: (_) {
                setState(() {});
              },
            ),
        ],
      ),
    );
  }

  Widget _buildResendSection(ThemeData theme, bool hasMobile) {
    return Center(
      child: Column(
        children: [
          if (_countdown > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: theme.textTheme.bodyMedium?.color,
                ),
                const SizedBox(width: 6),
                Text(
                  'Resend code in ${_countdown.toString().padLeft(2, '0')}s',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ] else ...[
            if (_isResending)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: BrandColors.accent,
                ),
              )
            else
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () => _handleResendOtp(type: 'all'),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(
                      hasMobile ? 'Resend All Codes' : 'Resend Code',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: BrandColors.accent,
                    ),
                  ),
                  if (hasMobile) ...[
                    if (!_isEmailVerified)
                      TextButton(
                        onPressed: () => _handleResendOtp(type: 'email'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.textTheme.bodyMedium?.color,
                        ),
                        child: const Text(
                          'Resend Email Only',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    if (!_isPhoneVerified)
                      TextButton(
                        onPressed: () => _handleResendOtp(type: 'phone'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.textTheme.bodyMedium?.color,
                        ),
                        child: const Text(
                          'Resend SMS Only',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _PinCodeInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final ThemeData theme;
  final ValueChanged<String>? onChanged;

  const _PinCodeInputField({
    required this.controller,
    required this.focusNode,
    required this.length,
    required this.theme,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Invisible input capturing keystrokes and paste events
        Opacity(
          opacity: 0.0,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            maxLength: length,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: onChanged,
            showCursor: false,
            enableInteractiveSelection: true,
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),

        // Visual digit boxes
        GestureDetector(
          onTap: () => focusNode.requestFocus(),
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(length, (index) {
              final text = controller.text;
              final isEntered = index < text.length;
              final isFocused = focusNode.hasFocus && index == text.length;
              final digit = isEntered ? text[index] : '';

              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 44,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isEntered
                      ? BrandColors.accent.withValues(alpha: 0.06)
                      : theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFocused
                        ? BrandColors.accent
                        : isEntered
                            ? BrandColors.accent.withValues(alpha: 0.4)
                            : theme.dividerColor,
                    width: isFocused ? 1.8 : 1.0,
                  ),
                ),
                child: Text(
                  digit,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: BrandColors.accent,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
