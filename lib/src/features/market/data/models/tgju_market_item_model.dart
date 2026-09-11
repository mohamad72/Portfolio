class TgjuMarketItemModel {
  const TgjuMarketItemModel({
    required this.price,
    required this.change,
    required this.changePercent,
    required this.direction,
    required this.timestamp,
  });

  factory TgjuMarketItemModel.fromJson(Map<String, dynamic> json) {
    return TgjuMarketItemModel(
      price: _parseNumber(json['p']),
      change: _parseNumber(json['d']),
      changePercent: _parseDouble(json['dp']),
      direction: json['dt']?.toString(),
      timestamp: json['ts']?.toString(),
    );
  }

  final num? price;
  final num? change;
  final double? changePercent;
  final String? direction;
  final String? timestamp;

  static num? _parseNumber(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value;
    }

    final normalized = value.toString().replaceAll(',', '').trim();
    if (normalized.isEmpty) {
      return null;
    }
    return num.tryParse(normalized);
  }

  static double? _parseDouble(Object? value) {
    final number = _parseNumber(value);
    return number?.toDouble();
  }
}
