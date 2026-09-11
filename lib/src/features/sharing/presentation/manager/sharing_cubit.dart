import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/shared_portfolio_bundle.dart';
import '../../domain/repository/portfolio_sharing_repository.dart';
import 'sharing_state.dart';

@lazySingleton
class SharingCubit extends Cubit<SharingState> {
  SharingCubit(this._repository) : super(const SharingInitial());

  final PortfolioSharingRepository _repository;

  Future<void> startHosting() async {
    emit(const SharingBusy('در حال آماده‌سازی نسخهٔ اشتراکی...'));
    final result = await _repository.startServer();
    result.fold(
      (failure) => emit(SharingFailure(failure.message)),
      (serverInfo) {
        final bundle = _repository.publishedBundle;
        if (bundle == null) {
          emit(const SharingFailure('نسخهٔ اشتراکی پرتفوی آماده نشد.'));
          return;
        }
        emit(SharingHosting(serverInfo: serverInfo, bundle: bundle));
      },
    );
  }

  Future<void> refreshHosting() async {
    final current = state;
    if (current is! SharingHosting) {
      await startHosting();
      return;
    }

    emit(const SharingBusy('در حال تازه‌سازی اطلاعات اشتراکی...'));
    final result = await _repository.refreshPublishedBundle();
    result.fold(
      (failure) => emit(SharingFailure(failure.message)),
      (bundle) => emit(
        SharingHosting(serverInfo: current.serverInfo, bundle: bundle),
      ),
    );
  }

  Future<void> stopHosting() async {
    final result = await _repository.stopServer();
    result.fold(
      (failure) => emit(SharingFailure(failure.message)),
      (_) => emit(const SharingInitial()),
    );
  }

  Future<SharedPortfolioBundle?> connect({
    required String serverAddress,
    required String username,
    required String password,
  }) async {
    emit(const SharingBusy('در حال اتصال به پرتفوی اشتراکی...'));
    final result = await _repository.connect(
      serverAddress: serverAddress,
      username: username,
      password: password,
    );
    return result.fold(
      (failure) {
        emit(SharingFailure(failure.message));
        return null;
      },
      (bundle) {
        emit(const SharingInitial());
        return bundle;
      },
    );
  }
}
