import '../../domain/entities/portfolio_holding.dart';
import '../../domain/entities/portfolio_quote.dart';

class MofidMarketQuoteModel {
  const MofidMarketQuoteModel({
    required this.symbolIsin,
    required this.bestBuyPriceRial,
    required this.bestBuyQuantity,
    required this.lastTradedPriceRial,
    required this.closingPriceRial,
    required this.previousCloseRial,
  });

  factory MofidMarketQuoteModel.fromJson(Map<String, dynamic> json) {
    return MofidMarketQuoteModel(
      symbolIsin: json['symbolIsin']?.toString() ?? '',
      bestBuyPriceRial: _num(json['bestBuyPrice']),
      bestBuyQuantity: _num(json['bestBuyQuantity']),
      lastTradedPriceRial: _num(json['lastTradedPrice']),
      closingPriceRial: _num(json['closingPrice']),
      previousCloseRial: _num(json['feeOfPreviousDaysClosingPrice']),
    );
  }

  final String symbolIsin;
  final num? bestBuyPriceRial;
  final num? bestBuyQuantity;
  final num? lastTradedPriceRial;
  final num? closingPriceRial;
  final num? previousCloseRial;

  PortfolioQuote toDomain() {
    final bestBuy = bestBuyPriceRial;
    final last = lastTradedPriceRial;
    final closing = closingPriceRial;

    final (price, basis) = bestBuy != null && bestBuy > 0
        ? (bestBuy, MarketPriceBasis.bestBuyOrder)
        : last != null && last > 0
            ? (last, MarketPriceBasis.lastTrade)
            : closing != null && closing > 0
                ? (closing, MarketPriceBasis.closingPrice)
                : (0, MarketPriceBasis.unavailable);

    return PortfolioQuote(
      symbolIsin: symbolIsin,
      marketPriceToman: price / 10,
      priceBasis: basis,
      previousCloseToman:
          previousCloseRial == null ? null : previousCloseRial! / 10,
      bestBuyQuantity: bestBuyQuantity,
    );
  }

  static num? _num(Object? value) {
    if (value is num) {
      return value;
    }
    return num.tryParse(value?.toString() ?? '');
  }
}
