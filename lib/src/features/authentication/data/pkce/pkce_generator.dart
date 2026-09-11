import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class PkcePair {
  const PkcePair({
    required this.verifier,
    required this.challenge,
    required this.state,
  });

  final String verifier;
  final String challenge;
  final String state;
}

class PkceGenerator {
  const PkceGenerator();

  PkcePair generate() {
    final verifier = _randomUrlSafeString(64);
    final challengeBytes = sha256.convert(utf8.encode(verifier)).bytes;
    final challenge = base64UrlEncode(challengeBytes).replaceAll('=', '');

    return PkcePair(
      verifier: verifier,
      challenge: challenge,
      state: _randomUrlSafeString(24),
    );
  }

  String _randomUrlSafeString(int byteCount) {
    final random = Random.secure();
    final bytes = List<int>.generate(
      byteCount,
      (_) => random.nextInt(256),
      growable: false,
    );
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}
