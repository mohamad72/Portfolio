import 'package:equatable/equatable.dart';

class HoldingAllocation extends Equatable {
  const HoldingAllocation({
    required this.portfolioId,
    required this.symbolIsin,
    required this.quantity,
    required this.effectiveAt,
  });

  final String portfolioId;
  final String symbolIsin;
  final num quantity;
  final DateTime effectiveAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'portfolioId': portfolioId,
        'symbolIsin': symbolIsin,
        'quantity': quantity,
        'effectiveAt': effectiveAt.toIso8601String(),
      };

  factory HoldingAllocation.fromJson(Map<String, dynamic> json) =>
      HoldingAllocation(
        portfolioId: json['portfolioId']?.toString() ?? '',
        symbolIsin: json['symbolIsin']?.toString() ?? '',
        quantity: _num(json['quantity']) ?? 0,
        effectiveAt:
            DateTime.tryParse(json['effectiveAt']?.toString() ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0),
      );

  static num? _num(Object? value) {
    if (value is num) {
      return value;
    }
    return num.tryParse(value?.toString() ?? '');
  }

  @override
  List<Object?> get props => <Object?>[
        portfolioId,
        symbolIsin,
        quantity,
        effectiveAt,
      ];
}
