import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../services/location_service.dart';
import '../data/delivery_repository.dart';
import '../models/delivery_models.dart';
import '../providers/delivery_providers.dart';
import 'delivery_map_widget.dart';

class DeliveryDetailScreen extends ConsumerWidget {
  const DeliveryDetailScreen({super.key, required this.uuid});

  final String uuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(deliveryDetailProvider(uuid));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Delivery')),
      body: order.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(deliveryDetailProvider(uuid)),
        ),
        data: (o) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(deliveryDetailProvider(uuid)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                o.deliveryNumber,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Chip(label: Text(_statusLabel(o.status))),
              const SizedBox(height: 12),
              _row('Pelanggan', o.customerName),
              _row('Telepon', o.customerPhone),
              if (o.deliveryAddress != null)
                _row('Alamat', o.deliveryAddress!),
              if (o.deliveryCity != null) _row('Kota', o.deliveryCity!),
              if (o.deliveryNotes != null) _row('Catatan', o.deliveryNotes!),
              _row('Total', Formatters.currency(o.totalAmount)),
              const Divider(height: 32),
              Text('Driver', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (o.driver?.user != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.delivery_dining)),
                  title: Text(o.driver!.user!.name),
                  subtitle: Text(
                    [
                      if (o.driver!.vehicleType != null) o.driver!.vehicleType!,
                      if (o.driver!.vehiclePlate != null) o.driver!.vehiclePlate!,
                    ].join(' · '),
                  ),
                )
              else
                const Text('Belum ada driver ditugaskan'),
              if (!['completed', 'cancelled'].contains(o.status)) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _pickDriver(context, ref, o),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: Text(o.driver == null ? 'Tugaskan Driver' : 'Ganti Driver'),
                ),
              ],
              if (o.items.isNotEmpty) ...[
                const Divider(height: 32),
                Text('Item', style: Theme.of(context).textTheme.titleMedium),
                ...o.items.map(
                  (i) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(i.productName),
                    subtitle: Text('x${i.quantity.toStringAsFixed(0)}'),
                    trailing: Text(Formatters.currency(i.subtotal)),
                  ),
                ),
              ],
              if (o.trackingPoints.isNotEmpty) ...[
                const Divider(height: 32),
                Text('Peta Tracking', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                DeliveryMapWidget(trackingPoints: o.trackingPoints),
              ],
              const Divider(height: 32),
              Text('Aksi', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _nextStatuses(o.status).map((status) {
                  return ActionChip(
                    label: Text(_statusLabel(status)),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      _updateStatus(context, ref, status);
                    },
                  );
                }).toList(),
              ),
              if (o.status == 'delivering') ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _sendLocation(context, ref, o.driverId),
                  icon: const Icon(Icons.my_location),
                  label: const Text('Kirim Lokasi GPS'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDriver(
    BuildContext context,
    WidgetRef ref,
    DeliveryOrderModel order,
  ) async {
    try {
      final drivers = await ref.read(deliveryRepositoryProvider).listDrivers(
            outletId: order.outletId,
          );
      if (!context.mounted) return;
      if (drivers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak ada driver tersedia')),
        );
        return;
      }

      final picked = await showModalBottomSheet<DeliveryDriver>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Pilih Driver', style: Theme.of(ctx).textTheme.titleMedium),
              ),
              ...drivers.map(
                (d) => ListTile(
                  leading: const Icon(Icons.two_wheeler),
                  title: Text(d.user?.name ?? 'Driver #${d.id}'),
                  subtitle: Text(d.vehiclePlate ?? d.vehicleType ?? ''),
                  onTap: () => Navigator.pop(ctx, d),
                ),
              ),
            ],
          ),
        ),
      );
      if (picked == null) return;

      await ref.read(deliveryRepositoryProvider).assignDriver(
            uuid,
            driverId: picked.id,
          );
      ref.invalidate(deliveryDetailProvider(uuid));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Driver: ${picked.user?.name ?? picked.id}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  List<String> _nextStatuses(String current) {
    return switch (current) {
      'waiting' => ['processing', 'cancelled'],
      'processing' => ['cooking', 'cancelled'],
      'cooking' => ['ready', 'cancelled'],
      'ready' => ['delivering', 'cancelled'],
      'delivering' => ['completed', 'cancelled'],
      _ => [],
    };
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    String status,
  ) async {
    try {
      await ref.read(deliveryRepositoryProvider).updateStatus(
            uuid,
            status: status,
          );
      ref.invalidate(deliveryDetailProvider(uuid));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status: ${_statusLabel(status)}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _sendLocation(
    BuildContext context,
    WidgetRef ref,
    int? driverId,
  ) async {
    try {
      final pos = await LocationService().getCurrentPosition();
      await ref.read(deliveryRepositoryProvider).recordLocation(
            uuid,
            latitude: pos.latitude,
            longitude: pos.longitude,
            driverId: driverId,
          );
      ref.invalidate(deliveryDetailProvider(uuid));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lokasi GPS terkirim')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label)),
          Expanded(child: Text(value)),
        ],
      ),
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