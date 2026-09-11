import 'package:equatable/equatable.dart';

import '../../domain/entities/investment_account.dart';
import '../../domain/entities/ipasargad_captcha.dart';

sealed class IPasargadLoginState extends Equatable {
  const IPasargadLoginState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class IPasargadLoginInitial extends IPasargadLoginState {
  const IPasargadLoginInitial();
}

final class IPasargadCaptchaLoading extends IPasargadLoginState {
  const IPasargadCaptchaLoading();
}

final class IPasargadCaptchaReady extends IPasargadLoginState {
  const IPasargadCaptchaReady(this.captcha, {this.submitting = false});

  final IPasargadCaptcha captcha;
  final bool submitting;

  @override
  List<Object?> get props => <Object?>[captcha, submitting];
}

final class IPasargadLoginSuccess extends IPasargadLoginState {
  const IPasargadLoginSuccess(this.account);

  final InvestmentAccount account;

  @override
  List<Object?> get props => <Object?>[account];
}

final class IPasargadLoginError extends IPasargadLoginState {
  const IPasargadLoginError(this.message, {this.captcha});

  final String message;
  final IPasargadCaptcha? captcha;

  @override
  List<Object?> get props => <Object?>[message, captcha];
}
