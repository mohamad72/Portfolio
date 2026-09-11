import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../shared/error/failure.dart';
import '../../../../shared/network/remote_data_source.dart';
import '../../domain/entities/market_price.dart';
import '../../domain/repository/market_repository.dart';
import '../mapper/tgju_market_mapper.dart';

@LazySingleton(as: MarketRepository)
class TgjuMarketRepositoryImpl implements MarketRepository {
  TgjuMarketRepositoryImpl(
    this._remoteDataSource, {
    TgjuMarketMapper mapper = const TgjuMarketMapper(),
  }) : _mapper = mapper;

  static const String _snapshotUrl = 'https://call4.tgju.org/ajax.json';
  static const String _alphabet =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  final RemoteDataSource _remoteDataSource;
  final TgjuMarketMapper _mapper;

  static const List<_InstrumentContract> _instruments = <_InstrumentContract>[
    _InstrumentContract(
      code: 'price_dollar_rl',
      title: 'دلار آزاد',
      sourceUnit: MarketSourceUnit.rialConfirmed,
    ),
    _InstrumentContract(
      code: 'price_eur',
      title: 'یورو آزاد',
      sourceUnit: MarketSourceUnit.unknown,
    ),
    _InstrumentContract(
      code: 'sekee',
      title: 'سکه امامی',
      sourceUnit: MarketSourceUnit.unknown,
    ),
    _InstrumentContract(
      code: 'geram18',
      title: 'طلای ۱۸ عیار',
      sourceUnit: MarketSourceUnit.rialConfirmed,
    ),
    _InstrumentContract(
      code: 'coin_blubber',
      title: 'حباب سکه امامی',
      sourceUnit: MarketSourceUnit.unknown,
    ),
  ];

  @override
  Future<Either<Failure, List<MarketPrice>>> getPrices() async {
    try {
      final response = await _remoteDataSource.getJson(
        _snapshotUrl,
        queryParameters: <String, dynamic>{'rev': _randomRevision()},
      );

      final current = response['current'];
      if (current is! Map) {
        return Left<Failure, List<MarketPrice>>(
          const Failure('ساختار پاسخ TGJU معتبر نیست.'),
        );
      }

      final prices = <MarketPrice>[];
      for (final contract in _instruments) {
        final rawItem = current[contract.code];
        if (rawItem is! Map) {
          continue;
        }

        prices.add(
          _mapper.map(
            code: contract.code,
            title: contract.title,
            raw: rawItem.map<String, dynamic>(
              (Object? key, Object? value) =>
                  MapEntry<String, dynamic>(key.toString(), value),
            ),
            sourceUnit: contract.sourceUnit,
          ),
        );
      }

      if (prices.isEmpty) {
        return Left<Failure, List<MarketPrice>>(
          const Failure('هیچ‌کدام از قیمت‌های موردنیاز در پاسخ TGJU نبود.'),
        );
      }

      return Right<Failure, List<MarketPrice>>(prices);
    } catch (error) {
      return Left<Failure, List<MarketPrice>>(
        Failure('دریافت قیمت‌های بازار ناموفق بود.', cause: error),
      );
    }
  }

  String _randomRevision() {
    final random = Random.secure();
    return List<String>.generate(
      60,
      (_) => _alphabet[random.nextInt(_alphabet.length)],
      growable: false,
    ).join();
  }
}

class _InstrumentContract {
  const _InstrumentContract({
    required this.code,
    required this.title,
    required this.sourceUnit,
  });

  final String code;
  final String title;
  final MarketSourceUnit sourceUnit;
}
