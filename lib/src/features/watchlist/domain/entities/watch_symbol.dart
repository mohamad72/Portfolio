import 'package:equatable/equatable.dart';

class WatchSymbol extends Equatable {
  const WatchSymbol({
    required this.symbolIsin,
    required this.symbolName,
    required this.title,
    this.priceToman,
    this.changePercent,
  });

  final String symbolIsin;
  final String symbolName;
  final String title;
  final num? priceToman;
  final double? changePercent;

  WatchSymbol copyWith({
    num? priceToman,
    double? changePercent,
  }) =>
      WatchSymbol(
        symbolIsin: symbolIsin,
        symbolName: symbolName,
        title: title,
        priceToman: priceToman ?? this.priceToman,
        changePercent: changePercent ?? this.changePercent,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'symbolIsin': symbolIsin,
        'symbolName': symbolName,
        'title': title,
      };

  factory WatchSymbol.fromJson(Map<String, dynamic> json) => WatchSymbol(
        symbolIsin: json['symbolIsin']?.toString() ?? '',
        symbolName: json['symbolName']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
      );

  @override
  List<Object?> get props => <Object?>[
        symbolIsin,
        symbolName,
        title,
        priceToman,
        changePercent,
      ];
}
