import 'package:customer_app/network/api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userServiceProvider = Provider<UserService>((ref) {
  final dio = ref.watch(dioProvider);
  return UserService(dio);
});

class UserService {
  final Dio _dio;

  UserService(this._dio);

  Future<Response> getUserProfile() async {
    try {
      Response<dynamic> result = await _dio.get("/users/profile/me");
      return result;
    } catch (err) {
      rethrow;
    }
  }

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

  /// Request OTP for updating or verifying customer email
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

  /// Verify OTP and update customer email
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

  /// Request OTP for updating or verifying customer mobile number
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

  /// Verify OTP and update customer mobile number
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

  /// Sync FCM device token with backend
  Future<Response?> syncFcmToken(String fcmToken) async {
    try {
      Response<dynamic> result = await _dio.patch(
        "/users/update/me",
        data: {"fcmToken": fcmToken},
      );
      return result;
    } catch (_) {
      return null;
    }
  }
}

