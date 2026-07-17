import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_app/network/api.dart';

final servicesServiceProvider = Provider<ServicesService>((ref) {
  final dio = ref.watch(dioProvider);
  return ServicesService(dio);
});

class ServicesService {
  final Dio _dio;

  ServicesService(this._dio);

  Future<Response> getRecommendedServices() async {
    try {
      Response<dynamic> result = await _dio.get("/services/recomended");
      return result;
    } catch (err) {
      rethrow;
    }
  }
}
