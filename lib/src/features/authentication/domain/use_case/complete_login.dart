import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../shared/error/failure.dart';
import '../entities/mofid_session.dart';
import '../repository/authentication_repository.dart';

@lazySingleton
class CompleteLogin {
  const CompleteLogin(this._repository);

  final AuthenticationRepository _repository;

  Future<Either<Failure, MofidSession>> call({
    required String code,
    required String codeVerifier,
  }) =>
      _repository.exchangeAuthorizationCode(
        code: code,
        codeVerifier: codeVerifier,
      );
}
