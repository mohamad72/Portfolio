import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/src/features/market/data/mapper/tgju_market_mapper.dart';

void main() {
  const mapper = TgjuMarketMapper();

  test('maps confirmed rial value to toman and keeps source timestamp', () {
    final price = mapper.map(
      code: 'price_dollar_rl',
      title: 'دلار آزاد',
      raw: const <String, dynamic>{
        'p': '2,359,750',
        'd': '10,000',
        'dp': 0.42,
        'dt': 'high',
        'ts': '2026-09-10 00:00:00',
      },
    );

    expect(price.priceToman, 235975);
    expect(price.changeToman, 1000);
    expect(price.changePercent, 0.42);
    expect(price.sourceTimestampRaw, '2026-09-10 00:00:00');
  });

  test('returns null money instead of zero when source price is missing', () {
    final price = mapper.map(
      code: 'price_dollar_rl',
      title: 'دلار آزاد',
      raw: const <String, dynamic>{'p': null, 'dp': null},
    );

    expect(price.priceToman, isNull);
    expect(price.changePercent, isNull);
  });

  test('does not relabel coin bubble as gold bubble', () {
    final price = mapper.map(
      code: 'coin_blubber',
      title: 'حباب سکه امامی',
      raw: const <String, dynamic>{'p': '13,920,000', 'dp': 0},
    );

    expect(price.title, 'حباب سکه امامی');
    expect(price.code, 'coin_blubber');
  });
}
