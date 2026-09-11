import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/src/features/authentication/data/remote/mofid_login_html_parser.dart';

void main() {
  const parser = MofidLoginHtmlParser();

  test('extracts antiforgery token and resolves relative form action', () {
    const html = '''
      <html>
        <body>
          <form id="primary_form" action="/Login?ReturnUrl=%2Fconnect%2Fauthorize" method="post">
            <input type="hidden" name="__RequestVerificationToken" value="csrf-token" />
          </form>
        </body>
      </html>
    ''';
    final pageUri = Uri.parse('https://login.emofid.com/Login');

    final challenge = parser.parseChallenge(html, pageUri);

    expect(challenge.requestVerificationToken, 'csrf-token');
    expect(
      challenge.postUri.toString(),
      'https://login.emofid.com/Login?ReturnUrl=%2Fconnect%2Fauthorize',
    );
  });

  test('uses current page uri when login form action is empty', () {
    const html = '''
      <form id="primary_form" method="post">
        <input name="__RequestVerificationToken" value="csrf-token" />
      </form>
    ''';
    final pageUri = Uri.parse(
      'https://login.emofid.com/Login?ReturnUrl=%2Fconnect%2Fauthorize',
    );

    final challenge = parser.parseChallenge(html, pageUri);

    expect(challenge.postUri, pageUri);
  });

  test('throws when antiforgery token is absent', () {
    expect(
      () => parser.parseChallenge(
        '<html><form id="primary_form"></form></html>',
        Uri.parse('https://login.emofid.com/Login'),
      ),
      throwsFormatException,
    );
  });
}
