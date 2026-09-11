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

    final data = response.data;
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
