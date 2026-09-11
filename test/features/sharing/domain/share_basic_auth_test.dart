import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/src/features/sharing/data/share_basic_auth.dart';
import 'package:portfolio/src/features/sharing/data/share_credentials.dart';

void main() {
  test('accepts the configured Basic auth credentials', () {
    final header = ShareBasicAuth.authorizationHeader(
      ShareCredentials.username,
      ShareCredentials.password,
    );

    expect(ShareBasicAuth.isAuthorized(header), isTrue);
  });

  test('rejects a wrong password', () {
    final header = ShareBasicAuth.authorizationHeader(
      ShareCredentials.username,
      'wrong-password',
    );

    expect(ShareBasicAuth.isAuthorized(header), isFalse);
  });
}
