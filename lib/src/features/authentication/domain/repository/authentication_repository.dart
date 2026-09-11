import 'package:dartz/dartz.dart';

import '../../../../shared/error/failure.dart';
import '../entities/mofid_session.dart';

abstract interface class AuthenticationRepository {
  Future<Either<Failure, MofidSession>> login({
    required String username,
    required String password,
  });

  Future<Either<Failure, MofidSession>> loginWithSavedCredentials();

  Future<bool> hasSession();

  Future<bool> hasSavedCredentials();

  Future<bool> canAuthenticateWithBiometrics();

  Future<Either<Failure, Unit>> authenticateWithBiometrics();

  Future<void> logout({bool forgetCredentials = false});
}
