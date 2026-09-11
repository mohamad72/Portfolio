import 'package:equatable/equatable.dart';

class MofidSession extends Equatable {
  const MofidSession({
    required this.accessToken,
    required this.tokenType,
    required this.expiresInSeconds,
  });

  final String accessToken;
  final String tokenType;
  final int expiresInSeconds;

  @override
  List<Object?> get props => <Object?>[
        accessToken,
        tokenType,
        expiresInSeconds,
      ];
}
