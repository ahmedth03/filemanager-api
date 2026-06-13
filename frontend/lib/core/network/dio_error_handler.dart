import 'dart:io';

import 'package:dio/dio.dart';

import '../error/exceptions.dart';
import '../error/failures.dart';

/// Maps a [DioException] to the corresponding [Failure] sealed type.
///
/// Call [DioErrorHandler.handle] from repository `catch` blocks:
/// ```dart
/// on DioException catch (e) {
///   return Left(DioErrorHandler.handle(e));
/// }
/// ```
class DioErrorHandler {
  DioErrorHandler._();

  /// Converts a [DioException] into a domain [Failure].
  static Failure handle(DioException error) {
    switch (error.type) {
      // ── Connection / network errors ──────────────────────────────────────
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const Failure.network(
          message: 'Connection timed out. Please check your network and retry.',
        );

      case DioExceptionType.connectionError:
        return const Failure.network(
          message:
              'Unable to connect to the server. Please check your internet connection.',
        );

      case DioExceptionType.cancel:
        return const Failure.network(message: 'Request was cancelled.');

      // ── Bad certificate ──────────────────────────────────────────────────
      case DioExceptionType.badCertificate:
        return const Failure.network(
          message: 'SSL certificate error. Connection is not secure.',
        );

      // ── Server responses (4xx / 5xx) ─────────────────────────────────────
      case DioExceptionType.badResponse:
        return _handleBadResponse(error);

      // ── Unknown ───────────────────────────────────────────────────────────
      case DioExceptionType.unknown:
        // Dio wraps SocketException as DioExceptionType.unknown
        if (error.error is SocketException) {
          return const Failure.network(
            message:
                'No internet connection. Please check your network settings.',
          );
        }
        return Failure.unknown(
          message: error.message ?? 'An unexpected error occurred.',
          exception: error.error,
        );
    }
  }

  // ── Response-level error mapping ──────────────────────────────────────────

  static Failure _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;
    final message = _extractMessage(responseData);

    switch (statusCode) {
      case 400:
        // Attempt to parse validation errors
        final validationErrors = _extractValidationErrors(responseData);
        if (validationErrors.isNotEmpty) {
          return Failure.validation(
            message: message ?? 'Validation failed. Please fix the errors.',
            errors: validationErrors,
          );
        }
        return Failure.server(
          statusCode: 400,
          message: message ?? 'Bad request.',
          data: responseData,
        );

      case 401:
        return Failure.auth(
          message: message ?? 'Authentication required. Please log in.',
        );

      case 403:
        return Failure.auth(
          message:
              message ?? 'You do not have permission to perform this action.',
        );

      case 404:
        return Failure.server(
          statusCode: 404,
          message: message ?? 'The requested resource was not found.',
          data: responseData,
        );

      case 409:
        return Failure.server(
          statusCode: 409,
          message: message ?? 'A conflict occurred. Please try again.',
          data: responseData,
        );

      case 422:
        final validationErrors = _extractValidationErrors(responseData);
        return Failure.validation(
          message: message ?? 'Unprocessable entity.',
          errors: validationErrors,
        );

      case 429:
        return Failure.server(
          statusCode: 429,
          message:
              message ?? 'Too many requests. Please wait and try again.',
          data: responseData,
        );

      case 500:
        return Failure.server(
          statusCode: 500,
          message: message ?? 'Internal server error. Please try again later.',
          data: responseData,
        );

      case 503:
        return Failure.server(
          statusCode: 503,
          message: message ?? 'Service temporarily unavailable.',
          data: responseData,
        );

      default:
        return Failure.server(
          statusCode: statusCode ?? -1,
          message: message ?? 'An unexpected server error occurred.',
          data: responseData,
        );
    }
  }

  // ── Parsing helpers ───────────────────────────────────────────────────────

  /// Tries to extract a human-readable message from the server response body.
  static String? _extractMessage(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) {
      return (data['message'] as String?) ??
          (data['error'] as String?) ??
          (data['msg'] as String?);
    }
    if (data is String) return data;
    return null;
  }

  /// Tries to extract field-level validation errors from the server response.
  ///
  /// Supports several common API response shapes:
  /// - `{ "errors": { "field": ["error1", "error2"] } }`
  /// - `{ "errors": [{ "field": "name", "message": "Required" }] }`
  /// - `{ "validation": { "field": ["error"] } }`
  static Map<String, List<String>> _extractValidationErrors(dynamic data) {
    if (data == null || data is! Map<String, dynamic>) return {};

    // Shape 1: map of field → list
    final errorsValue = data['errors'] ?? data['validation'];

    if (errorsValue is Map<String, dynamic>) {
      return errorsValue.map((key, value) {
        if (value is List) {
          return MapEntry(key, value.map((e) => e.toString()).toList());
        }
        if (value is String) {
          return MapEntry(key, [value]);
        }
        return MapEntry(key, <String>[]);
      });
    }

    // Shape 2: list of error objects
    if (errorsValue is List) {
      final Map<String, List<String>> result = {};
      for (final item in errorsValue) {
        if (item is Map<String, dynamic>) {
          final field = item['field'] as String? ?? 'general';
          final msg = item['message'] as String? ?? item['msg'] as String? ?? '';
          result.putIfAbsent(field, () => []).add(msg);
        }
      }
      return result;
    }

    return {};
  }

  /// Converts a generic [Exception] to a [Failure] for non-Dio errors.
  static Failure fromException(Object error) {
    if (error is DioException) return handle(error);
    if (error is SocketException) {
      return const Failure.network(
        message: 'No internet connection.',
      );
    }
    return Failure.unknown(
      message: error.toString(),
      exception: error,
    );
  }
}
