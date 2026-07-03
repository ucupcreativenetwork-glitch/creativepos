import '../../../core/utils/json_utils.dart';

class DashboardKpi {
  const DashboardKpi({
    required this.revenueToday,
    required this.revenueMonth,
    required this.transactionsToday,
    required this.transactionsMonth,
    required this.newMembersToday,
    required this.activeReservations,
    required this.activeDeliveries,
    required this.stockAlerts,
  });

  final double revenueToday;
  final double revenueMonth;
  final int transactionsToday;
  final int transactionsMonth;
  final int newMembersToday;
  final int activeReservations;
  final int activeDeliveries;
  final int stockAlerts;

  factory DashboardKpi.fromJson(Map<String, dynamic> json) {
    return DashboardKpi(
      revenueToday: parseJsonDouble(json['revenue_today']),
      revenueMonth: parseJsonDouble(json['revenue_month']),
      transactionsToday: parseJsonInt(json['transactions_today']),
      transactionsMonth: parseJsonInt(json['transactions_month']),
      newMembersToday: parseJsonInt(json['new_members_today']),
      activeReservations: parseJsonInt(json['active_reservations']),
      activeDeliveries: parseJsonInt(json['active_deliveries']),
      stockAlerts: parseJsonInt(json['stock_alerts']),
    );
  }
}

class SalesChartPoint {
  const SalesChartPoint({
    required this.label,
    required this.revenue,
    required this.transactions,
  });

  final String label;
  final double revenue;
  final int transactions;

  factory SalesChartPoint.fromJson(Map<String, dynamic> json) {
    return SalesChartPoint(
      label: json['label'] as String? ?? '',
      revenue: parseJsonDouble(json['revenue']),
      transactions: parseJsonInt(json['transactions']),
    );
  }
}

class TopProduct {
  const TopProduct({
    required this.productId,
    required this.productName,
    required this.totalQty,
    required this.totalRevenue,
  });

  final int productId;
  final String productName;
  final double totalQty;
  final double totalRevenue;

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      productId: parseJsonInt(json['product_id']),
      productName: parseJsonString(json['product_name'], fallback: '-'),
      totalQty: parseJsonDouble(json['total_qty']),
      totalRevenue: parseJsonDouble(json['total_revenue']),
    );
  }
}

class LiveFeedItem {
  const LiveFeedItem({
    required this.transactionNumber,
    required this.grandTotal,
    this.outlet,
    this.cashier,
    this.completedAt,
  });

  final String transactionNumber;
  final double grandTotal;
  final String? outlet;
  final String? cashier;
  final String? completedAt;

  factory LiveFeedItem.fromJson(Map<String, dynamic> json) {
    return LiveFeedItem(
      transactionNumber: json['transaction_number'] as String? ?? '-',
      grandTotal: parseJsonDouble(json['grand_total']),
      outlet: json['outlet'] as String?,
      cashier: json['cashier'] as String?,
      completedAt: json['completed_at'] as String?,
    );
  }
}

class OutletOption {
  const OutletOption({
    required this.id,
    required this.name,
    required this.code,
  });

  final int id;
  final String name;
  final String code;

  factory OutletOption.fromJson(Map<String, dynamic> json) {
    return OutletOption(
      id: parseJsonInt(json['id']),
      name: parseJsonString(json['name']),
      code: parseJsonString(json['code']),
    );
  }
}