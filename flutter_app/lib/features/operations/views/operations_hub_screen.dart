import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/feature_disabled_view.dart';
import '../../crm/views/crm_tab.dart';
import '../../delivery/views/delivery_tab.dart';
import '../../notifications/providers/notifications_providers.dart';
import '../../notifications/views/notifications_tab.dart';
import '../../settings/providers/feature_providers.dart';

class OperationsHubScreen extends ConsumerStatefulWidget {
  const OperationsHubScreen({
    super.key,
    this.initialTab = 0,
    this.initialTabKey,
  });

  final int initialTab;
  final String? initialTabKey;

  @override
  ConsumerState<OperationsHubScreen> createState() =>
      _OperationsHubScreenState();
}

class _OperationsHubScreenState extends ConsumerState<OperationsHubScreen>
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
    final unread = ref.watch(unreadNotificationsProvider);

    return features.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Operasional')),
        body: Center(child: Text(e.toString())),
      ),
      data: (f) {
        final tabs = <_OpsTab>[
          if (f.hasDelivery)
            const _OpsTab(label: 'Delivery', icon: Icons.delivery_dining_outlined, child: DeliveryTab()),
          if (f.hasCrm)
            const _OpsTab(label: 'CRM', icon: Icons.support_agent_outlined, child: CrmTab()),
          const _OpsTab(
            label: 'Notifikasi',
            icon: Icons.notifications_outlined,
            child: NotificationsTab(),
          ),
        ];

        if (tabs.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Operasional')),
            body: FeatureDisabledView(
              title: 'Modul operasional tidak tersedia',
              subtitle: f.packageName != null
                  ? 'Paket ${f.packageName} tidak mencakup delivery & CRM'
                  : 'Hubungi admin untuk upgrade paket',
            ),
          );
        }

        var initial = widget.initialTab;
        if (widget.initialTabKey != null) {
          final resolved = resolveOperationsTab(f, widget.initialTabKey!);
          if (resolved >= 0) initial = resolved;
        }
        initial = initial.clamp(0, tabs.length - 1);
        if (_tabs == null || _tabs!.length != tabs.length) {
          _tabs?.dispose();
          _tabs = TabController(length: tabs.length, vsync: this, initialIndex: initial);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Operasional'),
            bottom: TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                for (var i = 0; i < tabs.length; i++)
                  Tab(
                    icon: tabs[i].label == 'Notifikasi'
                        ? unread.when(
                            data: (count) => Badge(
                              isLabelVisible: count > 0,
                              label: Text('$count'),
                              child: Icon(tabs[i].icon),
                            ),
                            loading: () => Icon(tabs[i].icon),
                            error: (_, __) => Icon(tabs[i].icon),
                          )
                        : Icon(tabs[i].icon),
                    text: tabs[i].label,
                  ),
              ],
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

class _OpsTab {
  const _OpsTab({
    required this.label,
    required this.icon,
    required this.child,
  });

  final String label;
  final IconData icon;
  final Widget child;
}