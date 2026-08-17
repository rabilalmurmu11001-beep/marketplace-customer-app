import 'package:customer_app/network/api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final addressServiceProvider = Provider<AddressServices>((ref) {
  final dio = ref.watch(dioProvider);
  return AddressServices(dio);
});

class AddressServices {
  final Dio _dio;
  const AddressServices(this._dio);

  Future<Response> getAllUserAddress() async {
    try {
      Response<dynamic> result = await _dio.get('/addresses');
      return result;
    } catch (err) {
      rethrow;
    }
  }

  Future<Response> saveNewAddress(Map<String, dynamic> address) async {
    try {
      Response<dynamic> result = await _dio.post('/addresses', data: address);
      return result;
    } catch (err) {
      rethrow;
    }
  }

  Future<Response> saveUpdatedAddress(
    Map<String, dynamic> address,
    String id,
  ) async {
    try {
      Response<dynamic> result = await _dio.patch(
        '/addresses/$id',
        data: address,
      );
      return result;
    } catch (err) {
      rethrow;
    }
  }

  Future<Response> deleteAddress(String id) async {
    try {
      Response<dynamic> result = await _dio.delete("/addresses/$id");
      return result;
    } catch (err) {
      rethrow;
    }
  }
}
