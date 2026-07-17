import 'package:customer_app/network/api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

final categoryServiceProvider = Provider<CategoryService>((ref) {
  final dio = ref.watch(dioProvider);
  return CategoryService(dio);
});

class CategoryService {
  final Dio _dio;

  CategoryService(this._dio);

  Future<Response> getCategories() async {
    try {
      Response<dynamic> result = await _dio.get("/categories/all");
      return result;
    } catch (err) {
      rethrow;
    }
  }
}
