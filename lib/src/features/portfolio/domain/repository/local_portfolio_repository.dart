import 'package:dartz/dartz.dart';

import '../../../../shared/error/failure.dart';
import '../entities/holding_allocation.dart';
import '../entities/local_portfolio.dart';

abstract interface class LocalPortfolioRepository {
  Future<Either<Failure, List<LocalPortfolio>>> getPortfolios();

  Future<Either<Failure, Unit>> savePortfolio(LocalPortfolio portfolio);

  Future<Either<Failure, Unit>> deletePortfolio(String id);

  Future<Either<Failure, List<HoldingAllocation>>> getAllocations();

  Future<Either<Failure, Unit>> replaceHoldingAllocations(
    String holdingKey,
    List<HoldingAllocation> allocations,
  );
}
