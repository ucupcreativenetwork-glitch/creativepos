import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';

class CashKeypad extends StatelessWidget {
  const CashKeypad({
    super.key,
    required this.total,
    required this.received,
    required this.onChanged,
  });

  final double total;
  final double received;
  final ValueChanged<double> onChanged;

  void _tap(String key) {
    final current = received.toStringAsFixed(0);
    if (key == 'C') {
      onChanged(0);
      return;
    }
    if (key == '⌫') {
      if (current.length <= 1) {
        onChanged(0);
        return;
      }
      onChanged(double.tryParse(current.substring(0, current.length - 1)) ?? 0);
      return;
    }
    final next = current == '0' ? key : '$current$key';
    onChanged(double.tryParse(next) ?? received);
  }

  void _quickAdd(double amount) => onChanged(received + amount);

  @override
  Widget build(BuildContext context) {
    final change = received - total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Diterima'),
                  Text(
                    Formatters.currency(received),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kembalian'),
                  Text(
                    Formatters.currency(change >= 0 ? change : 0),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: change >= 0 ? Colors.green.shade700 : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final amount in [50000.0, 100000.0, 200000.0])
              ActionChip(
                label: Text('+${Formatters.currency(amount)}'),
                onPressed: () => _quickAdd(amount),
              ),
            ActionChip(
              label: const Text('Pas'),
              onPressed: () => onChanged(total),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.6,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final key in ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'C', '0', '⌫'])
              OutlinedButton(
                onPressed: () => _tap(key),
                child: Text(key, style: const TextStyle(fontSize: 18)),
              ),
          ],
        ),
      ],
    );
  }
}