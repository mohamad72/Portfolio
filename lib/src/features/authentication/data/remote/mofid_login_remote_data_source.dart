import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:injectable/injectable.dart';

import 'mofid_login_html_parser.dart';

abstract interface class MofidLoginRemoteDataSource {
  Future<Uri> authorizeWithCredentials({
    required Uri authorizationUri,
    required String username,
    required String password,
  });
}

@LazySingleton(as: MofidLoginRemoteDataSource)
class DioMofidLoginRemoteDataSource implements MofidLoginRemoteDataSource {
  DioMofidLoginRemoteDataSource()
      : _cookieJar = CookieJar(),
        _parser = const MofidLoginHtmlParser(),
        _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 10),
            headers: const <String, dynamic>{
              'Accept': 'text/html,application/xhtml+xml,application/json',
            },
          ),
        ) {
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  static const int _maxRedirects = 8;
  static final Uri _loginOrigin = Uri.parse('https://login.emofid.com/');

  final Dio _dio;
  final CookieJar _cookieJar;
  final MofidLoginHtmlParser _parser;

  @override
  Future<Uri> authorizeWithCredentials({
    required Uri authorizationUri,
    required String username,
    required String password,
  }) async {
    await _cookieJar.deleteAll();

    final loginPage = await _getLoginPage(authorizationUri);
    if (_isCallback(loginPage.uri)) {
      return loginPage.uri;
    }

    final challenge = _parser.parseChallenge(loginPage.body, loginPage.uri);
    final response = await _dio.postUri<String>(
      challenge.postUri,
      data: <String, dynamic>{
        'Username': username,
        'Password': password,
        '__RequestVerificationToken': challenge.requestVerificationToken,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.plain,
        followRedirects: false,
        validateStatus: _acceptRedirectOrSuccess,
        headers: <String, dynamic>{
          'Origin': _loginOrigin.origin,
          'Referer': _loginOrigin.toString(),
        },
      ),
    );

    final location = response.headers.value('location');
    if (location == null || location.isEmpty) {
      final message = _parser.extractErrorMessage(response.data ?? '');
      throw MofidDirectLoginException(
        message ??
            'ورود مستقیم مفید تأیید نشد. ممکن است نام کاربری/رمز نادرست باشد یا مرحلهٔ اضافی ورود لازم باشد.',
      );
    }

    final nextUri = challenge.postUri.resolve(location);
    return _followToCallback(nextUri);
  }

  Future<_HtmlPage> _getLoginPage(Uri startUri) async {
    var currentUri = startUri;

    for (var redirectCount = 0;
        redirectCount <= _maxRedirects;
        redirectCount++) {
      if (_isCallback(currentUri)) {
        return _HtmlPage(uri: currentUri, body: '');
      }

      final response = await _dio.getUri<String>(
        currentUri,
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: false,
          validateStatus: _acceptRedirectOrSuccess,
        ),
      );
      final location = response.headers.value('location');
      if (location == null || location.isEmpty) {
        final status = response.statusCode ?? 0;
        if (status < 200 || status >= 300) {
          throw MofidDirectLoginException(
            'صفحهٔ ورود مفید با وضعیت $status پاسخ داد.',
          );
        }
        return _HtmlPage(uri: currentUri, body: response.data ?? '');
      }
      currentUri = currentUri.resolve(location);
    }

    throw const MofidDirectLoginException(
      'تعداد تغییر مسیرهای ورود مفید بیش از حد انتظار بود.',
    );
  }

  Future<Uri> _followToCallback(Uri startUri) async {
    var currentUri = startUri;

    for (var redirectCount = 0;
        redirectCount <= _maxRedirects;
        redirectCount++) {
      if (_isCallback(currentUri)) {
        return currentUri;
      }

      final response = await _dio.getUri<String>(
        currentUri,
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: false,
          validateStatus: _acceptRedirectOrSuccess,
          headers: <String, dynamic>{
            'Referer': _loginOrigin.toString(),
          },
        ),
      );
      final location = response.headers.value('location');
      if (location == null || location.isEmpty) {
        final message = _parser.extractErrorMessage(response.data ?? '');
        throw MofidDirectLoginException(
          message ??
              'مفید به‌جای کد ورود یک مرحلهٔ اضافی برگرداند؛ این مرحله هنوز قرارداد API ثبت‌شده ندارد.',
        );
      }
      currentUri = currentUri.resolve(location);
    }

    throw const MofidDirectLoginException(
      'callback ورود مفید بعد از تغییر مسیرها دریافت نشد.',
    );
  }

  bool _isCallback(Uri uri) =>
      uri.scheme == 'https' &&
      uri.host == 'm.easytrader.ir' &&
      uri.path == '/auth-callback';

  static bool _acceptRedirectOrSuccess(int? status) =>
      status != null && status >= 200 && status < 400;
}

class MofidDirectLoginException implements Exception {
  const MofidDirectLoginException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _HtmlPage {
  const _HtmlPage({required this.uri, required this.body});

  final Uri uri;
  final String body;
}
