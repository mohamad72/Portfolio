import 'package:dartz/dartz.dart';

import '../../../../shared/error/failure.dart';
import '../entities/market_price.dart';

abstract interface class MarketRepository {
  Future<Either<Failure, List<MarketPrice>>> getPrices();
}
