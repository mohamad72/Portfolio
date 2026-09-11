import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

abstract interface class IPasargadSessionStore {
  Future<String?> readToken(String accountId);

  Future<DateTime?> readExpiresAt(String accountId);

  Future<void> writeSession({
    required String accountId,
    required String token,
    required DateTime expiresAt,
  });

  Future<void> clear(String accountId);
}

@LazySingleton(as: IPasargadSessionStore)
class SecureIPasargadSessionStore implements IPasargadSessionStore {
  SecureIPasargadSessionStore(this._storage);

  final FlutterSecureStorage _storage;

  String _tokenKey(String accountId) => 'ipasargad_token:$accountId';
  String _expiresKey(String accountId) => 'ipasargad_expires_at:$accountId';

  @override
  Future<String?> readToken(String accountId) async {
    final expiresAt = await readExpiresAt(accountId);
    if (expiresAt == null || !DateTime.now().toUtc().isBefore(expiresAt)) {
      await clear(accountId);
      return null;
    }
    final token = await _storage.read(key: _tokenKey(accountId));
    return token == null || token.isEmpty ? null : token;
  }

  @override
  Future<DateTime?> readExpiresAt(String accountId) async {
    final raw = await _storage.read(key: _expiresKey(accountId));
    return raw == null ? null : DateTime.tryParse(raw)?.toUtc();
  }

  @override
  Future<void> writeSession({
    required String accountId,
    required String token,
    required DateTime expiresAt,
  }) async {
    await _storage.write(key: _tokenKey(accountId), value: token);
    await _storage.write(
      key: _expiresKey(accountId),
      value: expiresAt.toUtc().toIso8601String(),
    );
  }

  @override
  Future<void> clear(String accountId) async {
    await _storage.delete(key: _tokenKey(accountId));
    await _storage.delete(key: _expiresKey(accountId));
  }
}
