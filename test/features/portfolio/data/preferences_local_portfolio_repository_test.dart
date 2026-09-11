import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/src/features/portfolio/data/repository/preferences_local_portfolio_repository_impl.dart';
import 'package:portfolio/src/features/portfolio/domain/entities/local_portfolio.dart';
import 'package:portfolio/src/shared/security/secure_session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _AccountSessionStore implements SessionStore {
  _AccountSessionStore(this.accountKey);

  String accountKey;

  @override
  Future<void> clear() async {}

  @override
  Future<String?> readAccessToken() async => 'token';

  @override
  Future<String?> readAccountKey() async => accountKey;

  @override
  Future<DateTime?> readExpiresAt() async =>
      DateTime.now().toUtc().add(const Duration(hours: 1));

  @override
  Future<void> writeSession({
    required String accessToken,
    required String accountKey,
    required DateTime expiresAt,
  }) async {
    this.accountKey = accountKey;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('local portfolios are scoped to the authenticated Mofid account', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final session = _AccountSessionStore('account-a');
    final repository = PreferencesLocalPortfolioRepositoryImpl(
      preferences,
      session,
    );

    await repository.savePortfolio(
      LocalPortfolio(
        id: 'mine',
        name: 'من',
        createdAt: DateTime.utc(2026, 9, 11),
      ),
    );

    var result = await repository.getPortfolios();
    result.fold(
      (failure) => fail(failure.message),
      (items) => expect(items.map((item) => item.id), contains('mine')),
    );

    session.accountKey = 'account-b';
    result = await repository.getPortfolios();
    result.fold(
      (failure) => fail(failure.message),
      (items) => expect(items, isEmpty),
    );
  });
}
