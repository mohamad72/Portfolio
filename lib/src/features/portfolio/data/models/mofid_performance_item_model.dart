class MofidPerformanceItemModel {
  const MofidPerformanceItemModel({
    required this.symbolIsin,
    required this.symbolName,
    required this.asset,
    required this.breakEvenPointRial,
  });

  factory MofidPerformanceItemModel.fromJson(Map<String, dynamic> json) {
    return MofidPerformanceItemModel(
      symbolIsin: json['symbolIsin']?.toString() ?? '',
      symbolName: json['symbolName']?.toString() ?? '',
      asset: _num(json['asset']) ?? 0,
      breakEvenPointRial: _num(json['breakevenPoint']),
    );
  }

  final String symbolIsin;
  final String symbolName;
  final num asset;
  final num? breakEvenPointRial;

  static num? _num(Object? value) {
    if (value is num) {
      return value;
    }
    return num.tryParse(value?.toString() ?? '');
  }
}
