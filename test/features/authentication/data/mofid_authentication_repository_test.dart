import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/src/features/authentication/data/repository/mofid_authentication_repository_impl.dart';
import 'package:portfolio/src/shared/network/remote_data_source.dart';
import 'package:portfolio/src/shared/security/secure_session_store.dart';

class _FakeRemoteDataSource implements RemoteDataSource {
  String? lastUrl;
  Map<String, dynamic>? lastForm;

  @override
  Future<Map<String, dynamic>> getJson(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String url, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> postForm(
    String url, {
    required Map<String, dynamic> body,
    Map<String, dynamic>? headers,
  }) async {
    lastUrl = url;
    lastForm = Map<String, dynamic>.from(body);
    return const <String, dynamic>{
      'access_token': 'test-token',
      'expires_in': 43200,
      'token_type': 'Bearer',
    };
  }
}

class _FakeSessionStore implements SessionStore {
  String? token;

  @override
  Future<void> clear() async => token = null;

  @override
  Future<String?> readAccessToken() async => token;

  @override
  Future<String?> readAccountKey() async => token == null ? null : 'account';

  @override
  Future<DateTime?> readExpiresAt() async =>
      token == null ? null : DateTime.now().toUtc().add(const Duration(hours: 1));

  @override
  Future<void> writeSession({
    required String accessToken,
    required String accountKey,
    required DateTime expiresAt,
  }) async {
    token = accessToken;
  }
}

void main() {
  test('exchanges authorization code with the observed PKCE token contract', () async {
    final remote = _FakeRemoteDataSource();
    final store = _FakeSessionStore();
    final repository = MofidAuthenticationRepositoryImpl(remote, store);

    final result = await repository.exchangeAuthorizationCode(
      code: 'auth-code',
      codeVerifier: 'verifier',
    );

    expect(result.isRight(), isTrue);
    expect(remote.lastUrl, 'https://login.emofid.com/connect/token');
    expect(remote.lastForm, <String, dynamic>{
      'grant_type': 'authorization_code',
      'redirect_uri': 'https://m.easytrader.ir/auth-callback',
      'code': 'auth-code',
      'code_verifier': 'verifier',
      'client_id': 'easy_pkce',
    });
    expect(store.token, 'test-token');
  });
}
