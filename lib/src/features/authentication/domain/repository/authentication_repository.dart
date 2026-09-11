import 'package:dartz/dartz.dart';

import '../../../../shared/error/failure.dart';
import '../entities/mofid_session.dart';

abstract interface class AuthenticationRepository {
  Future<Either<Failure, MofidSession>> exchangeAuthorizationCode({
    required String code,
    required String codeVerifier,
  });

  Future<bool> hasSession();

  Future<void> logout();
}
