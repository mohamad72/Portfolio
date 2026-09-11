import 'package:equatable/equatable.dart';

import '../../domain/entities/market_price.dart';

sealed class MarketState extends Equatable {
  const MarketState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class MarketInitial extends MarketState {
  const MarketInitial();
}

final class MarketLoading extends MarketState {
  const MarketLoading();
}

final class MarketLoaded extends MarketState {
  const MarketLoaded(this.prices);

  final List<MarketPrice> prices;

  @override
  List<Object?> get props => <Object?>[prices];
}

final class MarketError extends MarketState {
  const MarketError(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
