import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../shared/error/failure.dart';
import '../../../accounts/domain/entities/broker_provider.dart';
import '../../../accounts/domain/entities/investment_account.dart';
import '../../../accounts/domain/repository/broker_account_repository.dart';
import '../../domain/entities/account_snapshot.dart';
import '../../domain/entities/portfolio_quote.dart';
import '../../domain/repository/portfolio_repository.dart';
import '../source/ipasargad_portfolio_source.dart';
import '../source/mofid_portfolio_source.dart';

@LazySingleton(as: PortfolioRepository)
class MultiAccountPortfolioRepositoryImpl implements PortfolioRepository {
  MultiAccountPortfolioRepositoryImpl(
    this._mofidSource,
    this._iPasargadSource,
    this._accountRepository,
  );

  final MofidPortfolioSource _mofidSource;
  final IPasargadPortfolioSource _iPasargadSource;
  final BrokerAccountRepository _accountRepository;

  @override
  Future<Either<Failure, AccountSnapshot>> getAccountSnapshot() async {
    final primaryResult = await _mofidSource.getAccountSnapshot();
    final primaryFailure = primaryResult.fold<Failure?>((value) => value, (_) => null);
    if (primaryFailure != null) {
      return left(primaryFailure);
    }
    final primary = primaryResult.getOrElse(
      () => throw StateError('Primary snapshot unexpectedly unavailable.'),
    );

    final accountsResult = await _accountRepository.getAccounts();
    final accountsFailure = accountsResult.fold<Failure?>((value) => value, (_) => null);
    if (accountsFailure != null) {
      return left(accountsFailure);
    }

    final holdings = [...primary.holdings];
    final warnings = <String>[...primary.warnings];
    var latestSync = primary.syncedAt;

    for (final account in accountsResult.getOrElse(
      () => const <InvestmentAccount>[],
    )) {
      if (account.provider != BrokerProvider.iPasargad) {
        continue;
      }
      final result = await _iPasargadSource.getAccountSnapshot(account);
      result.fold(
        (failure) => warnings.add('${account.label}: ${failure.message}'),
        (snapshot) {
          holdings.addAll(snapshot.holdings);
          warnings.addAll(snapshot.warnings);
          if (snapshot.syncedAt.isAfter(latestSync)) {
            latestSync = snapshot.syncedAt;
          }
        },
      );
    }

    return right(
      AccountSnapshot(
        holdings: holdings,
        buyingPowerToman: primary.buyingPowerToman,
        syncedAt: latestSync,
        ayarPriceToman: primary.ayarPriceToman,
        warnings: warnings,
      ),
    );
  }

  @override
  Future<Either<Failure, Map<String, PortfolioQuote>>> getQuotes(
    List<String> symbolIsins,
  ) => _mofidSource.getQuotes(symbolIsins);
}
