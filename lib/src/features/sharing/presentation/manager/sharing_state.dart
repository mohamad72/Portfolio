import 'package:equatable/equatable.dart';

import '../../domain/entities/share_server_info.dart';
import '../../domain/entities/shared_portfolio_bundle.dart';

sealed class SharingState extends Equatable {
  const SharingState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class SharingInitial extends SharingState {
  const SharingInitial();
}

final class SharingBusy extends SharingState {
  const SharingBusy(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

final class SharingHosting extends SharingState {
  const SharingHosting({
    required this.serverInfo,
    required this.bundle,
  });

  final ShareServerInfo serverInfo;
  final SharedPortfolioBundle bundle;

  @override
  List<Object?> get props => <Object?>[serverInfo, bundle];
}

final class SharingFailure extends SharingState {
  const SharingFailure(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
