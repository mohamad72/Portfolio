abstract interface class RemoteDataSource {
  Future<Map<String, dynamic>> getJson(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  });

  Future<Map<String, dynamic>> postJson(
    String url, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  });

  Future<Map<String, dynamic>> postForm(
    String url, {
    required Map<String, dynamic> body,
    Map<String, dynamic>? headers,
  });
}
