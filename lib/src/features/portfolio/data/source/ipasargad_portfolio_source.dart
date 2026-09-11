import 'package:dartz/dartz.dart';

import '../../../../shared/error/failure.dart';
import '../../../accounts/domain/entities/investment_account.dart';
import '../../domain/entities/account_snapshot.dart';

abstract interface class IPasargadPortfolioSource {
  Future<Either<Failure, AccountSnapshot>> getAccountSnapshot(
    InvestmentAccount account,
  );
}
