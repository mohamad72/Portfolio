import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

class SavedMofidCredentials {
  const SavedMofidCredentials({
    required this.username,
    required this.password,
  });

  final String username;
  final String password;
}

abstract interface class MofidCredentialStore {
  Future<SavedMofidCredentials?> read();

  Future<void> write({required String username, required String password});

  Future<void> clear();
}

@LazySingleton(as: MofidCredentialStore)
class SecureMofidCredentialStore implements MofidCredentialStore {
  SecureMofidCredentialStore(this._storage);

  static const String _usernameKey = 'mofid_saved_username';
  static const String _passwordKey = 'mofid_saved_password';

  final FlutterSecureStorage _storage;

  @override
  Future<SavedMofidCredentials?> read() async {
    final username = await _storage.read(key: _usernameKey);
    final password = await _storage.read(key: _passwordKey);
    if (username == null || username.isEmpty || password == null) {
      return null;
    }
    return SavedMofidCredentials(username: username, password: password);
  }

  @override
  Future<void> write({
    required String username,
    required String password,
  }) async {
    await _storage.write(key: _usernameKey, value: username);
    await _storage.write(key: _passwordKey, value: password);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _passwordKey);
  }
}
