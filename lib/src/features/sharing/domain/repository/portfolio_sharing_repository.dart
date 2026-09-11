import 'package:dartz/dartz.dart';

import '../../../../shared/error/failure.dart';
import '../entities/share_server_info.dart';
import '../entities/shared_portfolio_bundle.dart';

abstract interface class PortfolioSharingRepository {
  bool get isServerRunning;

  SharedPortfolioBundle? get publishedBundle;

  Future<Either<Failure, SharedPortfolioBundle>> refreshPublishedBundle();

  Future<Either<Failure, ShareServerInfo>> startServer();

  Future<Either<Failure, Unit>> stopServer();

  Future<Either<Failure, SharedPortfolioBundle>> connect({
    required String serverAddress,
    required String username,
    required String password,
  });
}
