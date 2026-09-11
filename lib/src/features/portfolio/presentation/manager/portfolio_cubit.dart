import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/local_portfolio.dart';
import '../../domain/repository/local_portfolio_repository.dart';
import '../../domain/use_case/get_account_snapshot.dart';
import '../../domain/use_case/save_symbol_allocations.dart';
import 'portfolio_state.dart';

@lazySingleton
class PortfolioCubit extends Cubit<PortfolioState> {
  PortfolioCubit(
    this._getAccountSnapshot,
    this._localRepository,
    this._saveSymbolAllocations,
  ) : super(const PortfolioInitial());

  final GetAccountSnapshot _getAccountSnapshot;
  final LocalPortfolioRepository _localRepository;
  final SaveSymbolAllocations _saveSymbolAllocations;

  Future<void> load() async {
    emit(const PortfolioLoading());

    final snapshotResult = await _getAccountSnapshot();
    final snapshot = snapshotResult.fold((_) => null, (value) => value);
    if (snapshot == null) {
      emit(
        PortfolioError(
          snapshotResult.fold(
            (failure) => failure.message,
            (_) => 'دریافت پرتفوی ناموفق بود.',
          ),
        ),
      );
      return;
    }

    var portfolios = await _loadPortfolios();
    if (portfolios == null) {
      return;
    }
    if (portfolios.isEmpty) {
      final now = DateTime.now();
      await _localRepository.savePortfolio(
        LocalPortfolio(id: 'mine', name: 'من', createdAt: now),
      );
      await _localRepository.savePortfolio(
        LocalPortfolio(id: 'father', name: 'پدر', createdAt: now),
      );
      portfolios = await _loadPortfolios();
      if (portfolios == null) {
        return;
      }
    }

    final allocationsResult = await _localRepository.getAllocations();
    allocationsResult.fold(
      (failure) => emit(PortfolioError(failure.message)),
      (allocations) => emit(
        PortfolioLoaded(
          snapshot: snapshot,
          portfolios: portfolios!,
          allocations: allocations,
          selectedPortfolioId: PortfolioLoaded.totalPortfolioId,
        ),
      ),
    );
  }

  Future<List<LocalPortfolio>?> _loadPortfolios() async {
    final result = await _localRepository.getPortfolios();
    return result.fold(
      (failure) {
        emit(PortfolioError(failure.message));
        return null;
      },
      (value) => value,
    );
  }

  void selectPortfolio(String id) {
    final current = state;
    if (current is PortfolioLoaded) {
      emit(current.copyWith(selectedPortfolioId: id));
    }
  }

  void selectValueUnit(PortfolioValueUnit unit) {
    final current = state;
    if (current is PortfolioLoaded) {
      emit(current.copyWith(valueUnit: unit));
    }
  }

  Future<void> createPortfolio(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final result = await _localRepository.savePortfolio(
      LocalPortfolio(
        id: 'p_${DateTime.now().microsecondsSinceEpoch}',
        name: trimmed,
        createdAt: DateTime.now(),
      ),
    );
    await result.fold(
      (failure) async => emit(PortfolioError(failure.message)),
      (_) async => _reloadLocalData(),
    );
  }

  Future<void> renamePortfolio(String id, String name) async {
    final current = state;
    if (current is! PortfolioLoaded) {
      return;
    }
    final match = current.portfolios.where((item) => item.id == id);
    if (match.isEmpty || name.trim().isEmpty) {
      return;
    }
    final result = await _localRepository.savePortfolio(
      match.first.copyWith(name: name.trim()),
    );
    await result.fold(
      (failure) async => emit(PortfolioError(failure.message)),
      (_) async => _reloadLocalData(),
    );
  }

  Future<void> deletePortfolio(String id) async {
    final result = await _localRepository.deletePortfolio(id);
    await result.fold(
      (failure) async => emit(PortfolioError(failure.message)),
      (_) async => _reloadLocalData(),
    );
  }

  Future<String?> saveAllocations({
    required String symbolIsin,
    required num totalQuantity,
    required Map<String, num> allocations,
  }) async {
    final result = await _saveSymbolAllocations(
      symbolIsin: symbolIsin,
      totalQuantity: totalQuantity,
      allocations: allocations,
    );
    return result.fold(
      (failure) async => failure.message,
      (_) async {
        await _reloadLocalData();
        return null;
      },
    );
  }

  Future<void> _reloadLocalData() async {
    final current = state;
    if (current is! PortfolioLoaded) {
      return;
    }
    final portfoliosResult = await _localRepository.getPortfolios();
    final allocationsResult = await _localRepository.getAllocations();
    final portfolios = portfoliosResult.fold((_) => null, (value) => value);
    final allocations = allocationsResult.fold((_) => null, (value) => value);
    if (portfolios == null || allocations == null) {
      return;
    }
    final selectedStillExists = current.selectedPortfolioId ==
            PortfolioLoaded.totalPortfolioId ||
        current.selectedPortfolioId == PortfolioLoaded.unallocatedPortfolioId ||
        portfolios.any((item) => item.id == current.selectedPortfolioId);
    emit(
      current.copyWith(
        portfolios: portfolios,
        allocations: allocations,
        selectedPortfolioId: selectedStillExists
            ? current.selectedPortfolioId
            : PortfolioLoaded.totalPortfolioId,
      ),
    );
  }
}
