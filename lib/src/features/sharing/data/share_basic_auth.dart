import 'dart:convert';

import 'share_credentials.dart';

abstract final class ShareBasicAuth {
  static String authorizationHeader(String username, String password) {
    final encoded = base64Encode(utf8.encode('$username:$password'));
    return 'Basic $encoded';
  }

  static bool isAuthorized(String? authorizationHeader) {
    return authorizationHeader ==
        ShareBasicAuth.authorizationHeader(
          ShareCredentials.username,
          ShareCredentials.password,
        );
  }
}
