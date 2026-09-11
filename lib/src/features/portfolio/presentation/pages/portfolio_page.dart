import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/di/di_config.dart';
import '../../../../shared/format/number_formatters.dart';
import '../../../export/data/markdown_file_writer.dart';
import '../../../export/domain/markdown_portfolio_exporter.dart';
import '../../../market/presentation/widgets/market_summary_strip.dart';
import '../../domain/entities/local_portfolio.dart';
import '../../domain/entities/portfolio_holding.dart';
import '../manager/portfolio_cubit.dart';
import '../manager/portfolio_state.dart';
import '../widgets/allocation_sheet.dart';
import '../widgets/holding_card.dart';

class PortfolioPage extends StatelessWidget {
  const PortfolioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: context.read<PortfolioCubit>().load,
      child: BlocBuilder<PortfolioCubit, PortfolioState>(
        builder: (context, state) => switch (state) {
          PortfolioInitial() || PortfolioLoading() => const _LoadingBody(),
          PortfolioError(:final message) => _ErrorBody(message: message),
          PortfolioLoaded() => _LoadedBody(state: state),
        },
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) => const ListView(
        physics: AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          SizedBox(height: 260),
          Center(child: CircularProgressIndicator()),
        ],
      );
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          const SizedBox(height: 120),
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: context.read<PortfolioCubit>().load,
            child: const Text('تلاش دوباره'),
          ),
        ],
      );
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.state});

  final PortfolioLoaded state;

  @override
  Widget build(BuildContext context) {
    final holdings = state.visibleHoldings;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: <Widget>[
        const MarketSummaryStrip(),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(child: _portfolioSelector(context)),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'ساخت سبد جدید',
              onPressed: () => _showCreatePortfolioDialog(context),
              icon: const Icon(Icons.add),
            ),
            if (_selectedLocalPortfolio != null)
              IconButton.filledTonal(
                tooltip: 'تغییر نام سبد',
                onPressed: () => _showRenamePortfolioDialog(context),
                icon: const Icon(Icons.edit_outlined),
              ),
            if (_selectedLocalPortfolio != null)
              IconButton.filledTonal(
                tooltip: 'حذف سبد',
                onPressed: () => _confirmDeletePortfolio(context),
                icon: const Icon(Icons.delete_outline),
              ),
            IconButton.filledTonal(
              tooltip: 'خروجی Markdown',
              onPressed: () => _export(context, holdings),
              icon: const Icon(Icons.description_outlined),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _summaryCard(context),
        const SizedBox(height: 8),
        if (holdings.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'در این سبد سهمی تخصیص داده نشده است.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          for (final holding in holdings)
            HoldingCard(
              holding: holding,
              valueUnit: state.valueUnit,
              ayarPriceToman: state.snapshot.ayarPriceToman,
              onAllocate: () => _openAllocation(context, holding),
            ),
      ],
    );
  }

  Widget _portfolioSelector(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: state.selectedPortfolioId,
      decoration: const InputDecoration(
        labelText: 'سبد',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: <DropdownMenuItem<String>>[
        const DropdownMenuItem<String>(
          value: PortfolioLoaded.totalPortfolioId,
          child: Text('کل دارایی'),
        ),
        for (final portfolio in state.portfolios)
          DropdownMenuItem<String>(
            value: portfolio.id,
            child: Text(portfolio.name),
          ),
        const DropdownMenuItem<String>(
          value: PortfolioLoaded.unallocatedPortfolioId,
          child: Text('تخصیص‌نیافته'),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          context.read<PortfolioCubit>().selectPortfolio(value);
        }
      },
    );
  }

  Widget _summaryCard(BuildContext context) {
    final totalView =
        state.selectedPortfolioId == PortfolioLoaded.totalPortfolioId;
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
                    state.selectedTitle,
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
                  selected: <PortfolioValueUnit>{state.valueUnit},
                  onSelectionChanged: (selection) => context
                      .read<PortfolioCubit>()
                      .selectValueUnit(selection.first),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _summaryRow('ارزش سهام', _formatValue(state.visibleHoldingsValueToman)),
            if (totalView)
              _summaryRow('قدرت خرید گزارش‌شده', _formatValue(state.snapshot.buyingPowerToman)),
            if (totalView)
              _summaryRow('ارزش کل حساب', 'دادهٔ کافی نداریم'),
            _summaryRow(
              'آخرین همگام‌سازی',
              state.snapshot.syncedAt.toLocal().toString(),
            ),
            const Divider(height: 24),
            const Text(
              'بازده واقعی امروز، هفته و ماه فعلاً «داده کافی نداریم» است؛ گزارش سفارش موجود اجرای مستقل هر معامله را اثبات نمی‌کند.',
            ),
          ],
        ),
      ),
    );
  }


  String _formatValue(num? tomanValue) {
    if (tomanValue == null) {
      return 'ناموجود';
    }
    if (state.valueUnit == PortfolioValueUnit.toman) {
      return formatToman(tomanValue);
    }
    final equivalent = state.snapshot.toAyarUnits(tomanValue);
    if (equivalent == null) {
      return 'ناموجود';
    }
    return '${formatNumber(equivalent, decimals: 4)} واحد عیار';
  }

  Widget _summaryRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(label)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Future<void> _openAllocation(
    BuildContext context,
    PortfolioHolding holding,
  ) async {
    final current = <String, num>{
      for (final portfolio in state.portfolios)
        portfolio.id: state.allocatedQuantity(holding.symbolIsin, portfolio.id),
    };
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AllocationSheet(
        holding: state.snapshot.holdings.firstWhere(
          (item) => item.symbolIsin == holding.symbolIsin,
        ),
        portfolios: state.portfolios,
        currentAllocations: current,
        onSave: (allocations) => context.read<PortfolioCubit>().saveAllocations(
              symbolIsin: holding.symbolIsin,
              totalQuantity: state.snapshot.holdings
                  .firstWhere((item) => item.symbolIsin == holding.symbolIsin)
                  .quantity,
              allocations: allocations,
            ),
      ),
    );
  }


  LocalPortfolio? get _selectedLocalPortfolio {
    if (state.selectedPortfolioId == PortfolioLoaded.totalPortfolioId ||
        state.selectedPortfolioId == PortfolioLoaded.unallocatedPortfolioId) {
      return null;
    }
    for (final portfolio in state.portfolios) {
      if (portfolio.id == state.selectedPortfolioId) {
        return portfolio;
      }
    }
    return null;
  }

  Future<void> _showRenamePortfolioDialog(BuildContext context) async {
    final portfolio = _selectedLocalPortfolio;
    if (portfolio == null) {
      return;
    }
    final controller = TextEditingController(text: portfolio.name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تغییر نام سبد'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'نام سبد'),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.trim().isNotEmpty && context.mounted) {
      await context.read<PortfolioCubit>().renamePortfolio(portfolio.id, name);
    }
  }

  Future<void> _confirmDeletePortfolio(BuildContext context) async {
    final portfolio = _selectedLocalPortfolio;
    if (portfolio == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف سبد'),
        content: Text('سبد «${portfolio.name}» و تخصیص‌های آن حذف شود؟'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<PortfolioCubit>().deletePortfolio(portfolio.id);
    }
  }

  Future<void> _showCreatePortfolioDialog(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('سبد جدید'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'نام سبد'),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('ساخت'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && context.mounted) {
      await context.read<PortfolioCubit>().createPortfolio(name);
    }
  }

  Future<void> _export(
    BuildContext context,
    List<PortfolioHolding> holdings,
  ) async {
    final exporter = getIt<MarkdownPortfolioExporter>();
    final writer = getIt<MarkdownFileWriter>();
    final markdown = exporter.export(
      title: state.selectedTitle,
      snapshot: state.snapshot,
      holdings: holdings,
    );
    await Clipboard.setData(ClipboardData(text: markdown));
    try {
      final path = await writer.write(content: markdown);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Markdown کپی و در $path ذخیره شد.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Markdown کپی شد؛ ذخیرهٔ فایل ناموفق بود.')),
        );
      }
    }
  }
}
