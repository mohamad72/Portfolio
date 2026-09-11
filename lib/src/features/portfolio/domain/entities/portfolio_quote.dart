import 'package:equatable/equatable.dart';

import 'portfolio_holding.dart';

class PortfolioQuote extends Equatable {
  const PortfolioQuote({
    required this.symbolIsin,
    required this.marketPriceToman,
    required this.priceBasis,
    required this.previousCloseToman,
    required this.bestBuyQuantity,
  });

  final String symbolIsin;
  final num marketPriceToman;
  final MarketPriceBasis priceBasis;
  final num? previousCloseToman;
  final num? bestBuyQuantity;

  @override
  List<Object?> get props => <Object?>[
        symbolIsin,
        marketPriceToman,
        priceBasis,
        previousCloseToman,
        bestBuyQuantity,
      ];
}
