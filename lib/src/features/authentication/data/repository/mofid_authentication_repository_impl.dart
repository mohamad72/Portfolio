import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../shared/error/failure.dart';
import '../../../../shared/network/remote_data_source.dart';
import '../../../../shared/security/biometric_authenticator.dart';
import '../../../../shared/security/secure_session_store.dart';
import '../../domain/entities/mofid_session.dart';
import '../../domain/repository/authentication_repository.dart';
import '../pkce/pkce_generator.dart';
import '../remote/mofid_login_remote_data_source.dart';
import '../security/mofid_credential_store.dart';

@LazySingleton(as: AuthenticationRepository)
class MofidAuthenticationRepositoryImpl implements AuthenticationRepository {
  MofidAuthenticationRepositoryImpl(
    this._remoteDataSource,
    this._loginRemoteDataSource,
    this._sessionStore,
    this._credentialStore,
    this._biometricAuthenticator,
  );

  static const String _authorizationEndpoint =
      'https://login.emofid.com/connect/authorize';
  static const String _tokenUrl = 'https://login.emofid.com/connect/token';
  static const String _clientId = 'easy_pkce';
  static const String _redirectUri = 'https://m.easytrader.ir/auth-callback';
  static const String _scope =
      'easy2_api mts_api openid profile login_delegation-api';

  final RemoteDataSource _remoteDataSource;
  final MofidLoginRemoteDataSource _loginRemoteDataSource;
  final SessionStore _sessionStore;
  final MofidCredentialStore _credentialStore;
  final BiometricAuthenticator _biometricAuthenticator;

  @override
  Future<Either<Failure, MofidSession>> login({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty || password.isEmpty) {
      return left(const Failure('نام کاربری و رمز مفید را وارد کنید.'));
    }

    return _loginInternal(
      username: normalizedUsername,
      password: password,
      saveCredentials: true,
    );
  }

  @override
  Future<Either<Failure, MofidSession>> loginWithSavedCredentials() async {
    final credentials = await _credentialStore.read();
    if (credentials == null) {
      return left(const Failure('اطلاعات ورود ذخیره‌شدهٔ مفید پیدا نشد.'));
    }
    return _loginInternal(
      username: credentials.username,
      password: credentials.password,
      saveCredentials: false,
    );
  }

  Future<Either<Failure, MofidSession>> _loginInternal({
    required String username,
    required String password,
    required bool saveCredentials,
  }) async {
    try {
      const generator = PkceGenerator();
      final pair = generator.generate();
      final authorizationUri = Uri.parse(_authorizationEndpoint).replace(
        queryParameters: <String, String>{
          'client_id': _clientId,
          'redirect_uri': _redirectUri,
          'response_type': 'code',
          'scope': _scope,
          'state': pair.state,
          'code_challenge': pair.challenge,
          'code_challenge_method': 'S256',
        },
      );

      final callbackUri = await _loginRemoteDataSource.authorizeWithCredentials(
        authorizationUri: authorizationUri,
        username: username,
        password: password,
      );
      final returnedState = callbackUri.queryParameters['state'];
      if (returnedState != pair.state) {
        return left(const Failure('اعتبار state ورود مفید تأیید نشد.'));
      }

      final error = callbackUri.queryParameters['error_description'] ??
          callbackUri.queryParameters['error'];
      if (error != null && error.isNotEmpty) {
        return left(Failure(error));
      }
      final code = callbackUri.queryParameters['code'];
      if (code == null || code.isEmpty) {
        return left(const Failure('کد ورود از مفید دریافت نشد.'));
      }

      final sessionResult = await _exchangeAuthorizationCode(
        code: code,
        codeVerifier: pair.verifier,
      );
      return sessionResult.fold<Future<Either<Failure, MofidSession>>>(
        (failure) async => left(failure),
        (session) async {
          if (saveCredentials) {
            await _credentialStore.write(
              username: username,
              password: password,
            );
          }
          return right(session);
        },
      );
    } on MofidDirectLoginException catch (error) {
      return left(Failure(error.message, cause: error));
    } catch (error) {
      return left(Failure('ورود مستقیم مفید ناموفق بود.', cause: error));
    }
  }

  Future<Either<Failure, MofidSession>> _exchangeAuthorizationCode({
    required String code,
    required String codeVerifier,
  }) async {
    try {
      final response = await _remoteDataSource.postForm(
        _tokenUrl,
        body: <String, dynamic>{
          'grant_type': 'authorization_code',
          'redirect_uri': _redirectUri,
          'code': code,
          'code_verifier': codeVerifier,
          'client_id': _clientId,
        },
      );

      final token = response['access_token']?.toString();
      if (token == null || token.isEmpty) {
        return left(const Failure('توکن ورود مفید در پاسخ وجود نداشت.'));
      }

      final expiresIn = switch (response['expires_in']) {
        final int value => value,
        final num value => value.toInt(),
        final Object value => int.tryParse(value.toString()) ?? 0,
        null => 0,
      };

      final session = MofidSession(
        accessToken: token,
        tokenType: response['token_type']?.toString() ?? 'Bearer',
        expiresInSeconds: expiresIn,
      );
      final expiresAt = DateTime.now().toUtc().add(
        Duration(seconds: expiresIn > 0 ? expiresIn : 43200),
      );
      final identityToken = response['id_token']?.toString();
      await _sessionStore.writeSession(
        accessToken: token,
        accountKey: _accountKeyFor(
          identityToken == null || identityToken.isEmpty ? token : identityToken,
        ),
        expiresAt: expiresAt,
      );
      return right(session);
    } catch (error) {
      return left(Failure('تبادل توکن مفید ناموفق بود.', cause: error));
    }
  }

  String _accountKeyFor(String token) {
    String stableSeed = token;
    try {
      final parts = token.split('.');
      if (parts.length >= 2) {
        final normalized = base64Url.normalize(parts[1]);
        final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)));
        if (payload is Map) {
          final sub = payload['sub']?.toString();
          final pk = payload['pk']?.toString();
          if (sub != null && sub.isNotEmpty) {
            stableSeed = sub;
          } else if (pk != null && pk.isNotEmpty) {
            stableSeed = pk;
          }
        }
      }
    } catch (_) {
      // Opaque access tokens remain scoped by a stable local hash.
    }
    return sha256.convert(utf8.encode(stableSeed)).toString();
  }

  @override
  Future<bool> hasSession() async {
    final token = await _sessionStore.readAccessToken();
    final expiresAt = await _sessionStore.readExpiresAt();
    if (token == null || token.isEmpty || expiresAt == null) {
      return false;
    }
    if (!DateTime.now().toUtc().isBefore(expiresAt)) {
      await _sessionStore.clear();
      return false;
    }
    return true;
  }

  @override
  Future<bool> hasSavedCredentials() async =>
      await _credentialStore.read() != null;

  @override
  Future<bool> canAuthenticateWithBiometrics() async {
    try {
      return await _biometricAuthenticator.canAuthenticate();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Either<Failure, Unit>> authenticateWithBiometrics() async {
    try {
      final authenticated = await _biometricAuthenticator.authenticate();
      if (!authenticated) {
        return left(const Failure('اثر انگشت تأیید نشد.'));
      }
      return right(unit);
    } catch (error) {
      return left(Failure('احراز هویت بیومتریک ناموفق بود.', cause: error));
    }
  }

  @override
  Future<void> logout({bool forgetCredentials = false}) async {
    await _sessionStore.clear();
    if (forgetCredentials) {
      await _credentialStore.clear();
    }
  }
}
