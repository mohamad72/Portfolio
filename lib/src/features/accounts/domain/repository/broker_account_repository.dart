import 'package:dartz/dartz.dart';

import '../../../../shared/error/failure.dart';
import '../entities/investment_account.dart';

abstract interface class BrokerAccountRepository {
  Future<Either<Failure, List<InvestmentAccount>>> getAccounts();

  Future<Either<Failure, Unit>> saveAccount(InvestmentAccount account);

  Future<Either<Failure, Unit>> deleteAccount(String id);
}
