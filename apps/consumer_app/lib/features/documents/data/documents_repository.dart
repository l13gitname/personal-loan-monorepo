import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/providers.dart';

part 'documents_repository.freezed.dart';
part 'documents_repository.g.dart';

@freezed
abstract class DocumentInfo with _$DocumentInfo {
  const factory DocumentInfo({
    required String id,
    required String documentTypeCode,
    required String originalName,
    required String contentType,
    required int sizeBytes,
  }) = _DocumentInfo;

  factory DocumentInfo.fromJson(Map<String, dynamic> json) =>
      _$DocumentInfoFromJson(json);
}

class DocumentsRepository {
  DocumentsRepository(this._dio);

  final Dio _dio;

  Future<List<DocumentInfo>> list(String quotationId) => _guard(() async {
        final res = await _dio.get<List<dynamic>>('/quotations/$quotationId/documents');
        return res.data!
            .map((e) => DocumentInfo.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  /// Sends the file to the server (multipart). The server verifies the real
  /// file type (PDF/JPEG/PNG) and the product's document rules.
  Future<DocumentInfo> upload({
    required String quotationId,
    required String documentTypeCode,
    required String fileName,
    required Uint8List bytes,
  }) =>
      _guard(() async {
        // A multipart body can be sent only once, so build it per attempt.
        Future<Response<Map<String, dynamic>>> attempt() => _dio.post<Map<String, dynamic>>(
              '/quotations/$quotationId/documents',
              data: FormData.fromMap({
                'documentTypeCode': documentTypeCode,
                'file': MultipartFile.fromBytes(bytes, filename: fileName),
              }),
              options: Options(sendTimeout: const Duration(minutes: 2)),
            );

        Response<Map<String, dynamic>> res;
        try {
          res = await attempt();
        } on DioException catch (e) {
          // The interceptor refreshed the token but cannot replay a FormData.
          if (e.response?.statusCode != 401) rethrow;
          res = await attempt();
        }
        return DocumentInfo.fromJson(res.data!);
      });

  Future<void> remove(String quotationId, String documentId) => _guard(() async {
        await _dio.delete<void>('/quotations/$quotationId/documents/$documentId');
      });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final documentsRepositoryProvider =
    Provider<DocumentsRepository>((ref) => DocumentsRepository(ref.watch(dioProvider)));
