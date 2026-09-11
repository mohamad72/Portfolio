import 'package:html/parser.dart' as html_parser;

class MofidLoginChallenge {
  const MofidLoginChallenge({
    required this.postUri,
    required this.requestVerificationToken,
  });

  final Uri postUri;
  final String requestVerificationToken;
}

class MofidLoginHtmlParser {
  const MofidLoginHtmlParser();

  MofidLoginChallenge parseChallenge(String html, Uri pageUri) {
    final document = html_parser.parse(html);
    final tokenElement = document.querySelector(
      'input[name="__RequestVerificationToken"]',
    );
    final token = tokenElement?.attributes['value']?.trim();
    if (token == null || token.isEmpty) {
      throw const FormatException(
        'توکن ضد جعل فرم ورود مفید در صفحه پیدا نشد.',
      );
    }

    final form = document.querySelector('form#primary_form') ??
        document.querySelector('form');
    final action = form?.attributes['action']?.trim();
    final postUri = action == null || action.isEmpty
        ? pageUri
        : pageUri.resolve(action);

    return MofidLoginChallenge(
      postUri: postUri,
      requestVerificationToken: token,
    );
  }

  String? extractErrorMessage(String html) {
    final document = html_parser.parse(html);
    const selectors = <String>[
      '.validation-summary-errors',
      '.field-validation-error',
      '.text-danger',
      '[role="alert"]',
    ];
    for (final selector in selectors) {
      final text = document.querySelector(selector)?.text.trim();
      if (text != null && text.isNotEmpty) {
        return text.replaceAll(RegExp(r'\s+'), ' ');
      }
    }
    return null;
  }
}
