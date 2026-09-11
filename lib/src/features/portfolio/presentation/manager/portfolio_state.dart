import 'package:equatable/equatable.dart';

import '../../domain/entities/account_snapshot.dart';
import '../../domain/entities/holding_allocation.dart';
import '../../domain/entities/local_portfolio.dart';
import '../../domain/entities/portfolio_holding.dart';

enum PortfolioValueUnit { toman, ayar }

sealed class PortfolioState extends Equatable {
  const PortfolioState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class PortfolioInitial extends PortfolioState {
  const PortfolioInitial();
}

final class PortfolioLoading extends PortfolioState {
  const PortfolioLoading();
}

final class PortfolioError extends PortfolioState {
  const PortfolioError(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

final class PortfolioLoaded extends PortfolioState {
  const PortfolioLoaded({
    required this.snapshot,
    required this.portfolios,
    required this.allocations,
    required this.selectedPortfolioId,
    this.valueUnit = PortfolioValueUnit.toman,
  });

  static const String totalPortfolioId = '__total__';
  static const String unallocatedPortfolioId = '__unallocated__';

  final AccountSnapshot snapshot;
  final List<LocalPortfolio> portfolios;
  final List<HoldingAllocation> allocations;
  final String selectedPortfolioId;
  final PortfolioValueUnit valueUnit;

  String get selectedTitle {
    if (selectedPortfolioId == totalPortfolioId) {
      return 'کل دارایی';
    }
    if (selectedPortfolioId == unallocatedPortfolioId) {
      return 'تخصیص‌نیافته';
    }
    return portfolios
        .where((item) => item.id == selectedPortfolioId)
        .map((item) => item.name)
        .firstOrNull ??
        'سبد محلی';
  }

  List<PortfolioHolding> get visibleHoldings {
    if (selectedPortfolioId == totalPortfolioId) {
      return snapshot.holdings;
    }

    final result = <PortfolioHolding>[];
    for (final holding in snapshot.holdings) {
      final quantity = selectedPortfolioId == unallocatedPortfolioId
          ? unallocatedQuantity(holding)
          : allocatedQuantity(holding.holdingKey, selectedPortfolioId);
      if (quantity > 0) {
        result.add(holding.copyWith(quantity: quantity));
      }
    }
    return result;
  }

  num? get visibleHoldingsValueToman {
    var total = 0.0;
    for (final holding in visibleHoldings) {
      final value = holding.currentValueToman;
      if (value == null) {
        return null;
      }
      total += value.toDouble();
    }
    return total;
  }

  num allocatedQuantity(String holdingKey, String portfolioId) => allocations
      .where(
        (item) =>
            item.holdingKey == holdingKey && item.portfolioId == portfolioId,
      )
      .fold<num>(0, (sum, item) => sum + item.quantity);

  num totalAllocatedQuantity(String holdingKey) => allocations
      .where((item) => item.holdingKey == holdingKey)
      .fold<num>(0, (sum, item) => sum + item.quantity);

  num unallocatedQuantity(PortfolioHolding holding) {
    final value = holding.quantity - totalAllocatedQuantity(holding.holdingKey);
    return value < 0 ? 0 : value;
  }

  PortfolioLoaded copyWith({
    AccountSnapshot? snapshot,
    List<LocalPortfolio>? portfolios,
    List<HoldingAllocation>? allocations,
    String? selectedPortfolioId,
    PortfolioValueUnit? valueUnit,
  }) =>
      PortfolioLoaded(
        snapshot: snapshot ?? this.snapshot,
        portfolios: portfolios ?? this.portfolios,
        allocations: allocations ?? this.allocations,
        selectedPortfolioId: selectedPortfolioId ?? this.selectedPortfolioId,
        valueUnit: valueUnit ?? this.valueUnit,
      );

  @override
  List<Object?> get props => <Object?>[
        snapshot,
        portfolios,
        allocations,
        selectedPortfolioId,
        valueUnit,
      ];
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
