import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../shared/error/failure.dart';
import '../entities/local_portfolio.dart';
import '../repository/local_portfolio_repository.dart';

@lazySingleton
class GetLocalPortfolios {
  const GetLocalPortfolios(this._repository);

  final LocalPortfolioRepository _repository;

  Future<Either<Failure, List<LocalPortfolio>>> call() =>
      _repository.getPortfolios();
}
