import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../network/services/socketService.dart';
import '../network/services/uploadService.dart';
import '../network/services/userService.dart';
import '../security/secureStorage.dart';
import '../state/app_state.dart';
import '../store/use_app_store.dart';
import '../theme/brand_theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(customerProfileProvider) == null) {
        _refreshProfile();
      }
    });
  }

  Future<void> _refreshProfile() async {
    try {
      final res = await ref.read(userServiceProvider).getUserProfile();
      final data = res.data;
      if (data is Map<String, dynamic> && data['user'] != null) {
        ref.read(customerProfileProvider.notifier).setProfile(data['user']);
      }
    } catch (_) {}
  }

  Future<void> _pickAndUploadProfilePhoto(
    ImageSource source, {
    void Function(void Function())? modalSetState,
    void Function(String newUrl)? onUploaded,
  }) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return; // User cancelled

      if (modalSetState != null) {
        modalSetState(() {});
      }
      setState(() => _isUploadingPhoto = true);

      // 1. Upload to S3 via backend /upload endpoint
      final uploadService = ref.read(uploadServiceProvider);
      final uploadResult = await uploadService.uploadFile(
        file: pickedFile,
        folder: 'avatars',
      );

      // 2. Persist new photo URL to user profile
      final userService = ref.read(userServiceProvider);
      final res = await userService.updateProfilePicture(uploadResult.url);

      // 3. Update cached state in Riverpod
      if (res.data is Map<String, dynamic> && res.data['user'] != null) {
        ref.read(customerProfileProvider.notifier).setProfile(res.data['user']);
      } else {
        await _refreshProfile();
      }

      if (onUploaded != null) {
        onUploaded(uploadResult.url);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Profile picture updated successfully!'),
            backgroundColor: BrandColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile picture: $e'),
            backgroundColor: BrandColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
      if (modalSetState != null) {
        modalSetState(() {});
      }
    }
  }

  void _showPhotoPickerActionSheet(
    BuildContext context, {
    void Function(void Function())? modalSetState,
    void Function(String newUrl)? onUploaded,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Update Profile Picture',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose an option to change your avatar image',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: BrandColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.photo_camera_rounded,
                      color: BrandColors.primary,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Take a Photo',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  subtitle: const Text(
                    'Use camera to capture a new photo',
                    style: TextStyle(fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();
                    _pickAndUploadProfilePhoto(
                      ImageSource.camera,
                      modalSetState: modalSetState,
                      onUploaded: onUploaded,
                    );
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: BrandColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: BrandColors.accent,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Choose from Gallery',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  subtitle: const Text(
                    'Select an existing image from your device',
                    style: TextStyle(fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.of(bottomSheetContext).pop();
                    _pickAndUploadProfilePhoto(
                      ImageSource.gallery,
                      modalSetState: modalSetState,
                      onUploaded: onUploaded,
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _promptOtpVerification({
    required BuildContext context,
    required String type, // 'email' or 'mobile'
    required String target,
  }) async {
    try {
      final userService = ref.read(userServiceProvider);
      if (type == 'email') {
        await userService.requestEmailUpdateOtp(target);
      } else {
        await userService.requestMobileUpdateOtp(target);
      }
    } catch (e) {
      if (context.mounted) {
        String errorMsg = 'Failed to send verification code';
        if (e is DioException && e.response?.data != null) {
          final data = e.response!.data;
          if (data is Map && data['message'] != null) {
            errorMsg = data['message'] is List
                ? (data['message'] as List).join(', ')
                : data['message'].toString();
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: BrandColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }

    if (!context.mounted) return false;

    // Open OTP Verification Sheet without blocking spinners
    final verified = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ProfileOtpVerificationSheet(
        type: type,
        target: target,
      ),
    );

    return verified == true;
  }

  void _showEditProfileModal(
    BuildContext context,
    Map<String, dynamic> userProfile,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController(
      text: userProfile['username']?.toString() ?? '',
    );
    String initialEmail = (userProfile['email']?.toString() ?? '').trim();
    String initialMobile = (userProfile['mobile']?.toString() ?? '').trim();
    bool isEmailVerified = userProfile['isEmailVerified'] == true;
    bool isPhoneVerified = userProfile['isPhoneVerified'] == true;

    final emailController = TextEditingController(
      text: initialEmail,
    );
    final mobileController = TextEditingController(
      text: initialMobile,
    );
    final addressController = TextEditingController(
      text: userProfile['address']?.toString() ?? '',
    );
    final ageController = TextEditingController(
      text: userProfile['age']?.toString() ?? '',
    );
    String selectedGender =
        (userProfile['gender']?.toString().toLowerCase() == 'female')
            ? 'female'
            : (userProfile['gender']?.toString().toLowerCase() == 'male')
            ? 'male'
            : (userProfile['gender']?.toString().toLowerCase() == 'other')
            ? 'other'
            : '';

    bool isSaving = false;
    String? currentModalPhoto = userProfile['photo']?.toString();
    final modalInitials = (userProfile['username']?.toString() ?? 'U').trim().isNotEmpty
        ? (userProfile['username']?.toString() ?? 'U')
            .trim()
            .split(' ')
            .where((s) => s.isNotEmpty)
            .map((s) => s[0])
            .take(2)
            .join()
            .toUpperCase()
        : 'U';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle pill
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: theme.dividerColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Edit Customer Profile',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Update your personal details & contact coordinates',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => Navigator.of(modalContext).pop(),
                            icon: const Icon(Icons.close_rounded, size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor: theme.dividerColor.withValues(
                                alpha: 0.3,
                              ),
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Profile Picture Preview & Change Action
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        BrandColors.primary,
                                        BrandColors.accent,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: (currentModalPhoto != null &&
                                            currentModalPhoto!.isNotEmpty)
                                        ? Image.network(
                                            currentModalPhoto!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Center(
                                              child: Text(
                                                modalInitials,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              modalInitials,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                if (_isUploadingPhoto)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextButton.icon(
                              onPressed: _isUploadingPhoto
                                  ? null
                                  : () => _showPhotoPickerActionSheet(
                                        modalContext,
                                        modalSetState: setModalState,
                                        onUploaded: (url) {
                                          setModalState(() {
                                            currentModalPhoto = url;
                                          });
                                        },
                                      ),
                              icon: const Icon(
                                Icons.camera_alt_outlined,
                                size: 16,
                                color: BrandColors.primary,
                              ),
                              label: const Text(
                                'Change Profile Photo',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: BrandColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Full Name / Username
                      Text(
                        'FULL NAME / DISPLAY NAME',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyMedium?.color,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: usernameController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Display name cannot be empty';
                          }
                          if (value.trim().length < 3) {
                            return 'Name must be at least 3 characters';
                          }
                          if (value.trim().length > 30) {
                            return 'Name cannot exceed 30 characters';
                          }
                          return null;
                        },
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Enter your full name',
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: theme.cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Email Address
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'EMAIL ADDRESS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyMedium?.color,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              final currentText =
                                  emailController.text.trim().toLowerCase();
                              final hasChanged =
                                  currentText != initialEmail.toLowerCase();
                              final isVerified = !hasChanged && isEmailVerified;

                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          (isVerified
                                                  ? BrandColors.success
                                                  : BrandColors.warning)
                                              .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isVerified
                                              ? Icons.check_circle
                                              : Icons.schedule,
                                          size: 10,
                                          color: isVerified
                                              ? BrandColors.success
                                              : BrandColors.warning,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          isVerified
                                              ? 'Verified'
                                              : hasChanged
                                              ? 'Requires OTP'
                                              : 'Pending',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: isVerified
                                                ? BrandColors.success
                                                : BrandColors.warning,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isVerified &&
                                      currentText.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () async {
                                        final emailRegex = RegExp(
                                          r'^[^@]+@[^@]+\.[^@]+$',
                                        );
                                        if (!emailRegex.hasMatch(currentText)) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Please enter a valid email address first',
                                              ),
                                              backgroundColor: BrandColors.danger,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                          return;
                                        }
                                        final ok = await _promptOtpVerification(
                                          context: modalContext,
                                          type: 'email',
                                          target: currentText,
                                        );
                                        if (ok) {
                                          setModalState(() {
                                            initialEmail = currentText;
                                            isEmailVerified = true;
                                          });
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  '✓ Email verified successfully!',
                                                ),
                                                backgroundColor:
                                                    BrandColors.success,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: BrandColors.primary.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: BrandColors.primary.withValues(
                                              alpha: 0.3,
                                            ),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: const Text(
                                          'Verify with OTP',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: BrandColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) => setModalState(() {}),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email address cannot be empty';
                          }
                          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'customer@example.com',
                          prefixIcon: const Icon(Icons.email_outlined, size: 18),
                          filled: true,
                          fillColor: theme.cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Contact Mobile Phone
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'CONTACT MOBILE NUMBER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyMedium?.color,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              final currentText = mobileController.text.trim();
                              final hasChanged = currentText != initialMobile;
                              final isVerified = !hasChanged && isPhoneVerified;

                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          (isVerified
                                                  ? BrandColors.success
                                                  : BrandColors.warning)
                                              .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isVerified
                                              ? Icons.check_circle
                                              : Icons.schedule,
                                          size: 10,
                                          color: isVerified
                                              ? BrandColors.success
                                              : BrandColors.warning,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          isVerified
                                              ? 'Verified'
                                              : hasChanged
                                              ? 'Requires OTP'
                                              : 'Pending',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: isVerified
                                                ? BrandColors.success
                                                : BrandColors.warning,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isVerified &&
                                      currentText.isNotEmpty) ...[
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () async {
                                        final clean = currentText.replaceAll(
                                          RegExp(r'[\s-]'),
                                          '',
                                        );
                                        if (clean.length < 10 ||
                                            clean.length > 15) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Please enter a valid mobile number (10-15 digits)',
                                              ),
                                              backgroundColor: BrandColors.danger,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                          return;
                                        }
                                        final ok = await _promptOtpVerification(
                                          context: modalContext,
                                          type: 'mobile',
                                          target: currentText,
                                        );
                                        if (ok) {
                                          setModalState(() {
                                            initialMobile = currentText;
                                            isPhoneVerified = true;
                                          });
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  '✓ Mobile number verified successfully!',
                                                ),
                                                backgroundColor:
                                                    BrandColors.success,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: BrandColors.primary.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: BrandColors.primary.withValues(
                                              alpha: 0.3,
                                            ),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: const Text(
                                          'Verify with OTP',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: BrandColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: mobileController,
                        keyboardType: TextInputType.phone,
                        onChanged: (_) => setModalState(() {}),
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final clean = value.trim().replaceAll(
                              RegExp(r'[\s-]'),
                              '',
                            );
                            if (clean.length < 10 || clean.length > 15) {
                              return 'Mobile number must be 10-15 digits';
                            }
                          }
                          return null;
                        },
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'e.g. +1234567890 or 9876543210',
                          prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                          filled: true,
                          fillColor: theme.cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Primary Address
                      Text(
                        'PRIMARY DELIVERY / BILLING ADDRESS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.bodyMedium?.color,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: addressController,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'e.g. 104 Sector 4, Metro Residence',
                          prefixIcon: const Icon(
                            Icons.location_on_outlined,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: theme.cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.dividerColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Gender & Age Row
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'GENDER',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodyMedium?.color,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.dividerColor,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: selectedGender.isNotEmpty
                                          ? selectedGender
                                          : null,
                                      hint: Text(
                                        'Select',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              theme.textTheme.bodyMedium?.color,
                                        ),
                                      ),
                                      dropdownColor: theme.cardColor,
                                      isExpanded: true,
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'male',
                                          child: Text(
                                            'Male',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'female',
                                          child: Text(
                                            'Female',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'other',
                                          child: Text(
                                            'Other',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                      onChanged: (val) {
                                        setModalState(() {
                                          selectedGender = val ?? '';
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AGE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodyMedium?.color,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: ageController,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value != null &&
                                        value.trim().isNotEmpty) {
                                      final ageVal = int.tryParse(value.trim());
                                      if (ageVal == null ||
                                          ageVal < 18 ||
                                          ageVal > 100) {
                                        return '18-100';
                                      }
                                    }
                                    return null;
                                  },
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'Age',
                                    filled: true,
                                    fillColor: theme.cardColor,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: theme.dividerColor,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: theme.dividerColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (formKey.currentState?.validate() ??
                                      false) {
                                    final newEmail = emailController.text
                                        .trim()
                                        .toLowerCase();
                                    final newMobile =
                                        mobileController.text.trim();

                                    // Verify email with OTP if changed or unverified
                                    if (newEmail.isNotEmpty &&
                                        (newEmail !=
                                                initialEmail.toLowerCase() ||
                                            !isEmailVerified)) {
                                      final emailOk =
                                          await _promptOtpVerification(
                                            context: modalContext,
                                            type: 'email',
                                            target: newEmail,
                                          );
                                      if (!emailOk) return;
                                      initialEmail = newEmail;
                                      isEmailVerified = true;
                                    }

                                    // Verify mobile with OTP if changed or unverified
                                    if (newMobile.isNotEmpty &&
                                        (newMobile != initialMobile ||
                                            !isPhoneVerified)) {
                                      if (!modalContext.mounted) return;
                                      final mobileOk =
                                          await _promptOtpVerification(
                                            context: modalContext,
                                            type: 'mobile',
                                            target: newMobile,
                                          );
                                      if (!mobileOk) return;
                                      initialMobile = newMobile;
                                      isPhoneVerified = true;
                                    }

                                    setModalState(() => isSaving = true);
                                    try {
                                      final payload = <String, dynamic>{
                                        'username':
                                            usernameController.text.trim(),
                                      };

                                      final address =
                                          addressController.text.trim();
                                      if (address.isNotEmpty) {
                                        payload['address'] = address;
                                      }

                                      if (selectedGender.isNotEmpty) {
                                        payload['gender'] = selectedGender;
                                      }

                                      final ageText = ageController.text.trim();
                                      if (ageText.isNotEmpty) {
                                        final parsedAge = int.tryParse(ageText);
                                        if (parsedAge != null) {
                                          payload['age'] = parsedAge;
                                        }
                                      }

                                      final userService = ref.read(
                                        userServiceProvider,
                                      );
                                      final res = await userService
                                          .updateUserProfile(payload);

                                      if (res.data is Map<String, dynamic> &&
                                          res.data['user'] != null) {
                                        ref
                                            .read(
                                              customerProfileProvider.notifier,
                                            )
                                            .setProfile(res.data['user']);
                                      } else {
                                        await _refreshProfile();
                                      }

                                      if (modalContext.mounted) {
                                        Navigator.of(modalContext).pop();
                                      }
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              '✓ Customer profile updated successfully!',
                                            ),
                                            backgroundColor: BrandColors.success,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setModalState(() => isSaving = false);
                                      if (context.mounted) {
                                        String msg =
                                            'Failed to update profile: $e';
                                        if (e is DioException &&
                                            e.response?.data != null) {
                                          final d = e.response!.data;
                                          if (d is Map &&
                                              d['message'] != null) {
                                            msg = d['message'] is List
                                                ? (d['message'] as List).join(
                                                    ', ',
                                                  )
                                                : d['message'].toString();
                                          }
                                        }
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(msg),
                                            backgroundColor: BrandColors.danger,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BrandColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customerProfile = ref.watch(customerProfileProvider);
    final customerAddresses = ref.watch(customerAddressProvider);

    final userData = customerProfile ?? <String, dynamic>{};
    final username = userData['username']?.toString() ?? 'User Profile';
    final email = userData['email']?.toString() ?? 'Not configured';
    final mobile = userData['mobile']?.toString() ?? 'Not configured';
    final address = userData['address']?.toString() ?? 'No address configured';
    final photoUrl = userData['photo']?.toString();
    final bool isEmailVerified = userData['isEmailVerified'] == true;
    final bool isPhoneVerified = userData['isPhoneVerified'] == true;

    final initials = username.trim().isNotEmpty
        ? username
            .trim()
            .split(' ')
            .where((s) => s.isNotEmpty)
            .map((s) => s[0])
            .take(2)
            .join()
            .toUpperCase()
        : 'U';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Customer Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Profile',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshProfile,
          ),
        ],
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListenableBuilder(
        listenable: AppState(),
        builder: (context, _) {
          final appState = AppState();

          return RefreshIndicator(
            onRefresh: _refreshProfile,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 6),

                  // Avatar with Photo Upload & Camera Action Badge
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [BrandColors.primary, BrandColors.accent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: BrandColors.primary.withValues(alpha: 0.2),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: ClipOval(
                              child: Container(
                                color: theme.cardColor,
                                child: (photoUrl != null && photoUrl.isNotEmpty)
                                    ? Image.network(
                                        photoUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Center(
                                          child: Text(
                                            initials.isNotEmpty ? initials : 'U',
                                            style: const TextStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.bold,
                                              color: BrandColors.accent,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          initials.isNotEmpty ? initials : 'U',
                                          style: const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: BrandColors.accent,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        if (_isUploadingPhoto)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: -2,
                          child: InkWell(
                            onTap: _isUploadingPhoto
                                ? null
                                : () => _showPhotoPickerActionSheet(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: BrandColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.cardColor,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Display Name
                  Text(
                    username,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Membership Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: BrandColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'VERIFIED CUSTOMER ACCOUNT',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: BrandColors.accent,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Primary Edit Profile Action Button
                  SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: () => _showEditProfileModal(context, userData),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text(
                        'Edit Profile',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: BrandColors.primary,
                        side: const BorderSide(color: BrandColors.primary, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Identity & Contact Information Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PERSONAL & CONTACT INFORMATION',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyMedium?.color,
                                letterSpacing: 0.5,
                              ),
                            ),
                            InkWell(
                              onTap: () =>
                                  _showEditProfileModal(context, userData),
                              child: const Text(
                                'Edit Info',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: BrandColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _buildInfoRow(
                          theme: theme,
                          icon: Icons.person_outline,
                          label: 'Full Name',
                          value: username,
                        ),
                        const Divider(height: 18),
                        _buildInfoRow(
                          theme: theme,
                          icon: Icons.email_outlined,
                          label: 'Email Gateway',
                          value: email,
                          verified: isEmailVerified,
                          onVerifyTap: isEmailVerified
                              ? null
                              : () async {
                                  final ok = await _promptOtpVerification(
                                    context: context,
                                    type: 'email',
                                    target: email,
                                  );
                                  if (ok && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          '✓ Email verified successfully!',
                                        ),
                                        backgroundColor: BrandColors.success,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                        ),
                        const Divider(height: 18),
                        _buildInfoRow(
                          theme: theme,
                          icon: Icons.phone_android_outlined,
                          label: 'Contact Mobile',
                          value: mobile,
                          verified: isPhoneVerified,
                          onVerifyTap: isPhoneVerified ||
                                  mobile == 'Not configured' ||
                                  mobile.isEmpty
                              ? null
                              : () async {
                                  final ok = await _promptOtpVerification(
                                    context: context,
                                    type: 'mobile',
                                    target: mobile,
                                  );
                                  if (ok && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          '✓ Mobile number verified successfully!',
                                        ),
                                        backgroundColor: BrandColors.success,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                        ),
                        const Divider(height: 18),
                        _buildInfoRow(
                          theme: theme,
                          icon: Icons.location_on_outlined,
                          label: 'Primary Delivery Address',
                          value: address,
                        ),
                        if (userData['gender'] != null ||
                            userData['age'] != null) ...[
                          const Divider(height: 18),
                          _buildInfoRow(
                            theme: theme,
                            icon: Icons.badge_outlined,
                            label: 'Demographics',
                            value: [
                              if (userData['gender'] != null)
                                'Gender: ${userData['gender']}',
                              if (userData['age'] != null)
                                'Age: ${userData['age']}',
                            ].join(' • '),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Preferences & Account Settings List
                  Material(
                    color: theme.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: theme.dividerColor),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // Appearance Theme Selector Dropdown
                        ListTile(
                          leading: const Icon(
                            Icons.palette_outlined,
                            size: 18,
                            color: BrandColors.accent,
                          ),
                          title: const Text(
                            'Appearance Theme',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: DropdownButtonHideUnderline(
                            child: DropdownButton<ThemeMode>(
                              value: appState.currentThemeMode,
                              dropdownColor: theme.cardColor,
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: theme.textTheme.bodyMedium?.color,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: ThemeMode.system,
                                  child: Text(
                                    'System',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: ThemeMode.light,
                                  child: Text(
                                    'Light',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: ThemeMode.dark,
                                  child: Text(
                                    'Dark',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
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
                          trailingText:
                              '${customerAddresses?.length ?? 0} saved',
                          theme: theme,
                          onTap: () => context.push('/addresses'),
                        ),
                        Divider(height: 1, color: theme.dividerColor),
                        // Encrypted Payment Modules
                        _buildProfileOption(
                          leadingIcon: Icons.payment_outlined,
                          title: 'Encrypted Payment Modules',
                          trailingText: 'Active',
                          theme: theme,
                        ),
                        Divider(height: 1, color: theme.dividerColor),
                        // Trust & Help Support
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

                  // Logout Button
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
                        side: BorderSide(
                          color: BrandColors.danger.withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Terminate Session Logout',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: BrandColors.danger,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
    bool? verified,
    VoidCallback? onVerifyTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: BrandColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (verified != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (verified ? BrandColors.success : BrandColors.warning)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  verified ? Icons.check_circle : Icons.schedule,
                  size: 10,
                  color: verified ? BrandColors.success : BrandColors.warning,
                ),
                const SizedBox(width: 3),
                Text(
                  verified ? 'Verified' : 'Pending',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: verified ? BrandColors.success : BrandColors.warning,
                  ),
                ),
              ],
            ),
          ),
          if (!verified && onVerifyTap != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: onVerifyTap,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: BrandColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: BrandColors.primary.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: const Text(
                  'Verify',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: BrandColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ],
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

class _ProfileOtpVerificationSheet extends ConsumerStatefulWidget {
  final String type; // 'email' or 'mobile'
  final String target;

  const _ProfileOtpVerificationSheet({
    required this.type,
    required this.target,
  });

  @override
  ConsumerState<_ProfileOtpVerificationSheet> createState() =>
      _ProfileOtpVerificationSheetState();
}

class _ProfileOtpVerificationSheetState
    extends ConsumerState<_ProfileOtpVerificationSheet> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _countdown = 60;
  Timer? _timer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
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

  Future<void> _handleResend() async {
    if (_countdown > 0) return;
    setState(() {
      _errorMessage = null;
    });
    try {
      final userService = ref.read(userServiceProvider);
      if (widget.type == 'email') {
        await userService.requestEmailUpdateOtp(widget.target);
      } else {
        await userService.requestMobileUpdateOtp(widget.target);
      }
      _startCountdown(60);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ New verification code sent'),
            backgroundColor: BrandColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      String msg = 'Failed to resend code';
      if (e is DioException && e.response?.data != null) {
        final d = e.response!.data;
        if (d is Map && d['message'] != null) {
          msg = d['message'] is List
              ? (d['message'] as List).join(', ')
              : d['message'].toString();
        }
      }
      setState(() {
        _errorMessage = msg;
      });
    }
  }

  Future<void> _handleVerify() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Please enter the full 6-digit code';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    try {
      final userService = ref.read(userServiceProvider);
      Response res;
      if (widget.type == 'email') {
        res = await userService.verifyEmailUpdateOtp(widget.target, code);
      } else {
        res = await userService.verifyMobileUpdateOtp(widget.target, code);
      }

      if (res.data is Map<String, dynamic> && res.data['user'] != null) {
        ref.read(customerProfileProvider.notifier).setProfile(res.data['user']);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      String msg = 'Invalid verification code. Please check and try again.';
      if (e is DioException && e.response?.data != null) {
        final d = e.response!.data;
        if (d is Map && d['message'] != null) {
          msg = d['message'] is List
              ? (d['message'] as List).join(', ')
              : d['message'].toString();
        }
      }
      setState(() {
        _errorMessage = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEmail = widget.type == 'email';

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 20,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Pill
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Icon badge
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: BrandColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isEmail
                    ? Icons.mark_email_read_outlined
                    : Icons.phone_android_outlined,
                color: BrandColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 14),

            // Title
            Text(
              isEmail ? 'Verify Email Address' : 'Verify Mobile Number',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter the 6-digit code sent to',
              style: TextStyle(
                fontSize: 12,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.target,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: BrandColors.primary,
              ),
            ),
            const SizedBox(height: 24),

            // OTP 6-box input
            Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: 0.0,
                  child: TextField(
                    controller: _otpController,
                    focusNode: _focusNode,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (val) {
                      setState(() {
                        if (_errorMessage != null) _errorMessage = null;
                      });
                      if (val.length == 6) {
                        _handleVerify();
                      }
                    },
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _focusNode.requestFocus(),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      final text = _otpController.text;
                      final isEntered = index < text.length;
                      final isFocused =
                          _focusNode.hasFocus && index == text.length;
                      final digit = isEntered ? text[index] : '';

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 44,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isEntered
                              ? (isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF1F5F9))
                              : theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _errorMessage != null
                                ? BrandColors.danger
                                : isFocused
                                    ? BrandColors.primary
                                    : isEntered
                                        ? BrandColors.primary.withValues(
                                            alpha: 0.5,
                                          )
                                        : theme.dividerColor,
                            width: isFocused ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          digit,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: BrandColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 14,
                      color: BrandColors.danger,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: BrandColors.danger,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Resend section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Didn't receive the code? ",
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
                if (_countdown > 0)
                  Text(
                    'Resend in ${_countdown}s',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: BrandColors.primary,
                    ),
                  )
                else
                  TextButton(
                    onPressed: _handleResend,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Resend Code',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: BrandColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Actions: Verify Button and Cancel
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _handleVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Verify & Confirm',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
