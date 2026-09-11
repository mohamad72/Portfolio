import 'package:equatable/equatable.dart';

import '../../../accounts/domain/entities/broker_provider.dart';

enum MarketPriceBasis {
  bestBuyOrder,
  lastTrade,
  closingPrice,
  sourceSellPrice,
  unavailable,
}

class PortfolioHolding extends Equatable {
  const PortfolioHolding({
    required this.accountId,
    required this.accountLabel,
    required this.provider,
    required this.symbolIsin,
    required this.symbolName,
    required this.quantity,
    required this.marketPriceToman,
    this.marketPriceBasis = MarketPriceBasis.unavailable,
    this.breakEvenPriceToman,
    this.previousCloseToman,
    this.bestBuyQuantity,
  });

  final String accountId;
  final String accountLabel;
  final BrokerProvider provider;
  final String symbolIsin;
  final String symbolName;
  final num quantity;
  final num marketPriceToman;
  final MarketPriceBasis marketPriceBasis;
  final num? breakEvenPriceToman;
  final num? previousCloseToman;
  final num? bestBuyQuantity;

  String get holdingKey => '$accountId::$symbolIsin';

  num? get currentValueToman => marketPriceBasis == MarketPriceBasis.unavailable
      ? null
      : quantity * marketPriceToman;

  num? get estimatedUnrealizedProfitToman {
    final breakEven = breakEvenPriceToman;
    if (breakEven == null || marketPriceBasis == MarketPriceBasis.unavailable) {
      return null;
    }
    return quantity * (marketPriceToman - breakEven);
  }

  double? get priceChangePercent {
    final previous = previousCloseToman;
    if (previous == null ||
        previous == 0 ||
        marketPriceBasis == MarketPriceBasis.unavailable) {
      return null;
    }
    return ((marketPriceToman / previous) - 1) * 100;
  }

  PortfolioHolding copyWith({num? quantity}) => PortfolioHolding(
        accountId: accountId,
        accountLabel: accountLabel,
        provider: provider,
        symbolIsin: symbolIsin,
        symbolName: symbolName,
        quantity: quantity ?? this.quantity,
        marketPriceToman: marketPriceToman,
        marketPriceBasis: marketPriceBasis,
        breakEvenPriceToman: breakEvenPriceToman,
        previousCloseToman: previousCloseToman,
        bestBuyQuantity: bestBuyQuantity,
      );

  @override
  List<Object?> get props => <Object?>[
        accountId,
        accountLabel,
        provider,
        symbolIsin,
        symbolName,
        quantity,
        marketPriceToman,
        marketPriceBasis,
        breakEvenPriceToman,
        previousCloseToman,
        bestBuyQuantity,
      ];
}
