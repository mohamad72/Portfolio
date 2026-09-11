import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/src/features/authentication/data/pkce/pkce_generator.dart';

void main() {
  const generator = PkceGenerator();

  test('generates URL-safe verifier, challenge and state', () {
    final pair = generator.generate();

    expect(pair.verifier.length, greaterThanOrEqualTo(43));
    expect(pair.verifier.length, lessThanOrEqualTo(128));
    expect(pair.verifier, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
    expect(pair.challenge, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
    expect(pair.challenge, isNot(pair.verifier));
    expect(pair.state, matches(RegExp(r'^[A-Za-z0-9_-]+$')));
  });
}
