import 'package:dio/dio.dart';

/// Error shown to the user. Repositories translate every [DioException]
/// into this so ViewModels and widgets never depend on Dio.
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.errors = const [],
  });

  final String message;
  final int? statusCode;

  /// Field/rule messages, e.g. the list returned by `POST /quotations/:id/submit`.
  final List<String> errors;

  factory ApiException.fromDio(DioException e) {
    var message = 'Something went wrong. Please try again.';
    var errors = <String>[];

    final data = e.response?.data;
    if (data is Map) {
      final m = data['message'];
      if (m is String) {
        message = m;
      } else if (m is List) {
        errors = m.map((x) => x.toString()).toList();
        if (errors.isNotEmpty) message = errors.first;
      }
      final extra = data['errors'];
      if (extra is List) errors = extra.map((x) => x.toString()).toList();
    } else if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Cannot reach the server. Check your connection.';
    }

    return ApiException(message, statusCode: e.response?.statusCode, errors: errors);
  }

  @override
  String toString() => message;
}
