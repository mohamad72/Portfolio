import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../shared/error/failure.dart';
import '../entities/account_snapshot.dart';
import '../repository/portfolio_repository.dart';

@lazySingleton
class GetAccountSnapshot {
  const GetAccountSnapshot(this._repository);

  final PortfolioRepository _repository;

  Future<Either<Failure, AccountSnapshot>> call() =>
      _repository.getAccountSnapshot();
}
