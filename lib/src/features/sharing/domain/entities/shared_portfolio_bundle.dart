import 'package:equatable/equatable.dart';

import '../../../portfolio/domain/entities/account_snapshot.dart';
import '../../../portfolio/domain/entities/holding_allocation.dart';
import '../../../portfolio/domain/entities/local_portfolio.dart';
import '../../../portfolio/domain/entities/portfolio_holding.dart';

class SharedPortfolioBundle extends Equatable {
  const SharedPortfolioBundle({
    required this.snapshot,
    required this.portfolios,
    required this.allocations,
    required this.publishedAt,
  });

  static const String totalPortfolioId = '__total__';
  static const String unallocatedPortfolioId = '__unallocated__';

  final AccountSnapshot snapshot;
  final List<LocalPortfolio> portfolios;
  final List<HoldingAllocation> allocations;
  final DateTime publishedAt;

  num allocatedQuantity(String holdingKey, String portfolioId) => allocations
      .where(
        (item) =>
            item.holdingKey == holdingKey && item.portfolioId == portfolioId,
      )
      .fold<num>(0, (sum, item) => sum + item.quantity);

  num totalAllocatedQuantity(String holdingKey) => allocations
      .where((item) => item.holdingKey == holdingKey)
      .fold<num>(0, (sum, item) => sum + item.quantity);

  num unallocatedQuantity(String holdingKey) {
    final holding = snapshot.holdings
        .where((item) => item.holdingKey == holdingKey)
        .firstOrNull;
    if (holding == null) {
      return 0;
    }
    final value = holding.quantity - totalAllocatedQuantity(holdingKey);
    return value < 0 ? 0 : value;
  }

  List<PortfolioHolding> holdingsForPortfolio(String portfolioId) {
    if (portfolioId == totalPortfolioId) {
      return snapshot.holdings;
    }

    final result = <PortfolioHolding>[];
    for (final holding in snapshot.holdings) {
      final quantity = portfolioId == unallocatedPortfolioId
          ? unallocatedQuantity(holding.holdingKey)
          : allocatedQuantity(holding.holdingKey, portfolioId);
      if (quantity > 0) {
        result.add(holding.copyWith(quantity: quantity));
      }
    }
    return result;
  }

  String portfolioTitle(String portfolioId) {
    if (portfolioId == totalPortfolioId) {
      return 'کل دارایی';
    }
    if (portfolioId == unallocatedPortfolioId) {
      return 'تخصیص‌نیافته';
    }
    return portfolios
            .where((item) => item.id == portfolioId)
            .map((item) => item.name)
            .firstOrNull ??
        'سبد';
  }

  @override
  List<Object?> get props => <Object?>[
        snapshot,
        portfolios,
        allocations,
        publishedAt,
      ];
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
