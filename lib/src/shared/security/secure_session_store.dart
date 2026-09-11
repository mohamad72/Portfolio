import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

abstract interface class SessionStore {
  Future<String?> readAccessToken();

  Future<String?> readAccountKey();

  Future<DateTime?> readExpiresAt();

  Future<void> writeSession({
    required String accessToken,
    required String accountKey,
    required DateTime expiresAt,
  });

  Future<void> clear();
}

@LazySingleton(as: SessionStore)
class SecureSessionStore implements SessionStore {
  SecureSessionStore(this._storage);

  static const String _accessTokenKey = 'mofid_access_token';
  static const String _accountKey = 'mofid_account_key';
  static const String _expiresAtKey = 'mofid_access_token_expires_at';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() async {
    final token = await _storage.read(key: _accessTokenKey);
    if (token == null || token.isEmpty) {
      return null;
    }
    final expiresAt = await readExpiresAt();
    if (expiresAt == null || !DateTime.now().toUtc().isBefore(expiresAt)) {
      await clear();
      return null;
    }
    return token;
  }

  @override
  Future<String?> readAccountKey() => _storage.read(key: _accountKey);

  @override
  Future<DateTime?> readExpiresAt() async {
    final raw = await _storage.read(key: _expiresAtKey);
    if (raw == null) {
      return null;
    }
    return DateTime.tryParse(raw)?.toUtc();
  }

  @override
  Future<void> writeSession({
    required String accessToken,
    required String accountKey,
    required DateTime expiresAt,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _accountKey, value: accountKey);
    await _storage.write(
      key: _expiresAtKey,
      value: expiresAt.toUtc().toIso8601String(),
    );
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _accountKey);
    await _storage.delete(key: _expiresAtKey);
  }
}
