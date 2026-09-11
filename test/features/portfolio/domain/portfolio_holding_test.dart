import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/src/features/accounts/domain/entities/broker_provider.dart';
import 'package:portfolio/src/features/portfolio/domain/entities/portfolio_holding.dart';

void main() {
  test('currentValueToman multiplies allocated quantity by market price', () {
    const holding = PortfolioHolding(
      accountId: 'mofid-primary',
      accountLabel: 'مفید',
      provider: BrokerProvider.mofid,
      symbolIsin: 'IRTKMOFD0001',
      symbolName: 'عیار',
      quantity: 125,
      marketPriceToman: 42000,
      marketPriceBasis: MarketPriceBasis.lastTrade,
    );

    expect(holding.currentValueToman, 5250000);
  });

  test('same symbol in different accounts has a different holding key', () {
    const mofid = PortfolioHolding(
      accountId: 'mofid-primary',
      accountLabel: 'مفید',
      provider: BrokerProvider.mofid,
      symbolIsin: 'IRTKRITO0001',
      symbolName: 'ریتون',
      quantity: 1,
      marketPriceToman: 1,
    );
    const ipasargad = PortfolioHolding(
      accountId: 'ipas-1',
      accountLabel: 'آی‌پاسارگاد',
      provider: BrokerProvider.iPasargad,
      symbolIsin: 'IRTKRITO0001',
      symbolName: 'ریتون',
      quantity: 1,
      marketPriceToman: 1,
    );

    expect(mofid.holdingKey, 'mofid-primary::IRTKRITO0001');
    expect(ipasargad.holdingKey, 'ipas-1::IRTKRITO0001');
    expect(mofid.holdingKey, isNot(ipasargad.holdingKey));
  });
}
