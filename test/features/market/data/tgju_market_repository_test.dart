import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/src/features/market/data/repository/tgju_market_repository_impl.dart';
import 'package:portfolio/src/shared/network/remote_data_source.dart';

class _FakeRemoteDataSource implements RemoteDataSource {
  @override
  Future<Map<String, dynamic>> getJson(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    return <String, dynamic>{
      'current': <String, dynamic>{
        'price_dollar_rl': <String, dynamic>{
          'p': '2,359,750',
          'd': '0',
          'dp': 0,
          'ts': '2026-09-10 00:00:00',
        },
        'geram18': <String, dynamic>{
          'p': '241,814,000',
          'd': '0',
          'dp': 0,
          'ts': '2026-09-10 00:00:00',
        },
      },
    };
  }
}

void main() {
  test('repository returns available selected TGJU instruments', () async {
    final repository = TgjuMarketRepositoryImpl(_FakeRemoteDataSource());

    final result = await repository.getPrices();

    result.fold(
      (failure) => fail('Expected success, got ${failure.message}'),
      (prices) {
        expect(prices.any((price) => price.code == 'price_dollar_rl'), isTrue);
        expect(prices.any((price) => price.code == 'geram18'), isTrue);
      },
    );
  });
}
