import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_app/network/api.dart';

final reviewServiceProvider = Provider<ReviewServices>((ref) {
  final dio = ref.watch(dioProvider);
  return ReviewServices(dio);
});

class ReviewServices {
  final Dio _dio;

  ReviewServices(this._dio);

  Future<Response> getReviewsByServiceId(String serviceId) async {
    try {
      final Response<dynamic> result =
          await _dio.get("/reviews/service/$serviceId");
      return result;
    } catch (err) {
      rethrow;
    }
  }

  Future<Response> getReviewById(String id) async {
    try {
      final Response<dynamic> result = await _dio.get("/reviews/$id");
      return result;
    } catch (err) {
      rethrow;
    }
  }

  Future<Response> createReview({
    required String bookingId,
    required int ratings,
    required String note,
  }) async {
    try {
      final Response<dynamic> result = await _dio.post(
        "/reviews",
        data: {
          "bookingId": bookingId,
          "ratings": ratings,
          "note": note,
        },
      );
      return result;
    } catch (err) {
      rethrow;
    }
  }
}
