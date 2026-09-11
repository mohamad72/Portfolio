import 'package:equatable/equatable.dart';

import '../../domain/entities/login_request.dart';

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

final class AuthenticationLoginReady extends AuthenticationState {
  const AuthenticationLoginReady(this.request);

  final LoginRequest request;

  @override
  List<Object?> get props => <Object?>[request];
}

final class AuthenticationCompleting extends AuthenticationState {
  const AuthenticationCompleting(this.request);

  final LoginRequest request;

  @override
  List<Object?> get props => <Object?>[request];
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
