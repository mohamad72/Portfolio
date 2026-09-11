import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/src/features/portfolio/data/repository/mofid_portfolio_repository_impl.dart';
import 'package:portfolio/src/features/portfolio/domain/entities/portfolio_holding.dart';
import 'package:portfolio/src/shared/network/remote_data_source.dart';
import 'package:portfolio/src/shared/security/secure_session_store.dart';

class _PortfolioRemote implements RemoteDataSource {
  @override
  Future<Map<String, dynamic>> getJson(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    if (url.endsWith('/assetmodule/api/performance')) {
      return <String, dynamic>{
        'items': <Object?>[
          <String, dynamic>{
            'symbolIsin': 'IRTKMOFD0001',
            'symbolName': 'عیار',
            'asset': 10,
            'breakevenPoint': 560000,
          },
        ],
      };
    }
    if (url.endsWith('/easy/api/money')) {
      return <String, dynamic>{'buyPowerT2': 1000000};
    }
    throw StateError('Unexpected GET: $url');
  }

  @override
  Future<Map<String, dynamic>> postForm(
    String url, {
    required Map<String, dynamic> body,
    Map<String, dynamic>? headers,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String url, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    return <String, dynamic>{
      'data': <String, dynamic>{
        'marketData': <Object?>[
          <String, dynamic>{
            'symbolIsin': 'IRTKMOFD0001',
            'bestBuyPrice': 600000,
            'bestBuyQuantity': 500,
            'lastTradedPrice': 599000,
            'closingPrice': 598000,
            'feeOfPreviousDaysClosingPrice': 590000,
          },
        ],
      },
    };
  }
}

class _TokenStore implements SessionStore {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> readAccessToken() async => 'token';

  @override
  Future<String?> readAccountKey() async => 'account';

  @override
  Future<DateTime?> readExpiresAt() async =>
      DateTime.now().toUtc().add(const Duration(hours: 1));

  @override
  Future<void> writeSession({
    required String accessToken,
    required String accountKey,
    required DateTime expiresAt,
  }) async {}
}

void main() {
  test('maps current quantity and best-buy quote from rial to toman', () async {
    final repository = MofidPortfolioRepositoryImpl(
      _PortfolioRemote(),
      _TokenStore(),
    );

    final result = await repository.getAccountSnapshot();

    result.fold(
      (failure) => fail(failure.message),
      (snapshot) {
        expect(snapshot.buyingPowerToman, 100000);
        expect(snapshot.holdings, hasLength(1));
        final holding = snapshot.holdings.single;
        expect(holding.quantity, 10);
        expect(holding.marketPriceToman, 60000);
        expect(holding.breakEvenPriceToman, 56000);
        expect(holding.marketPriceBasis, MarketPriceBasis.bestBuyOrder);
      },
    );
  });
}
