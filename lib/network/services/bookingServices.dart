import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_app/network/api.dart';

final bookingServiceProvider = Provider<BookingServices>((ref) {
  final dio = ref.watch(dioProvider);
  return BookingServices(dio);
});

class BookingServices {
  final Dio _dio;

  BookingServices(this._dio);

  Future<Response> createBooking(Map<String, dynamic> bookingData) async {
    try {
      final payload = {
        "addresId": bookingData['addresId'] ?? bookingData['addressId'],
        "date": bookingData['date'] is DateTime
            ? (bookingData['date'] as DateTime).toIso8601String()
            : bookingData['date']?.toString(),
        "serviceId": bookingData['serviceId'],
        "timeSlot": bookingData['timeSlot'],
        "notes": bookingData['notes'] ?? '',
        if (bookingData['couponCode'] != null &&
            bookingData['couponCode'].toString().isNotEmpty)
          "couponCode": bookingData['couponCode'],
      };

      final Response<dynamic> result = await _dio.post(
        "/bookings",
        data: payload,
      );
      return result;
    } catch (err) {
      rethrow;
    }
  }

  Future<Response> getAllBookings() async {
    try {
      final Response<dynamic> result = await _dio.get("/bookings");
      return result;
    } catch (err) {
      rethrow;
    }
  }

  Future<Response> getBookingDetail(String id) async {
    try {
      final Response<dynamic> result = await _dio.get("/bookings/$id");
      return result;
    } catch (err) {
      rethrow;
    }
  }
}
