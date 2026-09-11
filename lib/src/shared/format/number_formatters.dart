String formatNumber(num value, {int decimals = 2}) {
  final negative = value < 0;
  final absolute = value.abs();
  final raw = absolute % 1 == 0
      ? absolute.toInt().toString()
      : absolute
          .toStringAsFixed(decimals)
          .replaceFirst(RegExp(r'\.?0+$'), '');
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

String formatToman(num value) => '${formatNumber(value)} تومان';

String formatPercent(double? value) {
  if (value == null) {
    return 'ناموجود';
  }
  final prefix = value > 0 ? '+' : '';
  return '$prefix${formatNumber(value)}٪';
}
