import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../shared/error/failure.dart';
import '../../../../shared/network/remote_data_source.dart';
import '../../../../shared/security/secure_session_store.dart';
import '../../domain/entities/account_snapshot.dart';
import '../../domain/entities/portfolio_holding.dart';
import '../../domain/entities/portfolio_quote.dart';
import '../../domain/repository/portfolio_repository.dart';
import '../models/mofid_market_quote_model.dart';
import '../models/mofid_performance_item_model.dart';

@LazySingleton(as: PortfolioRepository)
class MofidPortfolioRepositoryImpl implements PortfolioRepository {
  MofidPortfolioRepositoryImpl(this._remoteDataSource, this._sessionStore);

  static const String _baseUrl = 'https://api-mts.orbis.easytrader.ir';
  static const String _performanceUrl = '$_baseUrl/assetmodule/api/performance';
  static const String _moneyUrl = '$_baseUrl/easy/api/money';
  static const String _marketDataUrl = '$_baseUrl/symbols/api/marketdata';
  static const String _ayarIsin = 'IRTKMOFD0001';

  final RemoteDataSource _remoteDataSource;
  final SessionStore _sessionStore;

  @override
  Future<Either<Failure, AccountSnapshot>> getAccountSnapshot() async {
    try {
      final headers = await _authorizedHeaders();
      if (headers == null) {
        return left(const Failure('برای دریافت پرتفوی ابتدا وارد مفید شوید.'));
      }

      final performance = await _remoteDataSource.getJson(
        _performanceUrl,
        headers: headers,
      );
      final rawItems = performance['items'];
      if (rawItems is! List) {
        return left(const Failure('ساختار موجودی مفید معتبر نیست.'));
      }

      final items = rawItems
          .whereType<Map>()
          .map(
            (item) => MofidPerformanceItemModel.fromJson(
              item.map<String, dynamic>(
                (key, value) => MapEntry(key.toString(), value),
              ),
            ),
          )
          .where((item) => item.symbolIsin.isNotEmpty && item.asset != 0)
          .toList(growable: false);

      final quoteIsins = <String>{
        ...items.map((item) => item.symbolIsin),
        _ayarIsin,
      }.toList(growable: false);
      final quoteResult = await getQuotes(quoteIsins);
      Failure? quoteFailure;
      final quotes = quoteResult.fold<Map<String, PortfolioQuote>>(
        (failure) {
          quoteFailure = failure;
          return const <String, PortfolioQuote>{};
        },
        (value) => value,
      );
      if (quoteFailure != null) {
        return left(quoteFailure!);
      }

      final money = await _remoteDataSource.getJson(_moneyUrl, headers: headers);
      final buyingPowerRial = _num(money['buyPowerT2']) ?? _num(money['t2']) ?? 0;

      final holdings = items.map((item) {
        final quote = quotes[item.symbolIsin];
        return PortfolioHolding(
          symbolIsin: item.symbolIsin,
          symbolName: item.symbolName,
          quantity: item.asset,
          marketPriceToman: quote?.marketPriceToman ?? 0,
          marketPriceBasis:
              quote?.priceBasis ?? MarketPriceBasis.unavailable,
          breakEvenPriceToman: item.breakEvenPointRial == null
              ? null
              : item.breakEvenPointRial! / 10,
          previousCloseToman: quote?.previousCloseToman,
          bestBuyQuantity: quote?.bestBuyQuantity,
        );
      }).toList(growable: false);

      return right(
        AccountSnapshot(
          holdings: holdings,
          buyingPowerToman: buyingPowerRial / 10,
          syncedAt: DateTime.now(),
          ayarPriceToman: quotes[_ayarIsin]?.marketPriceToman,
        ),
      );
    } catch (error) {
      return left(Failure('دریافت پرتفوی مفید ناموفق بود.', cause: error));
    }
  }

  @override
  Future<Either<Failure, Map<String, PortfolioQuote>>> getQuotes(
    List<String> symbolIsins,
  ) async {
    if (symbolIsins.isEmpty) {
      return right(const <String, PortfolioQuote>{});
    }

    try {
      final headers = await _authorizedHeaders();
      if (headers == null) {
        return left(const Failure('نشست مفید موجود نیست.'));
      }

      final escapedIsins = symbolIsins
          .map((isin) => '"${isin.replaceAll('"', '')}"')
          .join(',');
      final query =
          'query {marketData(request: { isins: [$escapedIsins]}) {'
          'symbolIsin stateCode lastTradedPrice closingPrice '
          'feeOfPreviousDaysClosingPrice priceVar bestBuyPrice bestBuyQuantity '
          'bestSellPrice bestSellQuantity}}';

      final response = await _remoteDataSource.postJson(
        _marketDataUrl,
        body: <String, dynamic>{'query': query},
        headers: headers,
      );
      final data = response['data'];
      if (data is! Map || data['marketData'] is! List) {
        return left(const Failure('ساختار قیمت‌های مفید معتبر نیست.'));
      }

      final quotes = <String, PortfolioQuote>{};
      for (final raw in data['marketData'] as List) {
        if (raw is! Map) {
          continue;
        }
        final model = MofidMarketQuoteModel.fromJson(
          raw.map<String, dynamic>(
            (key, value) => MapEntry(key.toString(), value),
          ),
        );
        if (model.symbolIsin.isNotEmpty) {
          quotes[model.symbolIsin] = model.toDomain();
        }
      }
      return right(quotes);
    } catch (error) {
      return left(Failure('دریافت قیمت نمادها ناموفق بود.', cause: error));
    }
  }

  Future<Map<String, dynamic>?> _authorizedHeaders() async {
    final token = await _sessionStore.readAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }
    return <String, dynamic>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Origin': 'https://m.easytrader.ir',
      'Referer': 'https://m.easytrader.ir/',
    };
  }

  num? _num(Object? value) {
    if (value is num) {
      return value;
    }
    return num.tryParse(value?.toString() ?? '');
  }
}
