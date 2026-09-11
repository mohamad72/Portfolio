import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/src/shared/error/failure.dart';

void main() {
  group('Failure.detailed', () {
    test('keeps the original exception and stack trace in the UI message', () {
      final failure = Failure.detailed(
        'ذخیرهٔ فایل ناموفق بود.',
        StateError('disk is read-only'),
        StackTrace.fromString('saveFile (markdown_file_writer.dart:42:7)'),
      );

      expect(failure.message, contains('ذخیرهٔ فایل ناموفق بود.'));
      expect(failure.message, contains('StateError'));
      expect(failure.message, contains('disk is read-only'));
      expect(
        failure.message,
        contains('saveFile (markdown_file_writer.dart:42:7)'),
      );
    });

    test('includes the HTTP status, request target, and raw server response', () {
      final request = RequestOptions(
        path: 'https://api.example.test/portfolio',
        method: 'POST',
        headers: <String, dynamic>{
          'Authorization': 'Bearer must-not-be-shown',
        },
        data: <String, dynamic>{'password': 'must-not-be-shown'},
      );
      final error = DioException.badResponse(
        statusCode: 422,
        requestOptions: request,
        response: Response<Object?>(
          requestOptions: request,
          statusCode: 422,
          statusMessage: 'Unprocessable Entity',
          data: <String, dynamic>{
            'error': 'invalid_portfolio',
            'details': <String>['symbolIsin is required'],
            'access_token': 'must-not-be-shown',
          },
        ),
      );

      final failure = Failure.detailed(
        'دریافت پرتفوی ناموفق بود.',
        error,
        StackTrace.fromString('loadPortfolio (repository.dart:18:5)'),
      );

      expect(failure.message, contains('POST'));
      expect(
        failure.message,
        contains('https://api.example.test/portfolio'),
      );
      expect(failure.message, contains('422'));
      expect(failure.message, contains('Unprocessable Entity'));
      expect(failure.message, contains('invalid_portfolio'));
      expect(failure.message, contains('symbolIsin is required'));
      expect(failure.message, contains('loadPortfolio (repository.dart:18:5)'));
      expect(failure.message, contains('[REDACTED]'));
      expect(failure.message, isNot(contains('must-not-be-shown')));
    });

    test('keeps a malformed successful response instead of replacing it', () {
      final failure = Failure.invalidResponse(
        'ساختار موجودی مفید معتبر نیست.',
        <String, dynamic>{
          'items': 'unexpected text',
          'traceId': 'server-trace-42',
        },
      );

      expect(failure.message, contains('ساختار موجودی مفید معتبر نیست.'));
      expect(failure.message, contains('unexpected text'));
      expect(failure.message, contains('server-trace-42'));
    });
  });
}
