import 'package:dartz/dartz.dart';

import '../../../../shared/error/failure.dart';
import '../entities/investment_account.dart';
import '../entities/ipasargad_captcha.dart';

abstract interface class IPasargadAuthenticationRepository {
  Future<Either<Failure, IPasargadCaptcha>> getCaptcha();

  Future<Either<Failure, InvestmentAccount>> login({
    required String loginName,
    required String password,
    required String captchaValue,
    required String captchaHash,
    required String captchaSalt,
    required String accountLabel,
  });

  Future<void> logout(String accountId);
}
