import 'package:equatable/equatable.dart';

import '../../domain/entities/watch_symbol.dart';

sealed class WatchlistState extends Equatable {
  const WatchlistState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class WatchlistInitial extends WatchlistState {
  const WatchlistInitial();
}

final class WatchlistLoading extends WatchlistState {
  const WatchlistLoading();
}

final class WatchlistLoaded extends WatchlistState {
  const WatchlistLoaded({
    required this.selected,
    this.searchResults = const <WatchSymbol>[],
    this.searching = false,
    this.message,
  });

  final List<WatchSymbol> selected;
  final List<WatchSymbol> searchResults;
  final bool searching;
  final String? message;

  WatchlistLoaded copyWith({
    List<WatchSymbol>? selected,
    List<WatchSymbol>? searchResults,
    bool? searching,
    String? message,
    bool clearMessage = false,
  }) =>
      WatchlistLoaded(
        selected: selected ?? this.selected,
        searchResults: searchResults ?? this.searchResults,
        searching: searching ?? this.searching,
        message: clearMessage ? null : message ?? this.message,
      );

  @override
  List<Object?> get props => <Object?>[
        selected,
        searchResults,
        searching,
        message,
      ];
}

final class WatchlistError extends WatchlistState {
  const WatchlistError(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
