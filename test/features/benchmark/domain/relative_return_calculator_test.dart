import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/src/features/benchmark/domain/relative_return_calculator.dart';

void main() {
  const calculator = RelativeReturnCalculator();

  test('calculates relative return versus Ayar', () {
    final value = calculator.calculate(
      portfolioReturn: 0.10,
      benchmarkReturn: 0.20,
    );

    expect(value, closeTo(-0.0833333333, 0.0000001));
  });

  test('returns null when benchmark denominator is zero', () {
    final value = calculator.calculate(
      portfolioReturn: 0.10,
      benchmarkReturn: -1,
    );

    expect(value, isNull);
  });
}
