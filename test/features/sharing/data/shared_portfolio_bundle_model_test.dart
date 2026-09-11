import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/src/features/accounts/domain/entities/broker_provider.dart';
import 'package:portfolio/src/features/portfolio/domain/entities/account_snapshot.dart';
import 'package:portfolio/src/features/portfolio/domain/entities/holding_allocation.dart';
import 'package:portfolio/src/features/portfolio/domain/entities/local_portfolio.dart';
import 'package:portfolio/src/features/portfolio/domain/entities/portfolio_holding.dart';
import 'package:portfolio/src/features/sharing/data/models/shared_portfolio_bundle_model.dart';
import 'package:portfolio/src/features/sharing/domain/entities/shared_portfolio_bundle.dart';

void main() {
  test('round-trips account-aware shared holdings and allocations', () {
    final bundle = SharedPortfolioBundle(
      snapshot: AccountSnapshot(
        holdings: const <PortfolioHolding>[
          PortfolioHolding(
            accountId: 'ipas-1',
            accountLabel: 'آی‌پاسارگاد',
            provider: BrokerProvider.iPasargad,
            symbolIsin: 'IRTEST000001',
            symbolName: 'نمونه',
            quantity: 120,
            marketPriceToman: 1250,
            marketPriceBasis: MarketPriceBasis.sourceSellPrice,
            breakEvenPriceToman: 1000,
            previousCloseToman: 1200,
            bestBuyQuantity: 80,
          ),
        ],
        buyingPowerToman: 500000,
        syncedAt: DateTime.utc(2026, 9, 11, 12),
        ayarPriceToman: 25000,
      ),
      portfolios: <LocalPortfolio>[
        LocalPortfolio(
          id: 'mine',
          name: 'من',
          createdAt: DateTime.utc(2026, 9, 1),
        ),
      ],
      allocations: <HoldingAllocation>[
        HoldingAllocation(
          portfolioId: 'mine',
          holdingKey: 'ipas-1::IRTEST000001',
          symbolIsin: 'IRTEST000001',
          quantity: 70,
          effectiveAt: DateTime.utc(2026, 9, 11),
        ),
      ],
      publishedAt: DateTime.utc(2026, 9, 11, 12, 5),
    );

    final json = SharedPortfolioBundleModel.fromDomain(bundle).toJson();
    final decoded = SharedPortfolioBundleModel.fromJson(json).toDomain();

    expect(decoded, bundle);
    expect(decoded.holdingsForPortfolio('mine').single.quantity, 70);
    expect(decoded.unallocatedQuantity('ipas-1::IRTEST000001'), 50);
  });
}
