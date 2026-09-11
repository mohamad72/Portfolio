import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../shared/error/failure.dart';
import '../../../../shared/network/remote_data_source.dart';
import '../../domain/entities/broker_provider.dart';
import '../../domain/entities/investment_account.dart';
import '../../domain/entities/ipasargad_captcha.dart';
import '../../domain/repository/broker_account_repository.dart';
import '../../domain/repository/ipasargad_authentication_repository.dart';
import '../security/ipasargad_session_store.dart';

@LazySingleton(as: IPasargadAuthenticationRepository)
class IPasargadAuthenticationRepositoryImpl
    implements IPasargadAuthenticationRepository {
  IPasargadAuthenticationRepositoryImpl(
    this._remoteDataSource,
    this._accountRepository,
    this._sessionStore,
  );

  static const String _identityBaseUrl = 'https://identity.ipasargad.ir';
  static const String _captchaUrl = '$_identityBaseUrl/captcha/getCaptcha';
  static const String _loginUrl = '$_identityBaseUrl/Account/Login';

  final RemoteDataSource _remoteDataSource;
  final BrokerAccountRepository _accountRepository;
  final IPasargadSessionStore _sessionStore;

  @override
  Future<Either<Failure, IPasargadCaptcha>> getCaptcha() async {
    try {
      final response = await _remoteDataSource.getJson(
        _captchaUrl,
        headers: _publicHeaders,
      );
      final image = response['captchaByteData']?.toString() ?? '';
      final salt = response['salt']?.toString() ?? '';
      final hash = response['hashedCaptcha']?.toString() ?? '';
      if (image.isEmpty || salt.isEmpty || hash.isEmpty) {
        return left(const Failure('ساختار کپچای آی‌پاسارگاد معتبر نیست.'));
      }
      return right(
        IPasargadCaptcha(imageBase64: image, salt: salt, hash: hash),
      );
    } catch (error) {
      return left(Failure('دریافت کپچای آی‌پاسارگاد ناموفق بود.', cause: error));
    }
  }

  @override
  Future<Either<Failure, InvestmentAccount>> login({
    required String loginName,
    required String password,
    required String captchaValue,
    required String captchaHash,
    required String captchaSalt,
    required String accountLabel,
  }) async {
    final normalizedLoginName = loginName.trim();
    final normalizedLabel = accountLabel.trim().isEmpty
        ? 'آی‌پاسارگاد'
        : accountLabel.trim();
    if (normalizedLoginName.isEmpty || password.isEmpty) {
      return left(const Failure('نام کاربری و رمز آی‌پاسارگاد را وارد کنید.'));
    }
    if (captchaValue.trim().isEmpty) {
      return left(const Failure('کد کپچا را وارد کنید.'));
    }

    try {
      final response = await _remoteDataSource.postJson(
        _loginUrl,
        body: <String, dynamic>{
          'loginName': normalizedLoginName,
          'password': password,
          'captcha': <String, dynamic>{
            'hash': captchaHash,
            'salt': captchaSalt,
            'value': captchaValue.trim(),
          },
        },
        headers: _publicHeaders,
      );

      final success = response['isSuccess'] == true;
      final token = response['token']?.toString() ?? '';
      final expireIn = _int(response['expireIn']);
      if (!success || token.isEmpty || expireIn == null || expireIn <= 0) {
        final message = response['errorMessage']?.toString().trim();
        return left(
          Failure(
            message == null || message.isEmpty
                ? 'ورود به آی‌پاسارگاد ناموفق بود.'
                : message,
          ),
        );
      }

      final account = InvestmentAccount(
        id: 'ipasargad_${DateTime.now().microsecondsSinceEpoch}',
        provider: BrokerProvider.iPasargad,
        label: normalizedLabel,
      );
      await _sessionStore.writeSession(
        accountId: account.id,
        token: token,
        expiresAt: DateTime.now().toUtc().add(Duration(seconds: expireIn)),
      );
      final saveResult = await _accountRepository.saveAccount(account);
      final saveFailure = saveResult.fold<Failure?>((value) => value, (_) => null);
      if (saveFailure != null) {
        await _sessionStore.clear(account.id);
        return left(saveFailure);
      }
      return right(account);
    } catch (error) {
      return left(Failure('ورود به آی‌پاسارگاد ناموفق بود.', cause: error));
    }
  }

  @override
  Future<void> logout(String accountId) => _sessionStore.clear(accountId);

  Map<String, dynamic> get _publicHeaders => const <String, dynamic>{
        'Accept': 'application/json, text/plain, */*',
        'Origin': 'https://app.ipasargad.ir',
        'Referer': 'https://app.ipasargad.ir/',
        'WebApp-Version': '1.0.0 (12)',
      };

  int? _int(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }
}
