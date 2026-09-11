import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/watch_symbol.dart';
import '../../domain/repository/watchlist_repository.dart';
import 'watchlist_state.dart';

@lazySingleton
class WatchlistCubit extends Cubit<WatchlistState> {
  WatchlistCubit(this._repository) : super(const WatchlistInitial());

  final WatchlistRepository _repository;
  Timer? _searchDebounce;

  Future<void> load() async {
    emit(const WatchlistLoading());
    final result = await _repository.getSelected();
    result.fold(
      (failure) => emit(WatchlistError(failure.message)),
      (selected) => emit(WatchlistLoaded(selected: selected)),
    );
  }

  void search(String query) {
    _searchDebounce?.cancel();
    final current = state;
    if (current is! WatchlistLoaded) {
      return;
    }
    if (query.trim().length < 2) {
      emit(current.copyWith(searchResults: const <WatchSymbol>[], searching: false));
      return;
    }
    emit(current.copyWith(searching: true, clearMessage: true));
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      final result = await _repository.search(query);
      final latest = state;
      if (latest is! WatchlistLoaded) {
        return;
      }
      result.fold(
        (failure) => emit(
          latest.copyWith(
            searching: false,
            searchResults: const <WatchSymbol>[],
            message: failure.message,
          ),
        ),
        (results) => emit(
          latest.copyWith(
            searching: false,
            searchResults: results,
            clearMessage: true,
          ),
        ),
      );
    });
  }

  Future<void> add(WatchSymbol symbol) async {
    final result = await _repository.add(symbol);
    await result.fold(
      (failure) async {
        final current = state;
        if (current is WatchlistLoaded) {
          emit(current.copyWith(message: failure.message));
        }
      },
      (_) async => load(),
    );
  }

  Future<void> remove(String symbolIsin) async {
    final result = await _repository.remove(symbolIsin);
    await result.fold(
      (failure) async {
        final current = state;
        if (current is WatchlistLoaded) {
          emit(current.copyWith(message: failure.message));
        }
      },
      (_) async => load(),
    );
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
