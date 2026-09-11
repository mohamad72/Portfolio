import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../manager/market_cubit.dart';
import '../manager/market_state.dart';
import '../widgets/market_price_card.dart';

class MarketOverviewPage extends StatelessWidget {
  const MarketOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<MarketCubit>().load(),
      child: BlocBuilder<MarketCubit, MarketState>(
        builder: (BuildContext context, MarketState state) {
          return switch (state) {
            MarketInitial() || MarketLoading() => const _LoadingView(),
            MarketError(:final message) => _ErrorView(message: message),
            MarketLoaded(:final prices) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: <Widget>[
                  Text(
                    'قیمت‌های عمومی بازار',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'داده‌ها از snapshot TGJU می‌آیند. فقط واحدهایی که در منبع تأیید شده‌اند به تومان تبدیل می‌شوند.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  for (final price in prices) ...<Widget>[
                    MarketPriceCard(price: price),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
          };
        },
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: AlwaysScrollableScrollPhysics(),
      children: <Widget>[
        SizedBox(height: 220),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        const SizedBox(height: 120),
        Icon(
          Icons.cloud_off_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => context.read<MarketCubit>().load(),
          icon: const Icon(Icons.refresh),
          label: const Text('تلاش دوباره'),
        ),
      ],
    );
  }
}
