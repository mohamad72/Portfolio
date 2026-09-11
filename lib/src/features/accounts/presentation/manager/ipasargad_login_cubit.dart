import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/ipasargad_captcha.dart';
import '../../domain/repository/ipasargad_authentication_repository.dart';
import 'ipasargad_login_state.dart';

@injectable
class IPasargadLoginCubit extends Cubit<IPasargadLoginState> {
  IPasargadLoginCubit(this._repository) : super(const IPasargadLoginInitial());

  final IPasargadAuthenticationRepository _repository;

  IPasargadCaptcha? _captcha;

  Future<void> loadCaptcha() async {
    emit(const IPasargadCaptchaLoading());
    final result = await _repository.getCaptcha();
    result.fold(
      (failure) => emit(IPasargadLoginError(failure.message)),
      (captcha) {
        _captcha = captcha;
        emit(IPasargadCaptchaReady(captcha));
      },
    );
  }

  Future<void> login({
    required String loginName,
    required String password,
    required String captchaValue,
    required String accountLabel,
  }) async {
    final captcha = _captcha;
    if (captcha == null) {
      emit(const IPasargadLoginError('ابتدا کپچا را دریافت کنید.'));
      return;
    }
    emit(IPasargadCaptchaReady(captcha, submitting: true));
    final result = await _repository.login(
      loginName: loginName,
      password: password,
      captchaValue: captchaValue,
      captchaHash: captcha.hash,
      captchaSalt: captcha.salt,
      accountLabel: accountLabel,
    );
    result.fold(
      (failure) async {
        emit(IPasargadLoginError(failure.message, captcha: captcha));
        await loadCaptcha();
      },
      (account) => emit(IPasargadLoginSuccess(account)),
    );
  }
}
