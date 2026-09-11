import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio/src/features/export/domain/markdown_portfolio_exporter.dart';
import 'package:portfolio/src/features/portfolio/domain/entities/account_snapshot.dart';
import 'package:portfolio/src/features/portfolio/domain/entities/portfolio_holding.dart';

void main() {
  const exporter = MarkdownPortfolioExporter();

  test('exports portfolio data without authentication secrets', () {
    const holding = PortfolioHolding(
      symbolIsin: 'IRTKMOFD0001',
      symbolName: 'عیار',
      quantity: 10,
      marketPriceToman: 50000,
      marketPriceBasis: MarketPriceBasis.lastTrade,
    );
    final snapshot = AccountSnapshot(
      holdings: const <PortfolioHolding>[holding],
      buyingPowerToman: 100000,
      syncedAt: DateTime(2026, 9, 11, 12),
    );

    final markdown = exporter.export(
      title: 'کل دارایی',
      snapshot: snapshot,
      holdings: snapshot.holdings,
    );

    expect(markdown, contains('کل دارایی'));
    expect(markdown, contains('عیار'));
    expect(markdown.toLowerCase(), isNot(contains('access_token')));
    expect(markdown.toLowerCase(), isNot(contains('password')));
    expect(markdown.toLowerCase(), isNot(contains('authorization')));
  });
}
