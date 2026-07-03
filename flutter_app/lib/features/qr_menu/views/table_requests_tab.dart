import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/outlet_utils.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/interactive_card.dart';
import '../../../shared/widgets/load_more_list_view.dart';
import '../../../shared/widgets/outlet_dropdown.dart';
import '../../notifications/providers/notifications_providers.dart';
import '../../pos/providers/pos_providers.dart';
import '../data/table_requests_repository.dart';
import '../models/table_request_models.dart';

class TableRequestsTab extends ConsumerStatefulWidget {
  const TableRequestsTab({super.key});

  @override
  ConsumerState<TableRequestsTab> createState() => _TableRequestsTabState();
}

class _TableRequestsTabState extends ConsumerState<TableRequestsTab> {
  int? _outletId;
  var _pendingOnly = true;
  var _listKey = 0;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() => _listKey++);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<({List<TableServiceRequestModel> items, int lastPage})> _loadPage(
    int page,
  ) async {
    return ref.read(tableRequestsRepositoryProvider).list(
          outletId: _outletId,
          status: _pendingOnly ? 'pending' : null,
          page: page,
        );
  }

  Future<void> _acknowledge(TableServiceRequestModel request) async {
    try {
      await ref.read(tableRequestsRepositoryProvider).acknowledge(request.uuid);
      HapticFeedback.mediumImpact();
      setState(() => _listKey++);
      ref.invalidate(unreadNotificationsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${request.tableLabel} — ditangani')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final outletsAsync = ref.watch(settingsOutletsProvider);

    return outletsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (outlets) {
        final outletList = outlets.cast<Map<String, dynamic>>().toList();
        final resolvedOutletId = resolveOutletId(outletList, _outletId);
        if (resolvedOutletId != null && resolvedOutletId != _outletId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _outletId = resolvedOutletId);
              _listKey++;
            }
          });
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: OutletDropdown(
                      outlets: outletList,
                      value: resolvedOutletId,
                      onChanged: (v) {
                        setState(() {
                          _outletId = v;
                          _listKey++;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Pending'),
                    selected: _pendingOnly,
                    onSelected: (v) {
                      setState(() {
                        _pendingOnly = v;
                        _listKey++;
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: LoadMoreListView<TableServiceRequestModel>(
                key: ValueKey('table-req-$_listKey-$_outletId-$_pendingOnly'),
                loader: _loadPage,
                padding: const EdgeInsets.all(12),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                empty: const EmptyState(
                  icon: Icons.room_service_outlined,
                  title: 'Tidak ada permintaan meja',
                  subtitle: 'Panggilan pelayan & tagihan dari QR meja tampil di sini',
                ),
                itemBuilder: (context, request, index) {
                  final isPending = request.status == 'pending';
                  return InteractiveCard(
                    margin: EdgeInsets.zero,
                    color: isPending
                        ? AppColors.posGreenLight.withValues(alpha: 0.35)
                        : null,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isPending
                            ? AppColors.posGreen
                            : Colors.grey.shade400,
                        child: Icon(
                          request.type == 'request_bill'
                              ? Icons.receipt_long
                              : Icons.room_service,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        request.typeLabel,
                        style: TextStyle(
                          fontWeight:
                              isPending ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        [
                          request.tableLabel,
                          if (request.outletName != null) request.outletName!,
                          if (request.createdAt != null)
                            request.createdAt!.substring(0, 16),
                        ].join(' · '),
                      ),
                      trailing: isPending
                          ? FilledButton(
                              onPressed: () => _acknowledge(request),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.posGreen,
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text('Selesai'),
                            )
                          : Chip(
                              label: const Text('OK'),
                              visualDensity: VisualDensity.compact,
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