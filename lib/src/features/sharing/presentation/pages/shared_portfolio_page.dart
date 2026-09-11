import 'package:flutter/material.dart';

import '../../../../shared/format/number_formatters.dart';
import '../../../portfolio/domain/entities/portfolio_holding.dart';
import '../../../portfolio/presentation/manager/portfolio_state.dart';
import '../../../portfolio/presentation/widgets/holding_card.dart';
import '../../domain/entities/shared_portfolio_bundle.dart';

class SharedPortfolioPage extends StatefulWidget {
  const SharedPortfolioPage({required this.bundle, super.key});

  final SharedPortfolioBundle bundle;

  @override
  State<SharedPortfolioPage> createState() => _SharedPortfolioPageState();
}

class _SharedPortfolioPageState extends State<SharedPortfolioPage> {
  String _selectedPortfolioId = SharedPortfolioBundle.totalPortfolioId;
  PortfolioValueUnit _valueUnit = PortfolioValueUnit.toman;

  @override
  Widget build(BuildContext context) {
    final holdings = widget.bundle.holdingsForPortfolio(_selectedPortfolioId);
    return Scaffold(
      appBar: AppBar(title: const Text('پرتفوی اشتراکی')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: <Widget>[
          DropdownButtonFormField<String>(
            value: _selectedPortfolioId,
            decoration: const InputDecoration(
              labelText: 'سبد',
              border: OutlineInputBorder(),
            ),
            items: <DropdownMenuItem<String>>[
              const DropdownMenuItem<String>(
                value: SharedPortfolioBundle.totalPortfolioId,
                child: Text('کل دارایی'),
              ),
              for (final portfolio in widget.bundle.portfolios)
                DropdownMenuItem<String>(
                  value: portfolio.id,
                  child: Text(portfolio.name),
                ),
              const DropdownMenuItem<String>(
                value: SharedPortfolioBundle.unallocatedPortfolioId,
                child: Text('تخصیص‌نیافته'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedPortfolioId = value);
              }
            },
          ),
          const SizedBox(height: 12),
          _summaryCard(context, holdings),
          const SizedBox(height: 12),
          if (holdings.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'در این سبد دارایی تخصیص‌یافته‌ای وجود ندارد.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            for (final holding in holdings) ...<Widget>[
              HoldingCard(
                holding: holding,
                valueUnit: _valueUnit,
                ayarPriceToman: widget.bundle.snapshot.ayarPriceToman,
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  Widget _summaryCard(
    BuildContext context,
    List<PortfolioHolding> holdings,
  ) {
    final value = _holdingsValue(holdings);
    final isTotal =
        _selectedPortfolioId == SharedPortfolioBundle.totalPortfolioId;
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
                    widget.bundle.portfolioTitle(_selectedPortfolioId),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                SegmentedButton<PortfolioValueUnit>(
                  segments: const <ButtonSegment<PortfolioValueUnit>>[
                    ButtonSegment<PortfolioValueUnit>(
                      value: PortfolioValueUnit.toman,
                      label: Text('تومان'),
                    ),
                    ButtonSegment<PortfolioValueUnit>(
                      value: PortfolioValueUnit.ayar,
                      label: Text('عیار'),
                    ),
                  ],
                  selected: <PortfolioValueUnit>{_valueUnit},
                  onSelectionChanged: (selection) {
                    setState(() => _valueUnit = selection.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _row('ارزش سهام', _formatValue(value)),
            if (isTotal)
              _row(
                'قدرت خرید گزارش‌شده',
                _formatValue(widget.bundle.snapshot.buyingPowerToman),
              ),
            _row(
              'زمان همگام‌سازی مفید',
              widget.bundle.snapshot.syncedAt.toLocal().toString(),
            ),
            _row(
              'زمان انتشار برای اشتراک',
              widget.bundle.publishedAt.toLocal().toString(),
            ),
            const SizedBox(height: 8),
            Text(
              'این صفحه فقط خواندنی است و آخرین snapshot منتشرشده از گوشی مالک را نشان می‌دهد.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  num? _holdingsValue(List<PortfolioHolding> holdings) {
    var total = 0.0;
    for (final holding in holdings) {
      final value = holding.currentValueToman;
      if (value == null) {
        return null;
      }
      total += value.toDouble();
    }
    return total;
  }

  String _formatValue(num? value) {
    if (value == null) {
      return 'ناموجود';
    }
    if (_valueUnit == PortfolioValueUnit.toman) {
      return formatToman(value);
    }
    final ayarPrice = widget.bundle.snapshot.ayarPriceToman;
    if (ayarPrice == null || ayarPrice <= 0) {
      return 'ناموجود';
    }
    return '${formatNumber(value / ayarPrice, decimals: 4)} واحد عیار';
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(label)),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
}
