import '../../domain/entities/market_price.dart';
import '../models/tgju_market_item_model.dart';

class TgjuMarketMapper {
  const TgjuMarketMapper();

  MarketPrice map({
    required String code,
    required String title,
    required Map<String, dynamic> raw,
    MarketSourceUnit sourceUnit = MarketSourceUnit.rialConfirmed,
  }) {
    final model = TgjuMarketItemModel.fromJson(raw);
    final isRialConfirmed = sourceUnit == MarketSourceUnit.rialConfirmed;

    return MarketPrice(
      code: code,
      title: title,
      rawPrice: model.price,
      rawChange: model.change,
      priceToman: isRialConfirmed ? _rialToToman(model.price) : null,
      changeToman: isRialConfirmed ? _rialToToman(model.change) : null,
      changePercent: model.changePercent,
      direction: model.direction,
      sourceTimestampRaw: model.timestamp,
      sourceUnit: sourceUnit,
    );
  }

  num? _rialToToman(num? value) {
    if (value == null) {
      return null;
    }
    return value / 10;
  }
}
