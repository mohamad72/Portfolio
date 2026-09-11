import 'package:equatable/equatable.dart';

class HoldingAllocation extends Equatable {
  const HoldingAllocation({
    required this.portfolioId,
    required this.holdingKey,
    required this.symbolIsin,
    required this.quantity,
    required this.effectiveAt,
  });

  final String portfolioId;
  final String holdingKey;
  final String symbolIsin;
  final num quantity;
  final DateTime effectiveAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'portfolioId': portfolioId,
        'holdingKey': holdingKey,
        'symbolIsin': symbolIsin,
        'quantity': quantity,
        'effectiveAt': effectiveAt.toIso8601String(),
      };

  factory HoldingAllocation.fromJson(Map<String, dynamic> json) {
    final symbolIsin = json['symbolIsin']?.toString() ?? '';
    final explicitKey = json['holdingKey']?.toString() ?? '';
    return HoldingAllocation(
      portfolioId: json['portfolioId']?.toString() ?? '',
      holdingKey: explicitKey.isNotEmpty
          ? explicitKey
          : 'mofid-primary::$symbolIsin',
      symbolIsin: symbolIsin,
      quantity: _num(json['quantity']) ?? 0,
      effectiveAt: DateTime.tryParse(json['effectiveAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static num? _num(Object? value) {
    if (value is num) {
      return value;
    }
    return num.tryParse(value?.toString() ?? '');
  }

  @override
  List<Object?> get props => <Object?>[
        portfolioId,
        holdingKey,
        symbolIsin,
        quantity,
        effectiveAt,
      ];
}
