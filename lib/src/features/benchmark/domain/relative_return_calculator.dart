import 'package:injectable/injectable.dart';

@lazySingleton
class RelativeReturnCalculator {
  const RelativeReturnCalculator();

  double? calculate({
    required double portfolioReturn,
    required double benchmarkReturn,
  }) {
    final denominator = 1 + benchmarkReturn;
    if (denominator == 0) {
      return null;
    }
    return ((1 + portfolioReturn) / denominator) - 1;
  }
}
