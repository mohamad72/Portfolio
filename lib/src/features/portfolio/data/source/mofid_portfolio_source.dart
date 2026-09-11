import 'package:dartz/dartz.dart';

import '../../../../shared/error/failure.dart';
import '../../domain/entities/account_snapshot.dart';
import '../../domain/entities/portfolio_quote.dart';

abstract interface class MofidPortfolioSource {
  Future<Either<Failure, AccountSnapshot>> getAccountSnapshot();

  Future<Either<Failure, Map<String, PortfolioQuote>>> getQuotes(
    List<String> symbolIsins,
  );
}
