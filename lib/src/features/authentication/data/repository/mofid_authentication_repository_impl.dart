import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../shared/error/failure.dart';
import '../../../../shared/network/remote_data_source.dart';
import '../../../../shared/security/secure_session_store.dart';
import '../../domain/entities/mofid_session.dart';
import '../../domain/repository/authentication_repository.dart';

@LazySingleton(as: AuthenticationRepository)
class MofidAuthenticationRepositoryImpl implements AuthenticationRepository {
  MofidAuthenticationRepositoryImpl(
    this._remoteDataSource,
    this._sessionStore,
  );

  static const String _tokenUrl = 'https://login.emofid.com/connect/token';
  static const String _clientId = 'easy_pkce';
  static const String _redirectUri = 'https://m.easytrader.ir/auth-callback';

  final RemoteDataSource _remoteDataSource;
  final SessionStore _sessionStore;

  @override
  Future<Either<Failure, MofidSession>> exchangeAuthorizationCode({
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
      return left(Failure('تکمیل ورود مفید ناموفق بود.', cause: error));
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
      // Opaque tokens are still scoped safely, but local data will not carry
      // across a future token rotation for that account.
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
  Future<void> logout() => _sessionStore.clear();
}
