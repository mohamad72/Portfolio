import 'package:equatable/equatable.dart';

class PortfolioHolding extends Equatable {
  const PortfolioHolding({
    required this.symbolIsin,
    required this.symbolName,
    required this.quantity,
    required this.marketPriceToman,
  });

  final String symbolIsin;
  final String symbolName;
  final num quantity;
  final num marketPriceToman;

  num get currentValueToman => quantity * marketPriceToman;

  @override
  List<Object?> get props => <Object?>[
        symbolIsin,
        symbolName,
        quantity,
        marketPriceToman,
      ];
}
