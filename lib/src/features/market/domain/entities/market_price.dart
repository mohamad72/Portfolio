import 'package:equatable/equatable.dart';

enum MarketSourceUnit {
  rialConfirmed,
  unknown,
}

class MarketPrice extends Equatable {
  const MarketPrice({
    required this.code,
    required this.title,
    required this.rawPrice,
    required this.rawChange,
    required this.priceToman,
    required this.changeToman,
    required this.changePercent,
    required this.direction,
    required this.sourceTimestampRaw,
    required this.sourceUnit,
    this.source = 'TGJU',
  });

  final String code;
  final String title;
  final num? rawPrice;
  final num? rawChange;
  final num? priceToman;
  final num? changeToman;
  final double? changePercent;
  final String? direction;
  final String? sourceTimestampRaw;
  final MarketSourceUnit sourceUnit;
  final String source;

  bool get hasVerifiedTomanValue => sourceUnit == MarketSourceUnit.rialConfirmed;

  @override
  List<Object?> get props => <Object?>[
        code,
        title,
        rawPrice,
        rawChange,
        priceToman,
        changeToman,
        changePercent,
        direction,
        sourceTimestampRaw,
        sourceUnit,
        source,
      ];
}
