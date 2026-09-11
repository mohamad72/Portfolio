import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/src/features/accounts/data/repository/ipasargad_authentication_repository_impl.dart';
import 'package:portfolio/src/features/accounts/domain/entities/broker_provider.dart';
import 'package:portfolio/src/features/accounts/domain/entities/investment_account.dart';
import 'package:portfolio/src/features/accounts/domain/repository/broker_account_repository.dart';
import 'package:portfolio/src/features/accounts/data/security/ipasargad_session_store.dart';
import 'package:portfolio/src/shared/error/failure.dart';
import 'package:portfolio/src/shared/network/remote_data_source.dart';
import 'package:dartz/dartz.dart';

class _Remote implements RemoteDataSource {
  Map<String, dynamic>? lastLoginBody;

  @override
  Future<Map<String, dynamic>> getJson(
    String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    if (url.endsWith('/captcha/getCaptcha')) {
      return <String, dynamic>{
        'captchaByteData': 'YWJj',
        'salt': 'salt-value',
        'hashedCaptcha': 'hash-value',
      };
    }
    throw StateError('Unexpected GET $url');
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String url, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    if (url.endsWith('/Account/Login')) {
      lastLoginBody = (body! as Map).map<String, dynamic>(
        (key, value) => MapEntry(key.toString(), value),
      );
      return <String, dynamic>{
        'token': 'token-123',
        'sessionId': 'session-1',
        'expireIn': 28800,
        'step': 100,
        'isSuccess': true,
        'errorMessage': '',
        'errorCode': 0,
      };
    }
    throw StateError('Unexpected POST $url');
  }

  @override
  Future<Map<String, dynamic>> postForm(
    String url, {
    required Map<String, dynamic> body,
    Map<String, dynamic>? headers,
  }) => throw UnimplementedError();
}

class _Accounts implements BrokerAccountRepository {
  InvestmentAccount? saved;

  @override
  Future<Either<Failure, List<InvestmentAccount>>> getAccounts() async =>
      right(saved == null ? const <InvestmentAccount>[] : <InvestmentAccount>[saved!]);

  @override
  Future<Either<Failure, Unit>> saveAccount(InvestmentAccount account) async {
    saved = account;
    return right(unit);
  }

  @override
  Future<Either<Failure, Unit>> deleteAccount(String id) async {
    saved = null;
    return right(unit);
  }
}

class _Sessions implements IPasargadSessionStore {
  String? accountId;
  String? token;
  DateTime? expiresAt;

  @override
  Future<void> clear(String accountId) async {
    token = null;
    expiresAt = null;
  }

  @override
  Future<String?> readToken(String accountId) async => token;

  @override
  Future<DateTime?> readExpiresAt(String accountId) async => expiresAt;

  @override
  Future<void> writeSession({
    required String accountId,
    required String token,
    required DateTime expiresAt,
  }) async {
    this.accountId = accountId;
    this.token = token;
    this.expiresAt = expiresAt;
  }
}

void main() {
  test('maps captcha contract from iPasargad response', () async {
    final repository = IPasargadAuthenticationRepositoryImpl(
      _Remote(),
      _Accounts(),
      _Sessions(),
    );

    final result = await repository.getCaptcha();

    result.fold(
      (failure) => fail(failure.message),
      (captcha) {
        expect(captcha.imageBase64, 'YWJj');
        expect(captcha.salt, 'salt-value');
        expect(captcha.hash, 'hash-value');
      },
    );
  });

  test('sends observed captcha login shape and stores token session', () async {
    final remote = _Remote();
    final accounts = _Accounts();
    final sessions = _Sessions();
    final repository = IPasargadAuthenticationRepositoryImpl(
      remote,
      accounts,
      sessions,
    );

    final result = await repository.login(
      loginName: 'user',
      password: 'pass',
      captchaValue: '1234',
      captchaHash: 'hash-value',
      captchaSalt: 'salt-value',
      accountLabel: 'آی‌پاسارگاد من',
    );

    result.fold(
      (failure) => fail(failure.message),
      (account) {
        expect(account.provider, BrokerProvider.iPasargad);
        expect(account.label, 'آی‌پاسارگاد من');
        expect(sessions.accountId, account.id);
        expect(sessions.token, 'token-123');
        expect(accounts.saved, account);
      },
    );
    expect(remote.lastLoginBody?['loginName'], 'user');
    expect(remote.lastLoginBody?['password'], 'pass');
    expect(remote.lastLoginBody?['captcha'], <String, dynamic>{
      'hash': 'hash-value',
      'salt': 'salt-value',
      'value': '1234',
    });
  });
}
