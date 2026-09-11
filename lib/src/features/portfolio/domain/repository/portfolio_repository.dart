import 'package:dartz/dartz.dart';

import '../../../../shared/error/failure.dart';
import '../entities/account_snapshot.dart';
import '../entities/portfolio_quote.dart';

abstract interface class PortfolioRepository {
  Future<Either<Failure, AccountSnapshot>> getAccountSnapshot();

  Future<Either<Failure, Map<String, PortfolioQuote>>> getQuotes(
    List<String> symbolIsins,
  );
}
