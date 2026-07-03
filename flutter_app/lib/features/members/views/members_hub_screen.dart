import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/feature_disabled_view.dart';
import '../../qr_menu/views/qr_menu_tab.dart';
import '../../qr_menu/views/table_requests_tab.dart';
import '../../reservations/views/reservations_tab.dart';
import '../../settings/providers/feature_providers.dart';
import 'members_tab.dart';

class MembersHubScreen extends ConsumerStatefulWidget {
  const MembersHubScreen({super.key});

  @override
  ConsumerState<MembersHubScreen> createState() => _MembersHubScreenState();
}

class _MembersHubScreenState extends ConsumerState<MembersHubScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabs;

  @override
  void dispose() {
    _tabs?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final features = ref.watch(tenantFeaturesProvider);

    return features.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Member & Layanan')),
        body: Center(child: Text(e.toString())),
      ),
      data: (f) {
        final tabs = <_HubTab>[
          if (f.hasLoyalty)
            const _HubTab(label: 'Member', child: MembersTab()),
          if (f.hasQrMenu) ...[
            const _HubTab(label: 'QR Menu', child: QrMenuTab()),
            const _HubTab(label: 'Permintaan Meja', child: TableRequestsTab()),
          ],
          if (f.hasReservation)
            const _HubTab(label: 'Reservasi', child: ReservationsTab()),
        ];

        if (tabs.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Member & Layanan')),
            body: const FeatureDisabledView(
              title: 'Modul member tidak tersedia',
              subtitle: 'Upgrade paket untuk mengaktifkan loyalty & layanan',
            ),
          );
        }

        if (_tabs == null || _tabs!.length != tabs.length) {
          _tabs?.dispose();
          _tabs = TabController(length: tabs.length, vsync: this);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Member & Layanan'),
            bottom: TabBar(
              controller: _tabs,
              tabs: [for (final t in tabs) Tab(text: t.label)],
            ),
          ),
          body: TabBarView(
            controller: _tabs,
            children: [for (final t in tabs) t.child],
          ),
        );
      },
    );
  }
}

class _HubTab {
  const _HubTab({required this.label, required this.child});

  final String label;
  final Widget child;
}