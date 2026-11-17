import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';
import 'quotation_models.dart';

class QuotationRepository {
  QuotationRepository(this._dio);

  final Dio _dio;

  Future<List<QuotationSummary>> list() => _guard(() async {
        final res = await _dio.get<List<dynamic>>('/quotations');
        return res.data!
            .map((e) => QuotationSummary.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  Future<QuotationDetail> get(String id) => _guard(() async {
        final res = await _dio.get<Map<String, dynamic>>('/quotations/$id');
        return QuotationDetail.fromJson(res.data!);
      });

  Future<QuotationDetail> create(String productCode, SaveQuotationRequest request) =>
      _guard(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/quotations',
          data: {'productCode': productCode, ...request.toJson()},
        );
        return QuotationDetail.fromJson(res.data!);
      });

  Future<QuotationDetail> save(String id, SaveQuotationRequest request) =>
      _guard(() async {
        final res = await _dio.patch<Map<String, dynamic>>(
          '/quotations/$id',
          data: request.toJson(),
        );
        return QuotationDetail.fromJson(res.data!);
      });

  Future<QuotationDetail> submit(String id) => _guard(() async {
        final res = await _dio.post<Map<String, dynamic>>('/quotations/$id/submit');
        return QuotationDetail.fromJson(res.data!);
      });

  Future<QuotationDetail> cancel(String id, {String? reason}) => _guard(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/quotations/$id/cancel',
          data: {if (reason != null) 'reason': reason},
        );
        return QuotationDetail.fromJson(res.data!);
      });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final quotationRepositoryProvider =
    Provider<QuotationRepository>((ref) => QuotationRepository(ref.watch(dioProvider)));

final myQuotationsProvider = FutureProvider.autoDispose<List<QuotationSummary>>(
  (ref) => ref.watch(quotationRepositoryProvider).list(),
);
