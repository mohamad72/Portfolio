import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/src/features/authentication/data/remote/mofid_login_remote_data_source.dart';
import 'package:portfolio/src/features/authentication/data/repository/mofid_authentication_repository_impl.dart';
import 'package:portfolio/src/features/authentication/data/security/mofid_credential_store.dart';
import 'package:portfolio/src/shared/network/remote_data_source.dart';
import 'package:portfolio/src/shared/security/biometric_authenticator.dart';
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

class _FakeMofidLoginRemoteDataSource implements MofidLoginRemoteDataSource {
  String? username;
  String? password;
  Uri? authorizationUri;

  @override
  Future<Uri> authorizeWithCredentials({
    required Uri authorizationUri,
    required String username,
    required String password,
  }) async {
    this.authorizationUri = authorizationUri;
    this.username = username;
    this.password = password;
    final state = authorizationUri.queryParameters['state']!;
    return Uri.parse(
      'https://m.easytrader.ir/auth-callback?code=auth-code&state=$state',
    );
  }
}

class _FakeSessionStore implements SessionStore {
  String? token;
  DateTime? expiresAt;
  String? accountKey;

  @override
  Future<void> clear() async {
    token = null;
    expiresAt = null;
    accountKey = null;
  }

  @override
  Future<String?> readAccessToken() async => token;

  @override
  Future<String?> readAccountKey() async => accountKey;

  @override
  Future<DateTime?> readExpiresAt() async => expiresAt;

  @override
  Future<void> writeSession({
    required String accessToken,
    required String accountKey,
    required DateTime expiresAt,
  }) async {
    token = accessToken;
    this.accountKey = accountKey;
    this.expiresAt = expiresAt;
  }
}

class _FakeCredentialStore implements MofidCredentialStore {
  SavedMofidCredentials? credentials;

  @override
  Future<void> clear() async => credentials = null;

  @override
  Future<SavedMofidCredentials?> read() async => credentials;

  @override
  Future<void> write({required String username, required String password}) async {
    credentials = SavedMofidCredentials(username: username, password: password);
  }
}

class _FakeBiometricAuthenticator implements BiometricAuthenticator {
  bool available = true;
  bool result = true;

  @override
  Future<bool> canAuthenticate() async => available;

  @override
  Future<bool> authenticate() async => result;
}

void main() {
  test('logs in directly with username/password, exchanges PKCE code, and saves credentials', () async {
    final remote = _FakeRemoteDataSource();
    final loginRemote = _FakeMofidLoginRemoteDataSource();
    final sessionStore = _FakeSessionStore();
    final credentialStore = _FakeCredentialStore();
    final biometrics = _FakeBiometricAuthenticator();
    final repository = MofidAuthenticationRepositoryImpl(
      remote,
      loginRemote,
      sessionStore,
      credentialStore,
      biometrics,
    );

    final result = await repository.login(
      username: '09120000000',
      password: 'secret',
    );

    expect(result.isRight(), isTrue);
    expect(loginRemote.username, '09120000000');
    expect(loginRemote.password, 'secret');
    expect(loginRemote.authorizationUri?.host, 'login.emofid.com');
    expect(
      loginRemote.authorizationUri?.queryParameters['client_id'],
      'easy_pkce',
    );
    expect(remote.lastUrl, 'https://login.emofid.com/connect/token');
    expect(remote.lastForm?['grant_type'], 'authorization_code');
    expect(remote.lastForm?['code'], 'auth-code');
    expect(remote.lastForm?['code_verifier'], isNotEmpty);
    expect(sessionStore.token, 'test-token');
    expect(credentialStore.credentials?.username, '09120000000');
    expect(credentialStore.credentials?.password, 'secret');
  });

  test('re-login uses credentials previously saved in secure storage', () async {
    final remote = _FakeRemoteDataSource();
    final loginRemote = _FakeMofidLoginRemoteDataSource();
    final sessionStore = _FakeSessionStore();
    final credentialStore = _FakeCredentialStore()
      ..credentials = const SavedMofidCredentials(
        username: 'saved-user',
        password: 'saved-password',
      );
    final repository = MofidAuthenticationRepositoryImpl(
      remote,
      loginRemote,
      sessionStore,
      credentialStore,
      _FakeBiometricAuthenticator(),
    );

    final result = await repository.loginWithSavedCredentials();

    expect(result.isRight(), isTrue);
    expect(loginRemote.username, 'saved-user');
    expect(loginRemote.password, 'saved-password');
  });

  test('biometric authentication is delegated to local authenticator', () async {
    final biometrics = _FakeBiometricAuthenticator()..result = true;
    final repository = MofidAuthenticationRepositoryImpl(
      _FakeRemoteDataSource(),
      _FakeMofidLoginRemoteDataSource(),
      _FakeSessionStore(),
      _FakeCredentialStore(),
      biometrics,
    );

    final result = await repository.authenticateWithBiometrics();

    expect(result.isRight(), isTrue);
  });
}
