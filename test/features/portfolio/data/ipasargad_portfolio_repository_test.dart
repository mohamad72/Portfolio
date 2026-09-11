import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/src/features/accounts/data/security/ipasargad_session_store.dart';
import 'package:portfolio/src/features/accounts/domain/entities/broker_provider.dart';
import 'package:portfolio/src/features/accounts/domain/entities/investment_account.dart';
import 'package:portfolio/src/features/portfolio/data/repository/ipasargad_portfolio_repository_impl.dart';
import 'package:portfolio/src/features/portfolio/domain/entities/portfolio_holding.dart';
import 'package:portfolio/src/shared/network/remote_data_source.dart';

class _Remote implements RemoteDataSource {
  final List<Map<String, dynamic>?> seenHeaders = <Map<String, dynamic>?>[];

  @override
  Future<Map<String, dynamic>> getJson(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    seenHeaders.add(headers);
    if (url.endsWith('/api/request/getcustomerevidences')) {
      return <String, dynamic>{
        'result': <Object?>[
          <String, dynamic>{
            'volume': 1000,
            'remainVolume': 1000,
            'mutualFundCode': '12462',
            'mutualFundId': 3,
            'mutualFundSymbol': 'ریتون',
            'sellPrice': 25000,
            'buyPrice': 25100,
          },
        ],
        'isError': false,
      };
    }
    throw StateError('Unexpected GET $url');
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String url, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    seenHeaders.add(headers);
    if (url.endsWith('/api/requestdailyposition/getcustomerrequestcomposition')) {
      return <String, dynamic>{
        'result': <Object?>[
          <String, dynamic>{
            'remainVolume': 1000,
            'netValue': 25000000,
            'mutualFundId': 3,
            'mutualFundTitle': 'صندوق سرمایه‌گذاری طلای ریتون',
            'mutualFundSymbol': 'ریتون',
            'mutualFundCode': '12462',
            'symbol': 'ریتون',
            'isin': 'IRTKRITO0001',
          },
        ],
        'isError': false,
      };
    }
    if (url.endsWith('/api/requestdailyposition/getprofitorloss')) {
      return <String, dynamic>{
        'result': <Object?>[
          <String, dynamic>{
            'isin': 'IRTKRITO0001',
            'remainVolume': 1000,
            'buyAvgPrice': 20000,
            'lastTradedPrice': 25100,
            'prevClosePrice': 24000,
            'profitOrLoss': 5000000,
            'todayProfitOrLoss': 1000000,
          },
        ],
        'isError': false,
      };
    }
    throw StateError('Unexpected POST $url');
  }

  @override
  Future<Map<String, dynamic>> postForm(
    String url, {
    required Map<String, dynamic> body,
    Map<String, dynamic>? headers,
  }) => throw UnimplementedError();
}

class _Session implements IPasargadSessionStore {
  @override
  Future<void> clear(String accountId) async {}

  @override
  Future<DateTime?> readExpiresAt(String accountId) async =>
      DateTime.now().toUtc().add(const Duration(hours: 1));

  @override
  Future<String?> readToken(String accountId) async => 'ipas-token';

  @override
  Future<void> writeSession({
    required String accountId,
    required String token,
    required DateTime expiresAt,
  }) async {}
}

void main() {
  test('maps Riton holding, keeps source account, and converts observed rial values once', () async {
    final remote = _Remote();
    final repository = IPasargadPortfolioRepositoryImpl(remote, _Session());
    const account = InvestmentAccount(
      id: 'ipas-1',
      provider: BrokerProvider.iPasargad,
      label: 'آی‌پاسارگاد',
    );

    final result = await repository.getAccountSnapshot(account);

    result.fold(
      (failure) => fail(failure.message),
      (snapshot) {
        expect(snapshot.holdings, hasLength(1));
        final holding = snapshot.holdings.single;
        expect(holding.accountId, 'ipas-1');
        expect(holding.accountLabel, 'آی‌پاسارگاد');
        expect(holding.symbolIsin, 'IRTKRITO0001');
        expect(holding.quantity, 1000);
        expect(holding.marketPriceToman, 2500);
        expect(holding.breakEvenPriceToman, 2000);
        expect(holding.previousCloseToman, 2400);
        expect(holding.marketPriceBasis, MarketPriceBasis.sourceSellPrice);
        expect(holding.currentValueToman, 2500000);
      },
    );
    expect(
      remote.seenHeaders.every(
        (headers) => headers?['Cookie'] == 'otauth-FU=ipas-token',
      ),
      isTrue,
    );
  });
}
