import 'package:flutter/material.dart';

import '../models/pos_models.dart';

class ModifierSheet extends StatefulWidget {
  const ModifierSheet({
    super.key,
    required this.product,
    required this.onConfirm,
  });

  final PosProduct product;
  final void Function(List<SelectedModifier> modifiers) onConfirm;

  @override
  State<ModifierSheet> createState() => _ModifierSheetState();
}

class _ModifierSheetState extends State<ModifierSheet> {
  final Map<int, Set<int>> _selected = {};

  List<SelectedModifier> _buildSelection() {
    final result = <SelectedModifier>[];
    for (final group in widget.product.modifierGroups) {
      final ids = _selected[group.id] ?? {};
      for (final modifier in group.modifiers) {
        if (ids.contains(modifier.id)) {
          result.add(
            SelectedModifier(
              modifierId: modifier.id,
              groupId: group.id,
              groupName: group.name,
              name: modifier.name,
              priceAdjustment: modifier.priceAdjustment,
            ),
          );
        }
      }
    }
    return result;
  }

  bool _validate() {
    for (final group in widget.product.modifierGroups) {
      final count = (_selected[group.id] ?? {}).length;
      if (group.isRequired && count < group.minSelect) return false;
      if (count > group.maxSelect) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.product.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...widget.product.modifierGroups.map((group) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: group.modifiers.map((modifier) {
                    final selected =
                        _selected[group.id]?.contains(modifier.id) ?? false;
                    return FilterChip(
                      label: Text(
                        '${modifier.name} (+${modifier.priceAdjustment.toStringAsFixed(0)})',
                      ),
                      selected: selected,
                      onSelected: (value) {
                        setState(() {
                          final set = _selected.putIfAbsent(
                            group.id,
                            () => <int>{},
                          );
                          if (group.maxSelect <= 1) {
                            set.clear();
                          }
                          if (value) {
                            if (set.length < group.maxSelect) {
                              set.add(modifier.id);
                            }
                          } else {
                            set.remove(modifier.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
            );
          }),
          FilledButton(
            onPressed: _validate()
                ? () => widget.onConfirm(_buildSelection())
                : null,
            child: const Text('Tambah ke Keranjang'),
          ),
        ],
      ),
    );
  }
}