import 'package:equatable/equatable.dart';

import '../../domain/entities/investment_account.dart';

sealed class BrokerAccountsState extends Equatable {
  const BrokerAccountsState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class BrokerAccountsInitial extends BrokerAccountsState {
  const BrokerAccountsInitial();
}

final class BrokerAccountsLoading extends BrokerAccountsState {
  const BrokerAccountsLoading();
}

final class BrokerAccountsLoaded extends BrokerAccountsState {
  const BrokerAccountsLoaded(this.accounts);

  final List<InvestmentAccount> accounts;

  @override
  List<Object?> get props => <Object?>[accounts];
}

final class BrokerAccountsError extends BrokerAccountsState {
  const BrokerAccountsError(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
