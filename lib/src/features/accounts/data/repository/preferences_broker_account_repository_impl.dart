import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/error/failure.dart';
import '../../../../shared/security/secure_session_store.dart';
import '../../domain/entities/investment_account.dart';
import '../../domain/repository/broker_account_repository.dart';

@LazySingleton(as: BrokerAccountRepository)
class PreferencesBrokerAccountRepositoryImpl implements BrokerAccountRepository {
  PreferencesBrokerAccountRepositoryImpl(this._preferences, this._sessionStore);

  static const String _key = 'additional_broker_accounts_v1';

  final SharedPreferences _preferences;
  final SessionStore _sessionStore;

  Future<String> _scopedKey() async {
    final accountKey = await _sessionStore.readAccountKey();
    return '$_key:${accountKey ?? 'signed-out'}';
  }

  @override
  Future<Either<Failure, List<InvestmentAccount>>> getAccounts() async {
    try {
      final raw = _preferences.getString(await _scopedKey());
      if (raw == null || raw.isEmpty) {
        return right(const <InvestmentAccount>[]);
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return left(
          Failure.invalidResponse(
            'فهرست حساب‌های اضافه معتبر نیست.',
            decoded,
          ),
        );
      }
      final accounts = decoded
          .whereType<Map>()
          .map(
            (item) => InvestmentAccount.fromJson(
              item.map<String, dynamic>(
                (key, value) => MapEntry(key.toString(), value),
              ),
            ),
          )
          .where((item) => item.id.isNotEmpty && item.label.isNotEmpty)
          .toList(growable: false);
      return right(accounts);
    } catch (error, stackTrace) {
      return left(
        Failure.detailed(
          'خواندن حساب‌های اضافه ناموفق بود.',
          error,
          stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> saveAccount(InvestmentAccount account) async {
    final currentResult = await getAccounts();
    final failure = currentResult.fold<Failure?>((value) => value, (_) => null);
    if (failure != null) {
      return left(failure);
    }
    try {
      final accounts = List<InvestmentAccount>.from(
        currentResult.getOrElse(() => const <InvestmentAccount>[]),
      );
      final index = accounts.indexWhere((item) => item.id == account.id);
      if (index >= 0) {
        accounts[index] = account;
      } else {
        accounts.add(account);
      }
      await _preferences.setString(
        await _scopedKey(),
        jsonEncode(accounts.map((item) => item.toJson()).toList()),
      );
      return right(unit);
    } catch (error, stackTrace) {
      return left(
        Failure.detailed(
          'ذخیرهٔ حساب اضافه ناموفق بود.',
          error,
          stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteAccount(String id) async {
    final currentResult = await getAccounts();
    final failure = currentResult.fold<Failure?>((value) => value, (_) => null);
    if (failure != null) {
      return left(failure);
    }
    try {
      final accounts = List<InvestmentAccount>.from(
        currentResult.getOrElse(() => const <InvestmentAccount>[]),
      )..removeWhere((item) => item.id == id);
      await _preferences.setString(
        await _scopedKey(),
        jsonEncode(accounts.map((item) => item.toJson()).toList()),
      );
      return right(unit);
    } catch (error, stackTrace) {
      return left(
        Failure.detailed(
          'حذف حساب اضافه ناموفق بود.',
          error,
          stackTrace,
        ),
      );
    }
  }
}
