import 'package:equatable/equatable.dart';

class ShareServerInfo extends Equatable {
  const ShareServerInfo({
    required this.addresses,
    required this.port,
    required this.username,
    required this.password,
  });

  final List<String> addresses;
  final int port;
  final String username;
  final String password;

  List<String> get urls => addresses
      .map((address) => 'http://$address:$port')
      .toList(growable: false);

  @override
  List<Object?> get props => <Object?>[addresses, port, username, password];
}
