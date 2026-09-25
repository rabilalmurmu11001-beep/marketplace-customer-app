import 'package:customer_app/network/api.dart';
import 'package:customer_app/network/services/socketService.dart';
import 'package:customer_app/network/services/notification_service.dart';
import 'package:customer_app/security/secureStorage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A template for creating services that use the Dio instance.
final authServiceProvider = Provider<AuthService>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthService(dio);
});

class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  Future<Response> emaillogin(String username, String password) async {
    try {
      Response<dynamic> result = await _dio.post(
        "/auth/email/login",
        data: {"email": username, "password": password},
      );

      return result;
    } catch (err) {
      rethrow;
    }
  }

  Future<Response> phonelogin(String username, String password) async {
    try {
      Response<dynamic> result = await _dio.post(
        "/auth/phone/login",
        data: {"mobile": username, "password": password},
      );

      return result;
    } catch (err) {
      rethrow;
    }
  }

  Future<Response> signup(
    String username,
    String password,
    String email, [
    String? mobile,
  ]) async {
    try {
      final Map<String, dynamic> data = {
        "username": username,
        "password": password,
        "email": email,
      };
      if (mobile != null && mobile.trim().isNotEmpty) {
        data["mobile"] = mobile.trim();
      }

      Response<dynamic> result = await _dio.post(
        "/auth/signup",
        data: data,
      );

      return result;
    } catch (err) {
      rethrow;
    }
  }

  /// Verify signup OTP (email and/or phone) to complete user registration
  Future<Response> verifySignupOtp({
    String? signupToken,
    String? email,
    String? emailOtp,
    String? phoneOtp,
    String? otp,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (signupToken != null && signupToken.isNotEmpty) {
        data['signupToken'] = signupToken;
      }
      if (email != null && email.isNotEmpty) {
        data['email'] = email;
      }
      if (emailOtp != null && emailOtp.isNotEmpty) {
        data['emailOtp'] = emailOtp;
      }
      if (phoneOtp != null && phoneOtp.isNotEmpty) {
        data['phoneOtp'] = phoneOtp;
      }
      if (otp != null && otp.isNotEmpty) {
        data['otp'] = otp;
      }

      Response<dynamic> result = await _dio.post(
        "/auth/verify-signup-otp",
        data: data,
      );

      return result;
    } catch (err) {
      rethrow;
    }
  }

  /// Resend signup OTP for email, phone, or both
  Future<Response> resendSignupOtp({
    String? signupToken,
    String? email,
    String type = 'all',
  }) async {
    try {
      final Map<String, dynamic> data = {'type': type};
      if (signupToken != null && signupToken.isNotEmpty) {
        data['signupToken'] = signupToken;
      }
      if (email != null && email.isNotEmpty) {
        data['email'] = email;
      }

      Response<dynamic> result = await _dio.post(
        "/auth/resend-signup-otp",
        data: data,
      );

      return result;
    } catch (err) {
      rethrow;
    }
  }

  /// Request an OTP for the given identifier (email or phone)
  Future<Response> requestOtp(String identifier) async {
    try {
      Response<dynamic> result = await _dio.post(
        "/auth/request-otp",
        data: {"email": identifier},
      );

      return result;
    } catch (err) {
      rethrow;
    }
  }

  /// Verify the OTP code for the given identifier
  Future<Response> verifyOtp(String identifier, String code) async {
    try {
      Response<dynamic> result = await _dio.post(
        "/auth/verify-otp",
        data: {"identifier": identifier, "otp": code},
      );

      return result;
    } catch (err) {
      rethrow;
    }
  }

  /// Send password reset email
  Future<Response> resetPassword(String email) async {
    try {
      final result = await _dio.post(
        "/auth/password/reset",
        data: {"email": email},
      );
      return result;
    } catch (err) {
      rethrow;
    }
  }

  /// Update user profile with arbitrary allowed fields (username, mobile, gender, age, photo, address)
  Future<Response> updateUserProfile(Map<String, dynamic> updatedData) async {
    try {
      Response<dynamic> result = await _dio.patch(
        "/users/update/me",
        data: updatedData,
      );
      return result;
    } catch (err) {
      rethrow;
    }
  }

  /// Update user profile picture URL
  Future<Response> updateProfilePicture(String photoUrl) async {
    return updateUserProfile({'photo': photoUrl});
  }

  /// Request OTP for updating or verifying email
  Future<Response> requestEmailUpdateOtp(String email) async {
    try {
      final Response<dynamic> result = await _dio.post(
        "/users/request-email-otp",
        data: {"email": email},
      );
      return result;
    } catch (err) {
      rethrow;
    }
  }

  /// Verify OTP and update email
  Future<Response> verifyEmailUpdateOtp(String email, String otp) async {
    try {
      final Response<dynamic> result = await _dio.post(
        "/users/verify-email-otp",
        data: {"email": email, "otp": otp},
      );
      return result;
    } catch (err) {
      rethrow;
    }
  }

  /// Request OTP for updating or verifying mobile number
  Future<Response> requestMobileUpdateOtp(String mobile) async {
    try {
      final Response<dynamic> result = await _dio.post(
        "/users/request-mobile-otp",
        data: {"mobile": mobile},
      );
      return result;
    } catch (err) {
      rethrow;
    }
  }

  /// Verify OTP and update mobile number
  Future<Response> verifyMobileUpdateOtp(String mobile, String otp) async {
    try {
      final Response<dynamic> result = await _dio.post(
        "/users/verify-mobile-otp",
        data: {"mobile": mobile, "otp": otp},
      );
      return result;
    } catch (err) {
      rethrow;
    }
  }

  Future<bool> logout() async {
    try {
      final tokenRepository = TokenRepository();
      await NotificationService.instance.deleteTokenFromBackend();
      await tokenRepository.deleteToken();
      SocketService.instance.disconnect();
      return true;
    } catch (err) {
      return false;
    }
  }
}
