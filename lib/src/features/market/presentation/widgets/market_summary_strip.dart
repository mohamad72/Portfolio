import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../manager/market_cubit.dart';
import '../manager/market_state.dart';
import '../../domain/entities/market_price.dart';

class MarketSummaryStrip extends StatelessWidget {
  const MarketSummaryStrip({super.key});

  static const Set<String> _primaryCodes = <String>{
    'price_dollar_rl',
    'price_eur',
    'sekee',
    'geram18',
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MarketCubit, MarketState>(
      builder: (context, state) {
        if (state is MarketLoading || state is MarketInitial) {
          return const SizedBox(
            height: 74,
            child: Center(child: LinearProgressIndicator()),
          );
        }
        if (state is MarketError) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_off_outlined),
              title: const Text('قیمت‌های عمومی بازار در دسترس نیست.'),
              trailing: IconButton(
                tooltip: 'تلاش دوباره',
                onPressed: () => context.read<MarketCubit>().load(),
                icon: const Icon(Icons.refresh),
              ),
            ),
          );
        }

        final loaded = state as MarketLoaded;
        final prices = loaded.prices
            .where((item) => _primaryCodes.contains(item.code))
            .toList(growable: false);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: prices.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) => _MarketChip(
                  price: prices[index],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'حباب طلای ۱۸ عیار: ناموجود در قرارداد فعلی TGJU. حباب سکه با آن یکی نیست.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }
}

class _MarketChip extends StatelessWidget {
  const _MarketChip({required this.price});

  final MarketPrice price;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: SizedBox(
        width: 155,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                price.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 5),
              Text(
                _displayValue(price),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _displayValue(MarketPrice item) {
    final value = item.hasVerifiedTomanValue ? item.priceToman : item.rawPrice;
    if (value == null) {
      return 'ناموجود';
    }
    final unit = item.hasVerifiedTomanValue ? 'تومان' : 'واحد منبع';
    return '${_format(value)} $unit';
  }

  String _format(num value) {
    final negative = value < 0;
    final digits = value.abs().round().toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      final remaining = digits.length - index;
      buffer.write(digits[index]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    return '${negative ? '-' : ''}$buffer';
  }
}
