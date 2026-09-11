import 'package:equatable/equatable.dart';

import 'portfolio_holding.dart';

class AccountSnapshot extends Equatable {
  const AccountSnapshot({
    required this.holdings,
    required this.buyingPowerToman,
    required this.syncedAt,
    this.ayarPriceToman,
    this.warnings = const <String>[],
  });

  final List<PortfolioHolding> holdings;
  final num buyingPowerToman;
  final DateTime syncedAt;
  final num? ayarPriceToman;
  final List<String> warnings;

  num? get holdingsValueToman {
    var total = 0.0;
    for (final holding in holdings) {
      final value = holding.currentValueToman;
      if (value == null) {
        return null;
      }
      total += value.toDouble();
    }
    return total;
  }

  num? toAyarUnits(num tomanValue) {
    final price = ayarPriceToman;
    if (price == null || price <= 0) {
      return null;
    }
    return tomanValue / price;
  }

  @override
  List<Object?> get props => <Object?>[
        holdings,
        buyingPowerToman,
        syncedAt,
        ayarPriceToman,
        warnings,
      ];
}
