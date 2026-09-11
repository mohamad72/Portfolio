import 'package:equatable/equatable.dart';

enum MarketPriceBasis {
  bestBuyOrder,
  lastTrade,
  closingPrice,
  unavailable,
}

class PortfolioHolding extends Equatable {
  const PortfolioHolding({
    required this.symbolIsin,
    required this.symbolName,
    required this.quantity,
    required this.marketPriceToman,
    this.marketPriceBasis = MarketPriceBasis.unavailable,
    this.breakEvenPriceToman,
    this.previousCloseToman,
    this.bestBuyQuantity,
  });

  final String symbolIsin;
  final String symbolName;
  final num quantity;
  final num marketPriceToman;
  final MarketPriceBasis marketPriceBasis;
  final num? breakEvenPriceToman;
  final num? previousCloseToman;
  final num? bestBuyQuantity;

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
