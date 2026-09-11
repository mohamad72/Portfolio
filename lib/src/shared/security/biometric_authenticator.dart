import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';

abstract interface class BiometricAuthenticator {
  Future<bool> canAuthenticate();

  Future<bool> authenticate();
}

@LazySingleton(as: BiometricAuthenticator)
class LocalBiometricAuthenticator implements BiometricAuthenticator {
  LocalBiometricAuthenticator(this._localAuthentication);

  final LocalAuthentication _localAuthentication;

  @override
  Future<bool> canAuthenticate() async {
    final supported = await _localAuthentication.isDeviceSupported();
    if (!supported || !await _localAuthentication.canCheckBiometrics) {
      return false;
    }
    final available = await _localAuthentication.getAvailableBiometrics();
    return available.isNotEmpty;
  }

  @override
  Future<bool> authenticate() => _localAuthentication.authenticate(
        localizedReason: 'برای ورود به پرتفوی اثر انگشت را تأیید کنید.',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
}
