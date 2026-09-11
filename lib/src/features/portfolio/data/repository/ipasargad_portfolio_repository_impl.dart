import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../shared/error/failure.dart';
import '../../../../shared/network/remote_data_source.dart';
import '../../../accounts/data/security/ipasargad_session_store.dart';
import '../../../accounts/domain/entities/investment_account.dart';
import '../../domain/entities/account_snapshot.dart';
import '../../domain/entities/portfolio_holding.dart';
import '../source/ipasargad_portfolio_source.dart';

@LazySingleton(as: IPasargadPortfolioSource)
class IPasargadPortfolioRepositoryImpl implements IPasargadPortfolioSource {
  IPasargadPortfolioRepositoryImpl(this._remoteDataSource, this._sessionStore);

  static const String _baseUrl = 'https://clientapi.ipasargad.ir';
  static const String _compositionUrl =
      '$_baseUrl/api/requestdailyposition/getcustomerrequestcomposition';
  static const String _profitLossUrl =
      '$_baseUrl/api/requestdailyposition/getprofitorloss';
  static const String _evidencesUrl =
      '$_baseUrl/api/request/getcustomerevidences';

  final RemoteDataSource _remoteDataSource;
  final IPasargadSessionStore _sessionStore;

  @override
  Future<Either<Failure, AccountSnapshot>> getAccountSnapshot(
    InvestmentAccount account,
  ) async {
    try {
      final token = await _sessionStore.readToken(account.id);
      if (token == null || token.isEmpty) {
        return left(
          Failure('نشست ${account.label} منقضی شده است؛ دوباره وارد شوید.'),
        );
      }
      final headers = _authorizedHeaders(token);

      final composition = await _remoteDataSource.postJson(
        _compositionUrl,
        body: <String, dynamic>{'date': DateTime.now().toUtc().toIso8601String()},
        headers: headers,
      );
      final profitLoss = await _remoteDataSource.postJson(
        _profitLossUrl,
        headers: headers,
      );
      final evidences = await _remoteDataSource.getJson(
        _evidencesUrl,
        headers: headers,
      );

      if (composition['result'] is! List) {
        return left(
          Failure.invalidResponse(
            'ساختار ترکیب دارایی ${account.label} معتبر نیست.',
            composition,
          ),
        );
      }
      if (profitLoss['result'] is! List) {
        return left(
          Failure.invalidResponse(
            'ساختار سود و زیان ${account.label} معتبر نیست.',
            profitLoss,
          ),
        );
      }
      if (evidences['result'] is! List) {
        return left(
          Failure.invalidResponse(
            'ساختار گواهی‌های ${account.label} معتبر نیست.',
            evidences,
          ),
        );
      }

      final compositionItems = _mapList(composition['result']);
      final profitItems = _mapList(profitLoss['result']);
      final evidenceItems = _mapList(evidences['result']);

      final profitByIsin = <String, Map<String, dynamic>>{
        for (final item in profitItems)
          if ((item['isin']?.toString() ?? '').isNotEmpty)
            item['isin'].toString(): item,
      };
      final evidenceByFundCode = <String, Map<String, dynamic>>{
        for (final item in evidenceItems)
          if ((item['mutualFundCode']?.toString() ?? '').isNotEmpty)
            item['mutualFundCode'].toString(): item,
      };

      final holdings = <PortfolioHolding>[];
      for (final item in compositionItems) {
        final quantity = _num(item['remainVolume']) ?? 0;
        final isin = item['isin']?.toString() ?? '';
        if (quantity <= 0 || isin.isEmpty) {
          continue;
        }

        final fundCode = item['mutualFundCode']?.toString() ?? '';
        final profit = profitByIsin[isin];
        final evidence = evidenceByFundCode[fundCode];

        // The HAR payload does not label currency fields directly. Captured
        // settlement text uses rial, and quantity × sellPrice is consistent
        // with netValue. Convert to toman exactly once at this data boundary.
        final sellPriceRial = _num(evidence?['sellPrice']);
        final netValueRial = _num(item['netValue']);
        final fallbackPriceRial = quantity == 0 || netValueRial == null
            ? null
            : netValueRial / quantity;
        final marketPriceRial = sellPriceRial ?? fallbackPriceRial;

        holdings.add(
          PortfolioHolding(
            accountId: account.id,
            accountLabel: account.label,
            provider: account.provider,
            symbolIsin: isin,
            symbolName: item['symbol']?.toString().trim().isNotEmpty == true
                ? item['symbol'].toString()
                : item['mutualFundSymbol']?.toString() ?? isin,
            quantity: quantity,
            marketPriceToman: marketPriceRial == null ? 0 : marketPriceRial / 10,
            marketPriceBasis: marketPriceRial == null
                ? MarketPriceBasis.unavailable
                : MarketPriceBasis.sourceSellPrice,
            breakEvenPriceToman: _rialToToman(_num(profit?['buyAvgPrice'])),
            previousCloseToman: _rialToToman(_num(profit?['prevClosePrice'])),
          ),
        );
      }

      return right(
        AccountSnapshot(
          holdings: holdings,
          buyingPowerToman: 0,
          syncedAt: DateTime.now(),
        ),
      );
    } catch (error, stackTrace) {
      return left(
        Failure.detailed(
          'دریافت پرتفوی ${account.label} ناموفق بود.',
          error,
          stackTrace,
        ),
      );
    }
  }

  Map<String, dynamic> _authorizedHeaders(String token) => <String, dynamic>{
        'Accept': 'application/json, text/plain, */*',
        'Origin': 'https://app.ipasargad.ir',
        'Referer': 'https://app.ipasargad.ir/',
        'WebApp-Version': '1.0.0 (12)',
        'Cookie': 'otauth-FU=$token',
      };

  List<Map<String, dynamic>> _mapList(Object? raw) {
    if (raw is! List) {
      return const <Map<String, dynamic>>[];
    }
    return raw
        .whereType<Map>()
        .map(
          (item) => item.map<String, dynamic>(
            (key, value) => MapEntry(key.toString(), value),
          ),
        )
        .toList(growable: false);
  }

  num? _num(Object? value) {
    if (value is num) {
      return value;
    }
    return num.tryParse(value?.toString() ?? '');
  }

  num? _rialToToman(num? value) => value == null ? null : value / 10;
}
