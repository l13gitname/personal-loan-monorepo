import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import 'catalog_models.dart';

class CatalogRepository {
  CatalogRepository(this._dio);

  final Dio _dio;

  Future<List<Product>> products() async {
    try {
      final res = await _dio.get<List<dynamic>>('/products');
      return res.data!
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ProductDetail> detail(String code) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/products/$code');
      return ProductDetail.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final catalogRepositoryProvider =
    Provider<CatalogRepository>((ref) => CatalogRepository(ref.watch(dioProvider)));

final productsProvider = FutureProvider.autoDispose<List<Product>>(
  (ref) => ref.watch(catalogRepositoryProvider).products(),
);

final productDetailProvider = FutureProvider.family<ProductDetail, String>(
  (ref, code) => ref.watch(catalogRepositoryProvider).detail(code),
);
