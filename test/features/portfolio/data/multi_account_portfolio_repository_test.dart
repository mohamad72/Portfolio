import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/src/features/accounts/domain/entities/broker_provider.dart';
import 'package:portfolio/src/features/accounts/domain/entities/investment_account.dart';
import 'package:portfolio/src/features/accounts/domain/repository/broker_account_repository.dart';
import 'package:portfolio/src/features/portfolio/data/repository/multi_account_portfolio_repository_impl.dart';
import 'package:portfolio/src/features/portfolio/data/source/ipasargad_portfolio_source.dart';
import 'package:portfolio/src/features/portfolio/data/source/mofid_portfolio_source.dart';
import 'package:portfolio/src/features/portfolio/domain/entities/account_snapshot.dart';
import 'package:portfolio/src/features/portfolio/domain/entities/portfolio_holding.dart';
import 'package:portfolio/src/features/portfolio/domain/entities/portfolio_quote.dart';
import 'package:portfolio/src/shared/error/failure.dart';

class _Accounts implements BrokerAccountRepository {
  @override
  Future<Either<Failure, List<InvestmentAccount>>> getAccounts() async => right(
        const <InvestmentAccount>[
          InvestmentAccount(
            id: 'ipas-1',
            provider: BrokerProvider.iPasargad,
            label: 'آی‌پاسارگاد',
          ),
        ],
      );

  @override
  Future<Either<Failure, Unit>> saveAccount(InvestmentAccount account) async =>
      right(unit);

  @override
  Future<Either<Failure, Unit>> deleteAccount(String id) async => right(unit);
}

class _Mofid implements MofidPortfolioSource {
  @override
  Future<Either<Failure, AccountSnapshot>> getAccountSnapshot() async => right(
        AccountSnapshot(
          holdings: const <PortfolioHolding>[
            PortfolioHolding(
              accountId: 'mofid-primary',
              accountLabel: 'مفید',
              provider: BrokerProvider.mofid,
              symbolIsin: 'IRTKRITO0001',
              symbolName: 'ریتون',
              quantity: 100,
              marketPriceToman: 2300,
              marketPriceBasis: MarketPriceBasis.bestBuyOrder,
            ),
          ],
          buyingPowerToman: 1000,
          syncedAt: DateTime(2026, 9, 11),
          ayarPriceToman: 50000,
        ),
      );

  @override
  Future<Either<Failure, Map<String, PortfolioQuote>>> getQuotes(
    List<String> symbolIsins,
  ) async => right(const <String, PortfolioQuote>{});
}

class _IPasargad implements IPasargadPortfolioSource {
  @override
  Future<Either<Failure, AccountSnapshot>> getAccountSnapshot(
    InvestmentAccount account,
  ) async => right(
        AccountSnapshot(
          holdings: <PortfolioHolding>[
            PortfolioHolding(
              accountId: account.id,
              accountLabel: account.label,
              provider: account.provider,
              symbolIsin: 'IRTKRITO0001',
              symbolName: 'ریتون',
              quantity: 200,
              marketPriceToman: 2259,
              marketPriceBasis: MarketPriceBasis.sourceSellPrice,
            ),
          ],
          buyingPowerToman: 0,
          syncedAt: DateTime(2026, 9, 11),
        ),
      );
}

void main() {
  test('same ISIN in Mofid and iPasargad remains two holdings', () async {
    final repository = MultiAccountPortfolioRepositoryImpl(
      _Mofid(),
      _IPasargad(),
      _Accounts(),
    );

    final result = await repository.getAccountSnapshot();

    result.fold(
      (failure) => fail(failure.message),
      (snapshot) {
        expect(snapshot.holdings, hasLength(2));
        expect(
          snapshot.holdings.map((item) => item.holdingKey).toSet(),
          hasLength(2),
        );
        expect(
          snapshot.holdings.map((item) => item.accountLabel),
          containsAll(<String>['مفید', 'آی‌پاسارگاد']),
        );
      },
    );
  });
}
