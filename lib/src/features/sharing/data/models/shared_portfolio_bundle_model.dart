import '../../../portfolio/domain/entities/account_snapshot.dart';
import '../../../portfolio/domain/entities/holding_allocation.dart';
import '../../../portfolio/domain/entities/local_portfolio.dart';
import '../../../portfolio/domain/entities/portfolio_holding.dart';
import '../../domain/entities/shared_portfolio_bundle.dart';

class SharedPortfolioBundleModel {
  const SharedPortfolioBundleModel({required this.bundle});

  final SharedPortfolioBundle bundle;

  factory SharedPortfolioBundleModel.fromDomain(SharedPortfolioBundle bundle) =>
      SharedPortfolioBundleModel(bundle: bundle);

  factory SharedPortfolioBundleModel.fromJson(Map<String, dynamic> json) {
    final rawHoldings = json['holdings'];
    final rawPortfolios = json['portfolios'];
    final rawAllocations = json['allocations'];

    final holdings = rawHoldings is List
        ? rawHoldings
            .whereType<Map>()
            .map(
              (item) => _holdingFromJson(
                item.map<String, dynamic>(
                  (key, value) => MapEntry(key.toString(), value),
                ),
              ),
            )
            .toList(growable: false)
        : const <PortfolioHolding>[];

    final portfolios = rawPortfolios is List
        ? rawPortfolios
            .whereType<Map>()
            .map(
              (item) => LocalPortfolio.fromJson(
                item.map<String, dynamic>(
                  (key, value) => MapEntry(key.toString(), value),
                ),
              ),
            )
            .toList(growable: false)
        : const <LocalPortfolio>[];

    final allocations = rawAllocations is List
        ? rawAllocations
            .whereType<Map>()
            .map(
              (item) => HoldingAllocation.fromJson(
                item.map<String, dynamic>(
                  (key, value) => MapEntry(key.toString(), value),
                ),
              ),
            )
            .toList(growable: false)
        : const <HoldingAllocation>[];

    final syncedAt = DateTime.tryParse(json['syncedAt']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final publishedAt =
        DateTime.tryParse(json['publishedAt']?.toString() ?? '') ?? syncedAt;

    return SharedPortfolioBundleModel(
      bundle: SharedPortfolioBundle(
        snapshot: AccountSnapshot(
          holdings: holdings,
          buyingPowerToman: _num(json['buyingPowerToman']) ?? 0,
          syncedAt: syncedAt,
          ayarPriceToman: _num(json['ayarPriceToman']),
        ),
        portfolios: portfolios,
        allocations: allocations,
        publishedAt: publishedAt,
      ),
    );
  }

  SharedPortfolioBundle toDomain() => bundle;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'version': 1,
        'publishedAt': bundle.publishedAt.toIso8601String(),
        'syncedAt': bundle.snapshot.syncedAt.toIso8601String(),
        'buyingPowerToman': bundle.snapshot.buyingPowerToman,
        'ayarPriceToman': bundle.snapshot.ayarPriceToman,
        'holdings': bundle.snapshot.holdings
            .map(_holdingToJson)
            .toList(growable: false),
        'portfolios':
            bundle.portfolios.map((item) => item.toJson()).toList(growable: false),
        'allocations': bundle.allocations
            .map((item) => item.toJson())
            .toList(growable: false),
      };

  static Map<String, dynamic> _holdingToJson(PortfolioHolding holding) =>
      <String, dynamic>{
        'symbolIsin': holding.symbolIsin,
        'symbolName': holding.symbolName,
        'quantity': holding.quantity,
        'marketPriceToman': holding.marketPriceToman,
        'marketPriceBasis': holding.marketPriceBasis.name,
        'breakEvenPriceToman': holding.breakEvenPriceToman,
        'previousCloseToman': holding.previousCloseToman,
        'bestBuyQuantity': holding.bestBuyQuantity,
      };

  static PortfolioHolding _holdingFromJson(Map<String, dynamic> json) {
    final basisName = json['marketPriceBasis']?.toString();
    final basis = MarketPriceBasis.values
        .where((item) => item.name == basisName)
        .firstOrNull;
    return PortfolioHolding(
      symbolIsin: json['symbolIsin']?.toString() ?? '',
      symbolName: json['symbolName']?.toString() ?? '',
      quantity: _num(json['quantity']) ?? 0,
      marketPriceToman: _num(json['marketPriceToman']) ?? 0,
      marketPriceBasis: basis ?? MarketPriceBasis.unavailable,
      breakEvenPriceToman: _num(json['breakEvenPriceToman']),
      previousCloseToman: _num(json['previousCloseToman']),
      bestBuyQuantity: _num(json['bestBuyQuantity']),
    );
  }

  static num? _num(Object? value) {
    if (value is num) {
      return value;
    }
    return num.tryParse(value?.toString() ?? '');
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
