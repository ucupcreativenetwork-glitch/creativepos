class PosTotals {
  const PosTotals({
    required this.subtotal,
    required this.discountTotal,
    required this.taxTotal,
    required this.serviceCharge,
    required this.grandTotal,
  });

  final double subtotal;
  final double discountTotal;
  final double taxTotal;
  final double serviceCharge;
  final double grandTotal;
}

PosTotals calculatePosTotals({
  required double subtotal,
  double discountTotal = 0,
  double taxRate = 0,
  double serviceRate = 0,
}) {
  final taxableBase = (subtotal - discountTotal).clamp(0, double.infinity);
  final taxTotal = (taxableBase * taxRate / 100 * 100).round() / 100;
  final serviceCharge = (taxableBase * serviceRate / 100 * 100).round() / 100;
  final grandTotal =
      double.parse((taxableBase + taxTotal + serviceCharge).toStringAsFixed(2));

  return PosTotals(
    subtotal: subtotal,
    discountTotal: discountTotal,
    taxTotal: taxTotal,
    serviceCharge: serviceCharge,
    grandTotal: grandTotal,
  );
}