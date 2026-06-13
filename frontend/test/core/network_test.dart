import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harfidar/core/network/dio_error_handler.dart';

void main() {
  group('DioErrorHandler', () {
    test('handles connection timeout', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );

      final result = DioErrorHandler.handle(error);
      expect(result.message, contains('timeout'));
    });

    test('handles no internet connection', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionError,
      );

      final result = DioErrorHandler.handle(error);
      expect(result.message, contains('internet'));
    });

    test('handles 401 unauthorized', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
          data: {'message': 'Unauthorized'},
        ),
      );

      final result = DioErrorHandler.handle(error);
      expect(result.statusCode, equals(401));
    });

    test('handles 404 not found', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 404,
          data: {'message': 'Not found'},
        ),
      );

      final result = DioErrorHandler.handle(error);
      expect(result.statusCode, equals(404));
      expect(result.message, equals('Not found'));
    });

    test('handles array error messages', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 400,
          data: {'message': ['Email is required', 'Password is required']},
        ),
      );

      final result = DioErrorHandler.handle(error);
      expect(result.message, equals('Email is required'));
    });
  });

  group('AppException', () {
    test('toString returns message', () {
      const ex = AppException('Test error', statusCode: 400);
      expect(ex.toString(), equals('Test error'));
      expect(ex.statusCode, equals(400));
    });
  });
}
