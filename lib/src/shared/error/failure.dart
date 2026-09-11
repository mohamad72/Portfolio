import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

class Failure extends Equatable {
  const Failure(this.message, {this.cause, this.stackTrace});

  factory Failure.detailed(
    String context,
    Object error,
    StackTrace stackTrace,
  ) {
    final details = <String>[
      context,
      'نوع خطا: ${error.runtimeType}',
      'متن خطا: ${_redactText(error.toString())}',
    ];

    if (error is DioException) {
      final response = error.response;
      details.addAll(<String>[
        'نوع خطای شبکه: ${error.type.name}',
        'درخواست: ${error.requestOptions.method} ${error.requestOptions.uri}',
        'کد وضعیت: ${response?.statusCode ?? 'دریافت نشد'}',
        'متن وضعیت: ${response?.statusMessage ?? 'دریافت نشد'}',
        'پاسخ خام سرور: ${_formatPayload(response?.data)}',
      ]);
    }

    details.add('Stack trace:\n$stackTrace');
    return Failure(
      details.join('\n'),
      cause: error,
      stackTrace: stackTrace,
    );
  }

  factory Failure.invalidResponse(String context, Object? response) => Failure(
        '$context\n'
        'نوع پاسخ: ${response.runtimeType}\n'
        'پاسخ خام سرور: ${_formatPayload(response)}',
      );

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  List<Object?> get props => <Object?>[message, cause, stackTrace];

  static String _formatPayload(Object? payload) {
    if (payload == null) {
      return 'null';
    }
    if (payload is String) {
      return _redactText(payload);
    }
    try {
      return const JsonEncoder.withIndent('  ').convert(_redact(payload));
    } catch (error, stackTrace) {
      return '$payload\n'
          'خطای تبدیل پاسخ برای نمایش: ${error.runtimeType}: $error\n'
          'Stack trace تبدیل پاسخ:\n$stackTrace';
    }
  }

  static Object? _redact(Object? value) {
    if (value is Map) {
      return value.map<String, Object?>((key, item) {
        final stringKey = key.toString();
        return MapEntry<String, Object?>(
          stringKey,
          _isSensitiveKey(stringKey) ? '[REDACTED]' : _redact(item),
        );
      });
    }
    if (value is Iterable) {
      return value.map<Object?>((item) => _redact(item)).toList();
    }
    return value;
  }

  static bool _isSensitiveKey(String key) {
    final normalized = key.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
    return const <String>{
      'accesstoken',
      'refreshtoken',
      'idtoken',
      'token',
      'authorization',
      'password',
      'cookie',
      'setcookie',
    }.contains(normalized);
  }

  static String _redactText(String value) {
    var redacted = value.replaceAll(
      RegExp(r'Bearer\s+[^\s<>"]+', caseSensitive: false),
      'Bearer [REDACTED]',
    );
    redacted = redacted.replaceAll(
      RegExp(
        '''<input\\b[^>]*\\btype\\s*=\\s*['"]hidden['"][^>]*>''',
        caseSensitive: false,
      ),
      '<input type="hidden" value="[REDACTED]">',
    );
    return redacted;
  }
}
