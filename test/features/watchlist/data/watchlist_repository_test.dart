import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/src/features/watchlist/data/repository/watchlist_repository_impl.dart';
import 'package:portfolio/src/features/watchlist/domain/entities/watch_symbol.dart';
import 'package:portfolio/src/shared/network/remote_data_source.dart';
import 'package:portfolio/src/shared/security/secure_session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoopRemote implements RemoteDataSource {
  @override
  Future<Map<String, dynamic>> getJson(String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async => <String, dynamic>{};

  @override
  Future<Map<String, dynamic>> postForm(String url, {
    required Map<String, dynamic> body,
    Map<String, dynamic>? headers,
  }) async => <String, dynamic>{};

  @override
  Future<Map<String, dynamic>> postJson(String url, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async => <String, dynamic>{};
}

class _NoSessionStore implements SessionStore {
  _NoSessionStore({this.accountKey = 'account'});

  String accountKey;
  @override
  Future<void> clear() async {}

  @override
  Future<String?> readAccessToken() async => null;

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
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('add is idempotent and remove persists locally', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final repository = WatchlistRepositoryImpl(
      preferences,
      _NoopRemote(),
      _NoSessionStore(),
    );
    const symbol = WatchSymbol(
      symbolIsin: 'IRTKMOFD0001',
      symbolName: 'عیار',
      title: 'صندوق طلای عیار مفید',
    );

    await repository.add(symbol);
    await repository.add(symbol);
    var selected = await repository.getSelected();
    selected.fold(
      (failure) => fail(failure.message),
      (items) => expect(items, hasLength(1)),
    );

    await repository.remove(symbol.symbolIsin);
    selected = await repository.getSelected();
    selected.fold(
      (failure) => fail(failure.message),
      (items) => expect(items, isEmpty),
    );
  });

  test('selected watch symbols are isolated by account key', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final session = _NoSessionStore(accountKey: 'account-a');
    final repository = WatchlistRepositoryImpl(
      preferences,
      _NoopRemote(),
      session,
    );
    const symbol = WatchSymbol(
      symbolIsin: 'IRTKMOFD0001',
      symbolName: 'عیار',
      title: 'صندوق طلای عیار مفید',
    );

    await repository.add(symbol);
    session.accountKey = 'account-b';

    final selected = await repository.getSelected();
    selected.fold(
      (failure) => fail(failure.message),
      (items) => expect(items, isEmpty),
    );
  });
}
