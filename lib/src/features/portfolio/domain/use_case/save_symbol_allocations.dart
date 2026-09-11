import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../shared/error/failure.dart';
import '../entities/holding_allocation.dart';
import '../repository/local_portfolio_repository.dart';

@lazySingleton
class SaveSymbolAllocations {
  const SaveSymbolAllocations(this._repository);

  final LocalPortfolioRepository _repository;

  Future<Either<Failure, Unit>> call({
    required String symbolIsin,
    required num totalQuantity,
    required Map<String, num> allocations,
  }) async {
    if (totalQuantity < 0) {
      return left(const Failure('موجودی کل نمی‌تواند منفی باشد.'));
    }
    if (allocations.values.any((quantity) => quantity < 0)) {
      return left(const Failure('مقدار تخصیص نمی‌تواند منفی باشد.'));
    }

    final allocated = allocations.values.fold<num>(
      0,
      (sum, quantity) => sum + quantity,
    );
    if (allocated > totalQuantity) {
      return left(const Failure('مجموع تخصیص از موجودی کل نماد بیشتر است.'));
    }

    final now = DateTime.now();
    final records = allocations.entries
        .where((entry) => entry.value > 0)
        .map(
          (entry) => HoldingAllocation(
            portfolioId: entry.key,
            symbolIsin: symbolIsin,
            quantity: entry.value,
            effectiveAt: now,
          ),
        )
        .toList(growable: false);

    return _repository.replaceSymbolAllocations(symbolIsin, records);
  }
}
