import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/src/features/portfolio/domain/entities/holding_allocation.dart';
import 'package:portfolio/src/features/portfolio/domain/entities/local_portfolio.dart';
import 'package:portfolio/src/features/portfolio/domain/repository/local_portfolio_repository.dart';
import 'package:portfolio/src/features/portfolio/domain/use_case/save_symbol_allocations.dart';
import 'package:portfolio/src/shared/error/failure.dart';

class _FakeLocalPortfolioRepository implements LocalPortfolioRepository {
  List<HoldingAllocation> saved = <HoldingAllocation>[];

  @override
  Future<Either<Failure, Unit>> deletePortfolio(String id) async => right(unit);

  @override
  Future<Either<Failure, List<HoldingAllocation>>> getAllocations() async =>
      right(saved);

  @override
  Future<Either<Failure, List<LocalPortfolio>>> getPortfolios() async =>
      right(const <LocalPortfolio>[]);

  @override
  Future<Either<Failure, Unit>> replaceSymbolAllocations(
    String symbolIsin,
    List<HoldingAllocation> allocations,
  ) async {
    saved = List<HoldingAllocation>.from(allocations);
    return right(unit);
  }

  @override
  Future<Either<Failure, Unit>> savePortfolio(LocalPortfolio portfolio) async =>
      right(unit);
}

void main() {
  late _FakeLocalPortfolioRepository repository;
  late SaveSymbolAllocations useCase;

  setUp(() {
    repository = _FakeLocalPortfolioRepository();
    useCase = SaveSymbolAllocations(repository);
  });

  test('accepts a partial allocation and leaves remainder unallocated', () async {
    final result = await useCase(
      symbolIsin: 'ISIN',
      totalQuantity: 100,
      allocations: <String, num>{'mine': 40, 'father': 20},
    );

    expect(result.isRight(), isTrue);
    expect(repository.saved.fold<num>(0, (sum, item) => sum + item.quantity), 60);
  });

  test('rejects allocations above synced total quantity', () async {
    final result = await useCase(
      symbolIsin: 'ISIN',
      totalQuantity: 100,
      allocations: <String, num>{'mine': 60, 'father': 50},
    );

    expect(result.isLeft(), isTrue);
    expect(repository.saved, isEmpty);
  });

  test('rejects negative quantities', () async {
    final result = await useCase(
      symbolIsin: 'ISIN',
      totalQuantity: 100,
      allocations: <String, num>{'mine': -1},
    );

    expect(result.isLeft(), isTrue);
    expect(repository.saved, isEmpty);
  });
}
