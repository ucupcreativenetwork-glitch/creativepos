import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_message.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/outlet_utils.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/interactive_card.dart';
import '../../../shared/widgets/load_more_list_view.dart';
import '../../../shared/widgets/outlet_dropdown.dart';
import '../../pos/providers/pos_providers.dart';
import '../data/delivery_repository.dart';
import '../models/delivery_models.dart';
import 'delivery_detail_screen.dart';

class DeliveryTab extends ConsumerStatefulWidget {
  const DeliveryTab({super.key});

  @override
  ConsumerState<DeliveryTab> createState() => _DeliveryTabState();
}

class _DeliveryTabState extends ConsumerState<DeliveryTab> {
  int? _outletId;
  String? _statusFilter;
  var _listKey = 0;

  void _bumpList() => setState(() => _listKey++);

  Future<({List<DeliveryOrderModel> items, int lastPage})> _loadPage(
    int page,
  ) async {
    final result = await ref.read(deliveryRepositoryProvider).listOrders(
          outletId: _outletId,
          status: _statusFilter,
          page: page,
        );
    return (items: result.items, lastPage: result.meta.lastPage);
  }

  @override
  Widget build(BuildContext context) {
    final outletsAsync = ref.watch(settingsOutletsProvider);

    return outletsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        message: friendlyError(e),
        onRetry: () => ref.invalidate(settingsOutletsProvider),
      ),
      data: (outlets) {
        final outletList = outlets.cast<Map<String, dynamic>>().toList();
        final resolvedOutletId = resolveOutletId(outletList, _outletId);
        if (resolvedOutletId != null && resolvedOutletId != _outletId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _outletId = resolvedOutletId);
              _bumpList();
            }
          });
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: OutletDropdown(
                outlets: outletList,
                value: resolvedOutletId,
                onChanged: (v) {
                  setState(() => _outletId = v);
                  _bumpList();
                },
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                children: [
                  FilterChip(
                    label: const Text('Semua'),
                    selected: _statusFilter == null,
                    onSelected: (_) {
                      setState(() => _statusFilter = null);
                      _bumpList();
                    },
                  ),
                  ...[
                    'waiting',
                    'processing',
                    'cooking',
                    'ready',
                    'delivering',
                    'completed',
                    'cancelled',
                  ].map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        label: Text(_statusLabel(s)),
                        selected: _statusFilter == s,
                        onSelected: (_) {
                          setState(() => _statusFilter = s);
                          _bumpList();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LoadMoreListView<DeliveryOrderModel>(
                key: ValueKey('delivery-$_listKey-$_outletId-$_statusFilter'),
                loader: _loadPage,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                empty: const EmptyState(
                  icon: Icons.delivery_dining_outlined,
                  title: 'Belum ada order delivery',
                  subtitle: 'Order pengiriman dari web akan muncul di sini',
                ),
                itemBuilder: (context, order, index) {
                  return InteractiveCard(
                    margin: EdgeInsets.zero,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              DeliveryDetailScreen(uuid: order.uuid),
                        ),
                      );
                    },
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.posGreenLight,
                        child: Icon(
                          Icons.delivery_dining,
                          color: AppColors.posGreen,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        order.deliveryNumber,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${order.customerName} · ${order.customerPhone}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            Formatters.currency(order.totalAmount),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Chip(
                            label: Text(
                              _statusLabel(order.status),
                              style: const TextStyle(fontSize: 10),
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

String _statusLabel(String status) {
  return switch (status) {
    'waiting' => 'Menunggu',
    'processing' => 'Diproses',
    'cooking' => 'Dimasak',
    'ready' => 'Siap',
    'delivering' => 'Dikirim',
    'completed' => 'Selesai',
    'cancelled' => 'Dibatalkan',
    _ => status,
  };
}