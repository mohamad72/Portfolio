import 'package:flutter/material.dart';

import '../../domain/entities/market_price.dart';

class MarketPriceCard extends StatelessWidget {
  const MarketPriceCard({required this.price, super.key});

  final MarketPrice price;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final change = price.changePercent;
    final changeText = change == null
        ? 'ناموجود'
        : '${change > 0 ? '+' : ''}${_formatDecimal(change)}٪';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    price.title,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  changeText,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: _changeColor(context, change),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _displayPrice(price),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _metaText(price),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _displayPrice(MarketPrice price) {
    if (price.hasVerifiedTomanValue) {
      final value = price.priceToman;
      return value == null ? 'ناموجود' : '${_formatNumber(value)} تومان';
    }

    final raw = price.rawPrice;
    if (raw == null) {
      return 'ناموجود';
    }
    return '${_formatNumber(raw)} (واحد منبع)';
  }

  String _metaText(MarketPrice price) {
    final time = price.sourceTimestampRaw ?? 'زمان ناموجود';
    if (price.hasVerifiedTomanValue) {
      return '${price.source} • $time';
    }
    return '${price.source} • $time • تبدیل به تومان هنوز تأیید نشده';
  }

  Color? _changeColor(BuildContext context, double? value) {
    if (value == null || value == 0) {
      return Theme.of(context).colorScheme.onSurfaceVariant;
    }
    if (value > 0) {
      return Colors.green.shade700;
    }
    return Theme.of(context).colorScheme.error;
  }

  String _formatNumber(num value) {
    final rounded = value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
    final parts = rounded.split('.');
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
    return buffer.toString();
  }

  String _formatDecimal(double value) {
    final text = value.toStringAsFixed(2);
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}
