import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_app/network/api.dart';

final couponsServiceProvider = Provider<CouponsService>((ref) {
  final dio = ref.watch(dioProvider);
  return CouponsService(dio);
});

class CouponsService {
  final Dio _dio;

  CouponsService(this._dio);

  Future<Response> getAllCoupons() async {
    try {
      final Response<dynamic> result = await _dio.get('/coupons/all');
      return result;
    } catch (err) {
      rethrow;
    }
  }
}
