import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../shared/error/failure.dart';
import '../entities/market_price.dart';
import '../repository/market_repository.dart';

@lazySingleton
class GetMarketPrices {
  const GetMarketPrices(this._repository);

  final MarketRepository _repository;

  Future<Either<Failure, List<MarketPrice>>> call() => _repository.getPrices();
}
