import 'json_utils.dart';

int? parseOutletId(dynamic value) => parseJsonIntOrNull(value);

int? resolveOutletId(List<Map<String, dynamic>> outlets, int? preferred) {
  if (outlets.isEmpty) return null;

  final ids = outlets
      .map((o) => parseOutletId(o['id']))
      .whereType<int>()
      .toSet();

  if (preferred != null && ids.contains(preferred)) return preferred;

  final defaultOutlet = outlets.firstWhere(
    (o) => o['is_default'] == true,
    orElse: () => outlets.first,
  );

  return parseOutletId(defaultOutlet['id']);
}

Map<String, dynamic>? findOutletById(
  List<Map<String, dynamic>> outlets,
  int? outletId,
) {
  if (outletId == null) return null;
  for (final outlet in outlets) {
    if (parseOutletId(outlet['id']) == outletId) return outlet;
  }
  return null;
}