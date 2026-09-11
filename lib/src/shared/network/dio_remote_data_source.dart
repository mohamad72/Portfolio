import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import 'remote_data_source.dart';

@LazySingleton(as: RemoteDataSource)
class DioRemoteDataSource implements RemoteDataSource {
  DioRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, dynamic>> getJson(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    final response = await _dio.get<Object?>(
      url,
      queryParameters: queryParameters,
      options: Options(headers: headers),
    );
    return _asMap(response.data);
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String url, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    final response = await _dio.post<Object?>(
      url,
      data: body,
      queryParameters: queryParameters,
      options: Options(
        headers: headers,
        contentType: Headers.jsonContentType,
      ),
    );
    return _asMap(response.data);
  }

  @override
  Future<Map<String, dynamic>> postForm(
    String url, {
    required Map<String, dynamic> body,
    Map<String, dynamic>? headers,
  }) async {
    final response = await _dio.post<Object?>(
      url,
      data: body,
      options: Options(
        headers: headers,
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
    return _asMap(response.data);
  }

  Map<String, dynamic> _asMap(Object? data) {
    if (data is! Map) {
      throw const FormatException('Expected a JSON object response.');
    }

    return data.map<String, dynamic>(
      (Object? key, Object? value) => MapEntry<String, dynamic>(
        key.toString(),
        value,
      ),
    );
  }
}
