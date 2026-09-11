import 'package:equatable/equatable.dart';

class IPasargadCaptcha extends Equatable {
  const IPasargadCaptcha({
    required this.imageBase64,
    required this.salt,
    required this.hash,
  });

  final String imageBase64;
  final String salt;
  final String hash;

  @override
  List<Object?> get props => <Object?>[imageBase64, salt, hash];
}
