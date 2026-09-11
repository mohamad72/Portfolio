import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/src/features/portfolio/domain/entities/portfolio_holding.dart';

void main() {
  test('currentValueToman multiplies allocated quantity by market price', () {
    const holding = PortfolioHolding(
      symbolIsin: 'IRTKMOFD0001',
      symbolName: 'عیار',
      quantity: 125,
      marketPriceToman: 42000,
    );

    expect(holding.currentValueToman, 5250000);
  });
}
