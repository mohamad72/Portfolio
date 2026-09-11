import 'package:equatable/equatable.dart';

sealed class AuthenticationState extends Equatable {
  const AuthenticationState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class AuthenticationUnknown extends AuthenticationState {
  const AuthenticationUnknown();
}

final class AuthenticationSignedOut extends AuthenticationState {
  const AuthenticationSignedOut();
}

final class AuthenticationLoggingIn extends AuthenticationState {
  const AuthenticationLoggingIn();
}

final class AuthenticationBiometricRequired extends AuthenticationState {
  const AuthenticationBiometricRequired({this.message});

  final String? message;

  @override
  List<Object?> get props => <Object?>[message];
}

final class AuthenticationBiometricAuthenticating extends AuthenticationState {
  const AuthenticationBiometricAuthenticating();
}

final class AuthenticationSignedIn extends AuthenticationState {
  const AuthenticationSignedIn();
}

final class AuthenticationError extends AuthenticationState {
  const AuthenticationError(this.message);

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
