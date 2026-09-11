import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/error/failure.dart';
import '../../../../shared/security/secure_session_store.dart';
import '../../domain/entities/holding_allocation.dart';
import '../../domain/entities/local_portfolio.dart';
import '../../domain/repository/local_portfolio_repository.dart';

@LazySingleton(as: LocalPortfolioRepository)
class PreferencesLocalPortfolioRepositoryImpl
    implements LocalPortfolioRepository {
  PreferencesLocalPortfolioRepositoryImpl(this._preferences, this._sessionStore);

  static const String _portfoliosKey = 'local_portfolios_v1';
  static const String _allocationsKey = 'holding_allocations_v1';

  final SharedPreferences _preferences;
  final SessionStore _sessionStore;

  Future<String> _scopedKey(String base) async {
    final accountKey = await _sessionStore.readAccountKey();
    return '$base:${accountKey ?? 'signed-out'}';
  }

  @override
  Future<Either<Failure, List<LocalPortfolio>>> getPortfolios() async {
    try {
      final raw = _preferences.getString(await _scopedKey(_portfoliosKey));
      if (raw == null || raw.isEmpty) {
        return right(const <LocalPortfolio>[]);
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return left(const Failure('دادهٔ سبدهای محلی معتبر نیست.'));
      }
      return right(
        decoded
            .whereType<Map>()
            .map(
              (item) => LocalPortfolio.fromJson(
                item.map<String, dynamic>(
                  (key, value) => MapEntry(key.toString(), value),
                ),
              ),
            )
            .where((item) => item.id.isNotEmpty && item.name.isNotEmpty)
            .toList(growable: false),
      );
    } catch (error) {
      return left(Failure('خواندن سبدهای محلی ناموفق بود.', cause: error));
    }
  }

  @override
  Future<Either<Failure, Unit>> savePortfolio(LocalPortfolio portfolio) async {
    final currentResult = await getPortfolios();
    final failure = currentResult.fold<Failure?>((value) => value, (_) => null);
    if (failure != null) {
      return left(failure);
    }

    try {
      final current = currentResult.getOrElse(() => const <LocalPortfolio>[]);
      final updated = List<LocalPortfolio>.from(current);
      final index = updated.indexWhere((item) => item.id == portfolio.id);
      if (index >= 0) {
        updated[index] = portfolio;
      } else {
        updated.add(portfolio);
      }
      await _preferences.setString(
        await _scopedKey(_portfoliosKey),
        jsonEncode(updated.map((item) => item.toJson()).toList()),
      );
      return right(unit);
    } catch (error) {
      return left(Failure('ذخیرهٔ سبد محلی ناموفق بود.', cause: error));
    }
  }

  @override
  Future<Either<Failure, Unit>> deletePortfolio(String id) async {
    final portfoliosResult = await getPortfolios();
    final allocationsResult = await getAllocations();
    final portfolioFailure =
        portfoliosResult.fold<Failure?>((value) => value, (_) => null);
    if (portfolioFailure != null) {
      return left(portfolioFailure);
    }
    final allocationFailure =
        allocationsResult.fold<Failure?>((value) => value, (_) => null);
    if (allocationFailure != null) {
      return left(allocationFailure);
    }

    try {
      final portfolios = List<LocalPortfolio>.from(
        portfoliosResult.getOrElse(() => const <LocalPortfolio>[]),
      )..removeWhere((item) => item.id == id);
      final allocations = List<HoldingAllocation>.from(
        allocationsResult.getOrElse(() => const <HoldingAllocation>[]),
      )..removeWhere((item) => item.portfolioId == id);
      await _preferences.setString(
        await _scopedKey(_portfoliosKey),
        jsonEncode(portfolios.map((item) => item.toJson()).toList()),
      );
      await _preferences.setString(
        await _scopedKey(_allocationsKey),
        jsonEncode(allocations.map((item) => item.toJson()).toList()),
      );
      return right(unit);
    } catch (error) {
      return left(Failure('حذف سبد محلی ناموفق بود.', cause: error));
    }
  }

  @override
  Future<Either<Failure, List<HoldingAllocation>>> getAllocations() async {
    try {
      final raw = _preferences.getString(await _scopedKey(_allocationsKey));
      if (raw == null || raw.isEmpty) {
        return right(const <HoldingAllocation>[]);
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return left(const Failure('دادهٔ تخصیص‌ها معتبر نیست.'));
      }
      return right(
        decoded
            .whereType<Map>()
            .map(
              (item) => HoldingAllocation.fromJson(
                item.map<String, dynamic>(
                  (key, value) => MapEntry(key.toString(), value),
                ),
              ),
            )
            .where(
              (item) =>
                  item.portfolioId.isNotEmpty && item.holdingKey.isNotEmpty,
            )
            .toList(growable: false),
      );
    } catch (error) {
      return left(Failure('خواندن تخصیص‌ها ناموفق بود.', cause: error));
    }
  }

  @override
  Future<Either<Failure, Unit>> replaceHoldingAllocations(
    String holdingKey,
    List<HoldingAllocation> allocations,
  ) async {
    final currentResult = await getAllocations();
    final failure = currentResult.fold<Failure?>((value) => value, (_) => null);
    if (failure != null) {
      return left(failure);
    }

    try {
      final updated = List<HoldingAllocation>.from(
        currentResult.getOrElse(() => const <HoldingAllocation>[]),
      )
        ..removeWhere((item) => item.holdingKey == holdingKey)
        ..addAll(allocations.where((item) => item.quantity > 0));
      await _preferences.setString(
        await _scopedKey(_allocationsKey),
        jsonEncode(updated.map((item) => item.toJson()).toList()),
      );
      return right(unit);
    } catch (error) {
      return left(Failure('ذخیرهٔ تخصیص دارایی ناموفق بود.', cause: error));
    }
  }
}
