import 'package:dartz/dartz.dart';

import '../../../../shared/error/failure.dart';
import '../entities/watch_symbol.dart';

abstract interface class WatchlistRepository {
  Future<Either<Failure, List<WatchSymbol>>> getSelected();

  Future<Either<Failure, List<WatchSymbol>>> search(String query);

  Future<Either<Failure, Unit>> add(WatchSymbol symbol);

  Future<Either<Failure, Unit>> remove(String symbolIsin);
}
