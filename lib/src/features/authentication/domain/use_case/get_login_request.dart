import 'package:injectable/injectable.dart';

import '../../data/pkce/pkce_generator.dart';
import '../entities/login_request.dart';

@lazySingleton
class GetLoginRequest {
  const GetLoginRequest();

  static const String _authorizationEndpoint =
      'https://login.emofid.com/connect/authorize';
  static const String _clientId = 'easy_pkce';
  static const String _redirectUri = 'https://m.easytrader.ir/auth-callback';
  static const String _scope =
      'easy2_api mts_api openid profile login_delegation-api';

  LoginRequest call() {
    const generator = PkceGenerator();
    final pair = generator.generate();
    final uri = Uri.parse(_authorizationEndpoint).replace(
      queryParameters: <String, String>{
        'client_id': _clientId,
        'redirect_uri': _redirectUri,
        'response_type': 'code',
        'scope': _scope,
        'state': pair.state,
        'code_challenge': pair.challenge,
        'code_challenge_method': 'S256',
      },
    );

    return LoginRequest(
      authorizationUri: uri,
      codeVerifier: pair.verifier,
      state: pair.state,
    );
  }
}
