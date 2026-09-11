import 'package:injectable/injectable.dart';

import '../../portfolio/domain/entities/account_snapshot.dart';
import '../../portfolio/domain/entities/portfolio_holding.dart';

@lazySingleton
class MarkdownPortfolioExporter {
  const MarkdownPortfolioExporter();

  String export({
    required String title,
    required AccountSnapshot snapshot,
    required List<PortfolioHolding> holdings,
  }) {
    num? holdingsValue = 0;
    for (final holding in holdings) {
      final value = holding.currentValueToman;
      if (value == null) {
        holdingsValue = null;
        break;
      }
      holdingsValue = holdingsValue! + value;
    }
    final buffer = StringBuffer()
      ..writeln('# پرتفوی — $title')
      ..writeln()
      ..writeln('- واحد پول: تومان')
      ..writeln('- زمان همگام‌سازی حساب‌ها: ${snapshot.syncedAt.toIso8601String()}')
      ..writeln('- دارایی‌های هم‌نام در حساب‌های مختلف جداگانه گزارش می‌شوند.')
      ..writeln(
        '- ارزش سهام این نما: ${holdingsValue == null ? 'ناموجود' : '${_formatNumber(holdingsValue)} تومان'}',
      );

    if (title == 'کل دارایی') {
      buffer
        ..writeln('- قدرت خرید مفید: ${_formatNumber(snapshot.buyingPowerToman)} تومان')
        ..writeln('- قدرت خرید سایر ارائه‌دهندگان فقط در صورت وجود قرارداد معتبر جداگانه اضافه می‌شود.');
    }

    if (snapshot.warnings.isNotEmpty) {
      buffer
        ..writeln('- هشدارهای همگام‌سازی:')
        ..writeln(snapshot.warnings.map((item) => '  - $item').join('\n'));
    }

    buffer
      ..writeln()
      ..writeln('| حساب | نماد | تعداد | قیمت مبنا (تومان) | ارزش (تومان) | مبنای قیمت |')
      ..writeln('|---|---|---:|---:|---:|---|');

    for (final holding in holdings) {
      buffer.writeln(
        '| ${holding.accountLabel} | ${holding.symbolName} | ${_formatNumber(holding.quantity)} | '
        '${holding.marketPriceBasis == MarketPriceBasis.unavailable ? 'ناموجود' : _formatNumber(holding.marketPriceToman)} | '
        '${holding.currentValueToman == null ? 'ناموجود' : _formatNumber(holding.currentValueToman!)} | '
        '${_basisLabel(holding.marketPriceBasis)} |',
      );
    }

    buffer
      ..writeln()
      ..writeln('> سود واقعی امروز/هفته/ماه فقط زمانی نمایش یا صادر می‌شود که تاریخچهٔ اجرای معاملات و جریان‌های نقدی برای همان بازه کافی باشد.')
      ..writeln()
      ..writeln('منابع: مفید و آی‌پاسارگاد برای موجودی حساب‌های متصل؛ TGJU برای اقلام عمومی بازار.');

    return buffer.toString();
  }

  String _basisLabel(MarketPriceBasis basis) => switch (basis) {
        MarketPriceBasis.bestBuyOrder => 'بهترین سفارش خرید',
        MarketPriceBasis.lastTrade => 'آخرین معامله',
        MarketPriceBasis.closingPrice => 'قیمت پایانی',
        MarketPriceBasis.sourceSellPrice => 'قیمت فروش/ابطال منبع',
        MarketPriceBasis.unavailable => 'ناموجود',
      };

  String _formatNumber(num value) {
    final negative = value < 0;
    final absolute = value.abs();
    final raw = absolute % 1 == 0
        ? absolute.toInt().toString()
        : absolute.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
    final parts = raw.split('.');
    final digits = parts.first;
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      final remaining = digits.length - index;
      buffer.write(digits[index]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    if (parts.length > 1) {
      buffer.write('.${parts.last}');
    }
    return '${negative ? '-' : ''}$buffer';
  }
}
