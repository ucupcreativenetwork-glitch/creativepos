import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/dashboard_repository.dart';
import '../models/dashboard_models.dart';

class DashboardData {
  const DashboardData({
    required this.kpi,
    required this.salesChart,
    required this.topProducts,
    required this.liveFeed,
    required this.outlets,
  });

  final DashboardKpi kpi;
  final List<SalesChartPoint> salesChart;
  final List<TopProduct> topProducts;
  final List<LiveFeedItem> liveFeed;
  final List<OutletOption> outlets;
}

final dashboardDataProvider = FutureProvider.autoDispose<DashboardData>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  final outletId = ref.watch(selectedOutletIdProvider);

  final results = await Future.wait([
    repo.getKpi(outletId: outletId),
    repo.getSalesChart(outletId: outletId),
    repo.getTopProducts(outletId: outletId),
    repo.getLiveFeed(outletId: outletId),
    repo.getOutlets(),
  ]);

  return DashboardData(
    kpi: results[0] as DashboardKpi,
    salesChart: results[1] as List<SalesChartPoint>,
    topProducts: results[2] as List<TopProduct>,
    liveFeed: results[3] as List<LiveFeedItem>,
    outlets: results[4] as List<OutletOption>,
  );
});