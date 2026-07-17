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
      Response<dynamic> result = await _dio.get("/user/profile");
      return result;
    } catch (err) {
      rethrow;
    }
  }

  Future<Response> updateUserProfile(Map<String, dynamic> updatedData) async {
    try {
      Response<dynamic> result = await _dio.put(
        "/user/profile",
        data: updatedData,
      );
      return result;
    } catch (err) {
      rethrow;
    }
  }
}
