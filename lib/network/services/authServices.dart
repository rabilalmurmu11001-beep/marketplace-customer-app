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
    String email,
    String mobile,
  ) async {
    try {
      Response<dynamic> result = await _dio.post(
        "/auth/signup",
        data: {
          "username": username,
          "password": password,
          "email": email,
          "mobile": mobile,
        },
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
