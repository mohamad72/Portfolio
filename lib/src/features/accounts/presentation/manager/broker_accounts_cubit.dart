import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../data/security/ipasargad_session_store.dart';
import '../../domain/entities/broker_provider.dart';
import '../../domain/repository/broker_account_repository.dart';
import 'broker_accounts_state.dart';

@lazySingleton
class BrokerAccountsCubit extends Cubit<BrokerAccountsState> {
  BrokerAccountsCubit(this._repository, this._iPasargadSessionStore)
      : super(const BrokerAccountsInitial());

  final BrokerAccountRepository _repository;
  final IPasargadSessionStore _iPasargadSessionStore;

  Future<void> load() async {
    emit(const BrokerAccountsLoading());
    final result = await _repository.getAccounts();
    result.fold(
      (failure) => emit(BrokerAccountsError(failure.message)),
      (accounts) => emit(BrokerAccountsLoaded(accounts)),
    );
  }

  Future<void> remove(String id) async {
    final current = state;
    if (current is! BrokerAccountsLoaded) {
      return;
    }
    final match = current.accounts.where((item) => item.id == id);
    if (match.isNotEmpty && match.first.provider == BrokerProvider.iPasargad) {
      await _iPasargadSessionStore.clear(id);
    }
    final result = await _repository.deleteAccount(id);
    await result.fold(
      (failure) async => emit(BrokerAccountsError(failure.message)),
      (_) async => load(),
    );
  }
}
