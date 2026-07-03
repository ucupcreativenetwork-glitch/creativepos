import 'package:flutter/material.dart';

import '../../core/utils/outlet_utils.dart';

class OutletDropdown extends StatelessWidget {
  const OutletDropdown({
    super.key,
    required this.outlets,
    required this.value,
    required this.onChanged,
    this.label = 'Outlet',
  });

  final List<Map<String, dynamic>> outlets;
  final int? value;
  final ValueChanged<int?> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveOutletId(outlets, value);

    return DropdownButtonFormField<int?>(
      key: ValueKey(resolved),
      initialValue: resolved,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
      ),
      items: outlets
          .map(
            (o) => DropdownMenuItem<int?>(
              value: parseOutletId(o['id']),
              child: Text(o['name'] as String? ?? ''),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}