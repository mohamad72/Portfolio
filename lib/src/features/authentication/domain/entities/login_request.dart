import 'package:equatable/equatable.dart';

class LoginRequest extends Equatable {
  const LoginRequest({
    required this.authorizationUri,
    required this.codeVerifier,
    required this.state,
  });

  final Uri authorizationUri;
  final String codeVerifier;
  final String state;

  @override
  List<Object?> get props => <Object?>[
        authorizationUri,
        codeVerifier,
        state,
      ];
}
