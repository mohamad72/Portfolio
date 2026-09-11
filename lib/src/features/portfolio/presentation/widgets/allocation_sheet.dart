import 'package:flutter/material.dart';

import '../../../../shared/format/number_formatters.dart';
import '../../domain/entities/local_portfolio.dart';
import '../../domain/entities/portfolio_holding.dart';

typedef SaveAllocationCallback = Future<String?> Function(
  Map<String, num> allocations,
);

class AllocationSheet extends StatefulWidget {
  const AllocationSheet({
    required this.holding,
    required this.portfolios,
    required this.currentAllocations,
    required this.onSave,
    super.key,
  });

  final PortfolioHolding holding;
  final List<LocalPortfolio> portfolios;
  final Map<String, num> currentAllocations;
  final SaveAllocationCallback onSave;

  @override
  State<AllocationSheet> createState() => _AllocationSheetState();
}

class _AllocationSheetState extends State<AllocationSheet> {
  late final Map<String, TextEditingController> _controllers;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controllers = <String, TextEditingController>{
      for (final portfolio in widget.portfolios)
        portfolio.id: TextEditingController(
          text: _initialValue(widget.currentAllocations[portfolio.id] ?? 0),
        ),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'تقسیم ${widget.holding.symbolName}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text('موجودی کل: ${formatNumber(widget.holding.quantity)} سهم'),
            const SizedBox(height: 16),
            for (final portfolio in widget.portfolios) ...<Widget>[
              TextField(
                controller: _controllers[portfolio.id],
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: portfolio.name,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (widget.portfolios.length == 2)
              OutlinedButton.icon(
                onPressed: _splitHalf,
                icon: const Icon(Icons.balance_outlined),
                label: const Text('تقسیم ۵۰/۵۰'),
              ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('ذخیره تخصیص'),
            ),
          ],
        ),
      ),
    );
  }

  void _splitHalf() {
    final first = widget.portfolios.first;
    final second = widget.portfolios[1];
    final total = widget.holding.quantity;
    final firstValue = total is int ? total ~/ 2 : total / 2;
    final secondValue = total - firstValue;
    _controllers[first.id]!.text = _initialValue(firstValue);
    _controllers[second.id]!.text = _initialValue(secondValue);
  }

  Future<void> _save() async {
    final values = <String, num>{};
    for (final entry in _controllers.entries) {
      final text = entry.value.text.trim().replaceAll(',', '');
      final value = text.isEmpty ? 0 : num.tryParse(text);
      if (value == null) {
        setState(() => _error = 'یکی از تعدادها معتبر نیست.');
        return;
      }
      values[entry.key] = value;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSave(values);
    if (!mounted) {
      return;
    }
    if (error == null) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _saving = false;
      _error = error;
    });
  }

  String _initialValue(num value) =>
      value % 1 == 0 ? value.toInt().toString() : value.toString();
}
