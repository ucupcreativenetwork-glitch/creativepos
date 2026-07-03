import 'package:flutter_test/flutter_test.dart';
import 'package:creativepos_mobile/features/dashboard/models/dashboard_models.dart';

void main() {
  test('DashboardKpi parses API response', () {
    final kpi = DashboardKpi.fromJson({
      'revenue_today': 1500000,
      'revenue_month': 45000000,
      'transactions_today': 12,
      'transactions_month': 340,
      'new_members_today': 3,
      'active_reservations': 2,
      'active_deliveries': 1,
      'stock_alerts': 5,
    });

    expect(kpi.revenueToday, 1500000);
    expect(kpi.transactionsToday, 12);
    expect(kpi.activeReservations, 2);
    expect(kpi.stockAlerts, 5);
  });
}