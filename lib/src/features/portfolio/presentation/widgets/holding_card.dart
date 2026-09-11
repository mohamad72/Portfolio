import 'package:flutter/material.dart';

import '../../../../shared/format/number_formatters.dart';
import '../../domain/entities/portfolio_holding.dart';
import '../manager/portfolio_state.dart';

class HoldingCard extends StatelessWidget {
  const HoldingCard({
    required this.holding,
    this.onAllocate,
    required this.valueUnit,
    required this.ayarPriceToman,
    super.key,
  });

  final PortfolioHolding holding;
  final VoidCallback? onAllocate;
  final PortfolioValueUnit valueUnit;
  final num? ayarPriceToman;

  @override
  Widget build(BuildContext context) {
    final change = holding.priceChangePercent;
    final profit = holding.estimatedUnrealizedProfitToman;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        holding.symbolName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        holding.symbolIsin,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (onAllocate != null)
                  IconButton(
                    tooltip: 'تقسیم بین سبدها',
                    onPressed: onAllocate,
                    icon: const Icon(Icons.account_tree_outlined),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _row('تعداد', formatNumber(holding.quantity)),
            _row('قیمت مبنا', _formatValue(holding.marketPriceToman)),
            _row('ارزش', _formatValue(holding.currentValueToman)),
            _row('مبنای قیمت', _basisLabel(holding.marketPriceBasis)),
            if (holding.marketPriceBasis == MarketPriceBasis.bestBuyOrder &&
                holding.bestBuyQuantity != null)
              _row(
                'حجم بهترین خریدار',
                '${formatNumber(holding.bestBuyQuantity!)} سهم',
              ),
            if (holding.marketPriceBasis == MarketPriceBasis.bestBuyOrder &&
                holding.bestBuyQuantity != null &&
                holding.quantity > holding.bestBuyQuantity!)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'حجم بهترین خریدار از موجودی این نما کمتر است؛ فروش کل با این قیمت تضمین نمی‌شود.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ),
            if (change != null)
              _row(
                'تغییر قیمت نسبت به پایانی قبل',
                formatPercent(change),
                valueColor: _signedColor(context, change),
              ),
            if (profit != null)
              _row(
                'برآورد نسبت به سر‌به‌سر',
                _formatValue(profit),
                valueColor: _signedColor(context, profit.toDouble()),
              ),
            const SizedBox(height: 8),
            Text(
              'سود امروز/هفته/ماه: دادهٔ اجرای مستقل معاملات برای محاسبهٔ قطعی کافی نیست.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }


  String _formatValue(num? tomanValue) {
    if (tomanValue == null) {
      return 'ناموجود';
    }
    if (valueUnit == PortfolioValueUnit.toman) {
      return formatToman(tomanValue);
    }
    final price = ayarPriceToman;
    if (price == null || price <= 0) {
      return 'ناموجود';
    }
    return '${formatNumber(tomanValue / price, decimals: 4)} واحد عیار';
  }

  String _basisLabel(MarketPriceBasis basis) => switch (basis) {
        MarketPriceBasis.bestBuyOrder => 'بهترین سفارش خرید',
        MarketPriceBasis.lastTrade => 'آخرین معامله',
        MarketPriceBasis.closingPrice => 'قیمت پایانی',
        MarketPriceBasis.unavailable => 'ناموجود',
      };

  Color? _signedColor(BuildContext context, double value) {
    if (value > 0) {
      return Colors.green.shade700;
    }
    if (value < 0) {
      return Theme.of(context).colorScheme.error;
    }
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }
}
