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

  Future<Response> getAllServices() async {
    try {
      Response<dynamic> result = await _dio.get("/services");
      return result;
    } catch (err) {
      rethrow;
    }
  }

  Future<Response> getServiceDetail(String id) async {
    try {
      final Response<dynamic> result = await _dio.get('/services/$id');
      return result;
    } catch (err) {
      rethrow;
    }
  }

  Future<Response> bookService(Map<String, dynamic> bookingData) async {
    try {
      final result = await _dio.post(
        "/bookings",
        data: {
          "addresId": bookingData['addresId'],
          "date": bookingData['date'],
          "serviceId": bookingData['serviceId'],
          "timeSlot": bookingData['timeSlot'],
          "notes": bookingData['notes'],
        },
      );
      return result;
    } catch (err) {
      rethrow;
    }
  }
}
