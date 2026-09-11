import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/use_case/get_market_prices.dart';
import 'market_state.dart';

@injectable
class MarketCubit extends Cubit<MarketState> {
  MarketCubit(this._getMarketPrices) : super(const MarketInitial());

  final GetMarketPrices _getMarketPrices;

  Future<void> load() async {
    emit(const MarketLoading());
    final result = await _getMarketPrices();
    result.fold(
      (failure) => emit(MarketError(failure.message)),
      (prices) => emit(MarketLoaded(prices)),
    );
  }
}
