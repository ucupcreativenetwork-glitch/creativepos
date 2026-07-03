import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/kpi_card.dart';
import '../../auth/providers/auth_providers.dart';
import '../../notifications/providers/notifications_providers.dart';
import '../../settings/providers/feature_providers.dart';
import '../../settings/providers/sync_providers.dart';
import '../models/dashboard_models.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardDataProvider);
    final session = ref.watch(authControllerProvider).session;
    final outletId = ref.watch(selectedOutletIdProvider);
    final unread = ref.watch(unreadNotificationsProvider);
    final pendingSync = ref.watch(pendingSyncCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard'),
            if (session?.tenant != null)
              Text(
                session!.tenant!.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
          ],
        ),
        actions: [
          dashboard.maybeWhen(
            data: (data) {
              if (data.outlets.isEmpty) return const SizedBox.shrink();
              final validOutletId = outletId != null &&
                      data.outlets.any((o) => o.id == outletId)
                  ? outletId
                  : null;
              return DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  key: ValueKey(validOutletId),
                  value: validOutletId,
                  hint: const Text('Semua Outlet'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Semua Outlet'),
                    ),
                    ...data.outlets.map(
                      (o) => DropdownMenuItem<int?>(
                        value: o.id,
                        child: Text(o.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    ref.read(selectedOutletIdProvider.notifier).state = value;
                    ref.invalidate(dashboardDataProvider);
                  },
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          pendingSync.when(
            data: (count) {
              if (count <= 0) return const SizedBox.shrink();
              return IconButton(
                onPressed: () => context.push('/sync'),
                icon: Badge(
                  label: Text('$count'),
                  child: const Icon(Icons.cloud_off),
                ),
                tooltip: '$count transaksi offline',
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          unread.when(
            data: (count) => IconButton(
              onPressed: () => context.push(operationsPath('notifications')),
              icon: Badge(
                isLabelVisible: count > 0,
                label: Text('$count'),
                child: const Icon(Icons.notifications_outlined),
              ),
            ),
            loading: () => IconButton(
              onPressed: () => context.push(operationsPath('notifications')),
              icon: const Icon(Icons.notifications_outlined),
            ),
            error: (_, __) => IconButton(
              onPressed: () => context.push(operationsPath('notifications')),
              icon: const Icon(Icons.notifications_outlined),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: dashboard.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(dashboardDataProvider),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardDataProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GridView.count(
                crossAxisCount: MediaQuery.sizeOf(context).width > 600 ? 3 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  KpiCard(
                    title: 'Omzet Hari Ini',
                    value: Formatters.currency(data.kpi.revenueToday),
                    icon: Icons.payments_outlined,
                    onTap: () => context.go('/pos'),
                  ),
                  KpiCard(
                    title: 'Omzet Bulan Ini',
                    value: Formatters.currency(data.kpi.revenueMonth),
                    icon: Icons.calendar_month_outlined,
                    color: AppColors.success,
                    onTap: () => context.go('/pos'),
                  ),
                  KpiCard(
                    title: 'Penjualan Hari Ini',
                    value: '${data.kpi.transactionsToday}',
                    subtitle: 'Bulan: ${data.kpi.transactionsMonth}',
                    icon: Icons.receipt_long_outlined,
                    onTap: () => context.go('/pos'),
                  ),
                  KpiCard(
                    title: 'Member Baru',
                    value: '${data.kpi.newMembersToday}',
                    icon: Icons.people_outline,
                    onTap: () => context.go('/members'),
                  ),
                  KpiCard(
                    title: 'Reservasi Aktif',
                    value: '${data.kpi.activeReservations}',
                    icon: Icons.event_available_outlined,
                    color: AppColors.warning,
                    onTap: () => context.go('/members'),
                  ),
                  KpiCard(
                    title: 'Delivery Aktif',
                    value: '${data.kpi.activeDeliveries}',
                    icon: Icons.delivery_dining_outlined,
                    onTap: () => context.push(operationsPath('delivery')),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _OperationsSection(
                activeDeliveries: data.kpi.activeDeliveries,
                activeReservations: data.kpi.activeReservations,
              ),
              const SizedBox(height: 16),
              _SalesChartCard(points: data.salesChart),
              const SizedBox(height: 16),
              _TopProductsCard(products: data.topProducts),
              const SizedBox(height: 16),
              _LiveFeedCard(items: data.liveFeed),
            ],
          ),
        ),
      ),
    );
  }
}

class _OperationsSection extends ConsumerWidget {
  const _OperationsSection({
    required this.activeDeliveries,
    required this.activeReservations,
  });

  final int activeDeliveries;
  final int activeReservations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ref.watch(tenantFeaturesProvider);

    return features.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (f) {
        final tiles = <Widget>[
          if (f.hasDelivery)
            Expanded(
              child: _OpsTile(
                icon: Icons.delivery_dining_outlined,
                label: 'Delivery',
                badge: activeDeliveries > 0 ? '$activeDeliveries' : null,
                onTap: () => context.push(operationsPath('delivery')),
              ),
            ),
          if (f.hasCrm) ...[
            if (f.hasDelivery) const SizedBox(width: 8),
            Expanded(
              child: _OpsTile(
                icon: Icons.support_agent_outlined,
                label: 'CRM',
                onTap: () => context.push(operationsPath('crm')),
              ),
            ),
          ],
          if (f.hasDelivery || f.hasCrm) const SizedBox(width: 8),
          Expanded(
            child: _OpsTile(
              icon: Icons.notifications_outlined,
              label: 'Notifikasi',
              onTap: () => context.push(operationsPath('notifications')),
            ),
          ),
        ];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Operasional',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (f.hasReservation && activeReservations > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$activeReservations reservasi aktif hari ini',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(children: tiles),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OpsTile extends StatelessWidget {
  const _OpsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Badge(
                isLabelVisible: badge != null,
                label: Text(badge ?? ''),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SalesChartCard extends StatelessWidget {
  const _SalesChartCard({required this.points});

  final List<SalesChartPoint> points;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grafik Penjualan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: points.isEmpty
                  ? const EmptyState(
                      icon: Icons.show_chart,
                      title: 'Belum ada data penjualan',
                      subtitle: 'Grafik akan muncul setelah transaksi pertama',
                    )
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(),
                          topTitles: const AxisTitles(),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: points.length <= 14,
                              reservedSize: 22,
                              getTitlesWidget: (value, meta) {
                                final i = value.toInt();
                                if (i < 0 || i >= points.length) {
                                  return const SizedBox.shrink();
                                }
                                final label = points[i].label;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    label.length > 5 ? label.substring(5) : label,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: true,
                            color: AppColors.primary,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                            spots: [
                              for (var i = 0; i < points.length; i++)
                                FlSpot(i.toDouble(), points[i].revenue),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  const _TopProductsCard({required this.products});

  final List<TopProduct> products;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Produk Terlaris',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            if (products.isEmpty)
              const EmptyState(
                icon: Icons.trending_up,
                title: 'Belum ada produk terlaris',
                subtitle: 'Data muncul setelah ada penjualan',
              )
            else
              ...products.map(
                (product) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(product.productName),
                  subtitle: Text('Qty: ${product.totalQty}'),
                  trailing: Text(
                    Formatters.currency(product.totalRevenue),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LiveFeedCard extends StatelessWidget {
  const _LiveFeedCard({required this.items});

  final List<LiveFeedItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Penjualan Terbaru',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Belum ada transaksi',
                subtitle: 'Penjualan terbaru akan tampil di sini',
              )
            else
              ...items.map(
                (feed) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    child: Icon(Icons.point_of_sale, size: 18),
                  ),
                  title: Text(feed.transactionNumber),
                  subtitle: Text('${feed.outlet ?? '-'} · ${feed.cashier ?? '-'}'),
                  trailing: Text(
                    Formatters.currency(feed.grandTotal),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}