import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/src/features/accounts/data/repository/preferences_broker_account_repository_impl.dart';
import 'package:portfolio/src/features/accounts/domain/entities/broker_provider.dart';
import 'package:portfolio/src/features/accounts/domain/entities/investment_account.dart';
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

  test('additional broker accounts are scoped to the primary Mofid account',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final session = _AccountSessionStore('account-a');
    final repository = PreferencesBrokerAccountRepositoryImpl(
      preferences,
      session,
    );

    await repository.saveAccount(
      const InvestmentAccount(
        id: 'ipas-a',
        provider: BrokerProvider.iPasargad,
        label: 'آی‌پاسارگاد من',
      ),
    );

    var result = await repository.getAccounts();
    result.fold(
      (failure) => fail(failure.message),
      (items) => expect(items.map((item) => item.id), contains('ipas-a')),
    );

    session.accountKey = 'account-b';
    result = await repository.getAccounts();
    result.fold(
      (failure) => fail(failure.message),
      (items) => expect(items, isEmpty),
    );
  });
}
