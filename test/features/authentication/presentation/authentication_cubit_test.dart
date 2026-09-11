import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/src/features/authentication/domain/entities/mofid_session.dart';
import 'package:portfolio/src/features/authentication/domain/repository/authentication_repository.dart';
import 'package:portfolio/src/features/authentication/presentation/manager/authentication_cubit.dart';
import 'package:portfolio/src/features/authentication/presentation/manager/authentication_state.dart';
import 'package:portfolio/src/shared/error/failure.dart';

class _Repository implements AuthenticationRepository {
  bool hasSessionValue = false;
  bool hasSavedCredentialsValue = false;
  bool canBiometricValue = false;
  bool biometricAccepted = true;
  int savedLoginCount = 0;

  static const _session = MofidSession(
    accessToken: 'token',
    tokenType: 'Bearer',
    expiresInSeconds: 3600,
  );

  @override
  Future<Either<Failure, Unit>> authenticateWithBiometrics() async =>
      biometricAccepted
          ? right(unit)
          : left(const Failure('اثر انگشت تأیید نشد.'));

  @override
  Future<bool> canAuthenticateWithBiometrics() async => canBiometricValue;

  @override
  Future<bool> hasSavedCredentials() async => hasSavedCredentialsValue;

  @override
  Future<bool> hasSession() async => hasSessionValue;

  @override
  Future<Either<Failure, MofidSession>> login({
    required String username,
    required String password,
  }) async => right(_session);

  @override
  Future<Either<Failure, MofidSession>> loginWithSavedCredentials() async {
    savedLoginCount++;
    hasSessionValue = true;
    return right(_session);
  }

  @override
  Future<void> logout({bool forgetCredentials = false}) async {
    hasSessionValue = false;
    if (forgetCredentials) {
      hasSavedCredentialsValue = false;
    }
  }
}

void main() {
  test('startup requests biometrics when saved credentials are available', () async {
    final repository = _Repository()
      ..hasSavedCredentialsValue = true
      ..canBiometricValue = true
      ..hasSessionValue = true;
    final cubit = AuthenticationCubit(repository);

    await cubit.checkSession();

    expect(cubit.state, const AuthenticationBiometricRequired());
  });

  test('successful biometric unlock reuses valid session', () async {
    final repository = _Repository()
      ..hasSavedCredentialsValue = true
      ..canBiometricValue = true
      ..hasSessionValue = true;
    final cubit = AuthenticationCubit(repository);
    await cubit.checkSession();

    await cubit.unlockWithBiometrics();

    expect(cubit.state, const AuthenticationSignedIn());
    expect(repository.savedLoginCount, 0);
  });

  test('successful biometric unlock re-logins when token is expired', () async {
    final repository = _Repository()
      ..hasSavedCredentialsValue = true
      ..canBiometricValue = true
      ..hasSessionValue = false;
    final cubit = AuthenticationCubit(repository);
    await cubit.checkSession();

    await cubit.unlockWithBiometrics();

    expect(cubit.state, const AuthenticationSignedIn());
    expect(repository.savedLoginCount, 1);
  });
}
