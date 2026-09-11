import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/format/number_formatters.dart';
import '../../domain/entities/watch_symbol.dart';
import '../manager/watchlist_cubit.dart';
import '../manager/watchlist_state.dart';

class WatchlistPage extends StatelessWidget {
  const WatchlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: context.read<WatchlistCubit>().load,
      child: BlocBuilder<WatchlistCubit, WatchlistState>(
        builder: (context, state) => switch (state) {
          WatchlistInitial() || WatchlistLoading() => ListView(
              physics: AlwaysScrollableScrollPhysics(),
              children: <Widget>[
                SizedBox(height: 260),
                Center(child: CircularProgressIndicator()),
              ],
            ),
          WatchlistError(:final message) => _WatchlistError(message: message),
          WatchlistLoaded() => _WatchlistLoadedBody(state: state),
        },
      ),
    );
  }
}

class _WatchlistError extends StatelessWidget {
  const _WatchlistError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 140),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: context.read<WatchlistCubit>().load,
            child: const Text('تلاش دوباره'),
          ),
        ],
      );
}

class _WatchlistLoadedBody extends StatelessWidget {
  const _WatchlistLoadedBody({required this.state});

  final WatchlistLoaded state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: <Widget>[
        TextField(
          decoration: InputDecoration(
            hintText: 'جست‌وجوی نماد…',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: state.searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            border: const OutlineInputBorder(),
          ),
          onChanged: context.read<WatchlistCubit>().search,
        ),
        if (state.message != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            state.message!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (state.searchResults.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: <Widget>[
                for (final symbol in state.searchResults.take(10))
                  ListTile(
                    title: Text(symbol.symbolName),
                    subtitle: Text(symbol.title),
                    trailing: const Icon(Icons.add_circle_outline),
                    onTap: () => context.read<WatchlistCubit>().add(symbol),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text('دیده‌بان من', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (state.selected.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'هنوز نمادی اضافه نشده است.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          for (final symbol in state.selected) _WatchSymbolCard(symbol: symbol),
      ],
    );
  }
}

class _WatchSymbolCard extends StatelessWidget {
  const _WatchSymbolCard({required this.symbol});

  final WatchSymbol symbol;

  @override
  Widget build(BuildContext context) {
    final change = symbol.changePercent;
    return Card(
      child: ListTile(
        title: Text(symbol.symbolName),
        subtitle: Text(
          symbol.priceToman == null
              ? symbol.title
              : '${symbol.title}\n${formatToman(symbol.priceToman!)} • تغییر قیمت ${formatPercent(change)}',
        ),
        isThreeLine: symbol.priceToman != null,
        trailing: IconButton(
          tooltip: 'حذف از دیده‌بان',
          onPressed: () =>
              context.read<WatchlistCubit>().remove(symbol.symbolIsin),
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }
}
