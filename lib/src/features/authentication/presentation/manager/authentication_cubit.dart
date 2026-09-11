import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../shared/error/failure.dart';
import '../../domain/repository/authentication_repository.dart';
import 'authentication_state.dart';

@lazySingleton
class AuthenticationCubit extends Cubit<AuthenticationState> {
  AuthenticationCubit(this._repository)
      : super(const AuthenticationUnknown());

  final AuthenticationRepository _repository;

  Future<void> checkSession() async {
    try {
      final hasSavedCredentials = await _repository.hasSavedCredentials();
      final canUseBiometrics = hasSavedCredentials &&
          await _repository.canAuthenticateWithBiometrics();

      if (canUseBiometrics) {
        emit(const AuthenticationBiometricRequired());
        return;
      }

      final hasSession = await _repository.hasSession();
      emit(
        hasSession
            ? const AuthenticationSignedIn()
            : const AuthenticationSignedOut(),
      );
    } catch (error, stackTrace) {
      emit(
        AuthenticationError(
          Failure.detailed(
            'بررسی نشست و قابلیت اثر انگشت ناموفق بود.',
            error,
            stackTrace,
          ).message,
        ),
      );
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    emit(const AuthenticationLoggingIn());
    final result = await _repository.login(
      username: username,
      password: password,
    );
    result.fold(
      (failure) => emit(AuthenticationError(failure.message)),
      (_) => emit(const AuthenticationSignedIn()),
    );
  }

  Future<void> unlockWithBiometrics() async {
    emit(const AuthenticationBiometricAuthenticating());
    final biometricResult = await _repository.authenticateWithBiometrics();
    final biometricFailure = biometricResult.fold(
      (failure) => failure,
      (_) => null,
    );
    if (biometricFailure != null) {
      emit(AuthenticationBiometricRequired(message: biometricFailure.message));
      return;
    }

    if (await _repository.hasSession()) {
      emit(const AuthenticationSignedIn());
      return;
    }

    final loginResult = await _repository.loginWithSavedCredentials();
    loginResult.fold(
      (failure) => emit(AuthenticationError(failure.message)),
      (_) => emit(const AuthenticationSignedIn()),
    );
  }

  Future<void> logout({bool forgetCredentials = false}) async {
    await _repository.logout(forgetCredentials: forgetCredentials);
    emit(const AuthenticationSignedOut());
  }
}
