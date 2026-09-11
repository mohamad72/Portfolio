import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/error/failure.dart';
import '../../../../shared/network/remote_data_source.dart';
import '../../../../shared/security/secure_session_store.dart';
import '../../domain/entities/watch_symbol.dart';
import '../../domain/repository/watchlist_repository.dart';

@LazySingleton(as: WatchlistRepository)
class WatchlistRepositoryImpl implements WatchlistRepository {
  WatchlistRepositoryImpl(
    this._preferences,
    this._remoteDataSource,
    this._sessionStore,
  );

  static const String _key = 'watchlist_v1';
  static const String _baseUrl = 'https://api-mts.orbis.easytrader.ir';
  static const String _symbolsUrl = '$_baseUrl/symbols/api/symbols/all';
  static const String _marketDataUrl = '$_baseUrl/symbols/api/marketdata';

  final SharedPreferences _preferences;
  final RemoteDataSource _remoteDataSource;
  final SessionStore _sessionStore;

  List<WatchSymbol>? _catalogCache;

  @override
  Future<Either<Failure, List<WatchSymbol>>> getSelected() async {
    try {
      final selected = await _readLocal();
      if (selected.isEmpty) {
        return right(selected);
      }
      final token = await _sessionStore.readAccessToken();
      if (token == null || token.isEmpty) {
        return right(selected);
      }
      final quotes = await _fetchQuotes(
        selected.map((item) => item.symbolIsin).toList(growable: false),
        token,
      );
      return right(
        selected
            .map((item) {
              final quote = quotes[item.symbolIsin];
              if (quote == null) {
                return item;
              }
              return item.copyWith(
                priceToman: quote.$1,
                changePercent: quote.$2,
              );
            })
            .toList(growable: false),
      );
    } catch (error, stackTrace) {
      return left(
        Failure.detailed(
          'خواندن دیده‌بان ناموفق بود.',
          error,
          stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<WatchSymbol>>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      return right(const <WatchSymbol>[]);
    }

    try {
      final token = await _sessionStore.readAccessToken();
      if (token == null || token.isEmpty) {
        return left(const Failure('برای جست‌وجوی نماد ابتدا وارد مفید شوید.'));
      }
      final catalog = _catalogCache ??= await _loadCatalog(token);
      final normalized = trimmed.toLowerCase();
      final results = catalog
          .where(
            (item) =>
                item.symbolName.toLowerCase().contains(normalized) ||
                item.title.toLowerCase().contains(normalized) ||
                item.symbolIsin.toLowerCase().contains(normalized),
          )
          .take(30)
          .toList(growable: false);
      return right(results);
    } catch (error, stackTrace) {
      return left(
        Failure.detailed(
          'جست‌وجوی نماد ناموفق بود.',
          error,
          stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> add(WatchSymbol symbol) async {
    try {
      final current = await _readLocal();
      if (current.any((item) => item.symbolIsin == symbol.symbolIsin)) {
        return right(unit);
      }
      await _writeLocal(<WatchSymbol>[...current, symbol]);
      return right(unit);
    } catch (error, stackTrace) {
      return left(
        Failure.detailed(
          'افزودن نماد به دیده‌بان ناموفق بود.',
          error,
          stackTrace,
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> remove(String symbolIsin) async {
    try {
      final current = await _readLocal();
      current.removeWhere((item) => item.symbolIsin == symbolIsin);
      await _writeLocal(current);
      return right(unit);
    } catch (error, stackTrace) {
      return left(
        Failure.detailed(
          'حذف نماد از دیده‌بان ناموفق بود.',
          error,
          stackTrace,
        ),
      );
    }
  }

  Future<List<WatchSymbol>> _readLocal() async {
    final raw = _preferences.getString(await _scopedKey());
    if (raw == null || raw.isEmpty) {
      return <WatchSymbol>[];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw FormatException(
        'Expected a JSON array for the local watchlist. '
        'Actual type: ${decoded.runtimeType}. Raw value: $raw',
      );
    }
    return decoded
        .whereType<Map>()
        .map(
          (item) => WatchSymbol.fromJson(
            item.map<String, dynamic>(
              (key, value) => MapEntry(key.toString(), value),
            ),
          ),
        )
        .where((item) => item.symbolIsin.isNotEmpty)
        .toList();
  }

  Future<void> _writeLocal(List<WatchSymbol> symbols) async {
    await _preferences.setString(
      await _scopedKey(),
      jsonEncode(symbols.map((item) => item.toJson()).toList()),
    );
  }

  Future<String> _scopedKey() async {
    final accountKey = await _sessionStore.readAccountKey();
    return '$_key:${accountKey ?? 'signed-out'}';
  }

  Future<List<WatchSymbol>> _loadCatalog(String token) async {
    final response = await _remoteDataSource.postJson(
      _symbolsUrl,
      body: const <String, dynamic>{'hash': 'null'},
      headers: _headers(token),
    );
    final symbols = response['symbols'];
    if (symbols is! List) {
      throw FormatException(
        'Invalid symbols response. Raw response: ${jsonEncode(response)}',
      );
    }
    return symbols
        .whereType<Map>()
        .map(
          (item) => WatchSymbol(
            symbolIsin: item['symbolIsin']?.toString() ?? '',
            symbolName: item['symbolName']?.toString() ?? '',
            title: item['title']?.toString() ?? '',
          ),
        )
        .where((item) => item.symbolIsin.isNotEmpty && item.symbolName.isNotEmpty)
        .toList(growable: false);
  }

  Future<Map<String, (num?, double?)>> _fetchQuotes(
    List<String> isins,
    String token,
  ) async {
    final escaped = isins
        .map((isin) => '"${isin.replaceAll('"', '')}"')
        .join(',');
    final query =
        'query {marketData(request: { isins: [$escaped]}) {'
        'symbolIsin lastTradedPrice closingPrice feeOfPreviousDaysClosingPrice '
        'bestBuyPrice}}';
    final response = await _remoteDataSource.postJson(
      _marketDataUrl,
      body: <String, dynamic>{'query': query},
      headers: _headers(token),
    );
    final data = response['data'];
    if (data is! Map || data['marketData'] is! List) {
      throw FormatException(
        'Invalid market data response. Raw response: ${jsonEncode(response)}',
      );
    }
    final result = <String, (num?, double?)>{};
    for (final raw in data['marketData'] as List) {
      if (raw is! Map) {
        continue;
      }
      final isin = raw['symbolIsin']?.toString() ?? '';
      if (isin.isEmpty) {
        continue;
      }
      final bestBuy = _num(raw['bestBuyPrice']);
      final last = _num(raw['lastTradedPrice']);
      final closing = _num(raw['closingPrice']);
      final priceRial = bestBuy != null && bestBuy > 0
          ? bestBuy
          : last != null && last > 0
              ? last
              : closing;
      final previousClose = _num(raw['feeOfPreviousDaysClosingPrice']);
      final changePercent = priceRial == null ||
              previousClose == null ||
              previousClose == 0
          ? null
          : ((priceRial / previousClose) - 1) * 100;
      result[isin] = (
        priceRial == null ? null : priceRial / 10,
        changePercent?.toDouble(),
      );
    }
    return result;
  }

  Map<String, dynamic> _headers(String token) => <String, dynamic>{
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Origin': 'https://m.easytrader.ir',
        'Referer': 'https://m.easytrader.ir/',
      };

  num? _num(Object? value) {
    if (value is num) {
      return value;
    }
    return num.tryParse(value?.toString() ?? '');
  }
}
