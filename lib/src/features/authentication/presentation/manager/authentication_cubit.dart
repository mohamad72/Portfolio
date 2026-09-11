import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/login_request.dart';
import '../../domain/repository/authentication_repository.dart';
import '../../domain/use_case/complete_login.dart';
import '../../domain/use_case/get_login_request.dart';
import 'authentication_state.dart';

@lazySingleton
class AuthenticationCubit extends Cubit<AuthenticationState> {
  AuthenticationCubit(
    this._repository,
    this._getLoginRequest,
    this._completeLogin,
  ) : super(const AuthenticationUnknown());

  static const String redirectUri = 'https://m.easytrader.ir/auth-callback';

  final AuthenticationRepository _repository;
  final GetLoginRequest _getLoginRequest;
  final CompleteLogin _completeLogin;

  LoginRequest? _activeRequest;

  Future<void> checkSession() async {
    final hasSession = await _repository.hasSession();
    emit(
      hasSession
          ? const AuthenticationSignedIn()
          : const AuthenticationSignedOut(),
    );
  }

  void beginLogin() {
    final request = _getLoginRequest();
    _activeRequest = request;
    emit(AuthenticationLoginReady(request));
  }

  Future<void> completeRedirect(Uri uri) async {
    final request = _activeRequest;
    if (request == null) {
      emit(const AuthenticationError('فرآیند ورود فعال نیست.'));
      return;
    }

    final returnedState = uri.queryParameters['state'];
    final code = uri.queryParameters['code'];
    if (returnedState != request.state) {
      emit(const AuthenticationError('اعتبار state ورود مفید تأیید نشد.'));
      return;
    }
    if (code == null || code.isEmpty) {
      final error = uri.queryParameters['error_description'] ??
          uri.queryParameters['error'] ??
          'کد ورود از مفید دریافت نشد.';
      emit(AuthenticationError(error));
      return;
    }

    emit(AuthenticationCompleting(request));
    final result = await _completeLogin(
      code: code,
      codeVerifier: request.codeVerifier,
    );
    result.fold(
      (failure) => emit(AuthenticationError(failure.message)),
      (_) {
        _activeRequest = null;
        emit(const AuthenticationSignedIn());
      },
    );
  }

  Future<void> logout() async {
    await _repository.logout();
    _activeRequest = null;
    emit(const AuthenticationSignedOut());
  }
}
