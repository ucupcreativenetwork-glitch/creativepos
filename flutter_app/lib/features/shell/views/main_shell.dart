import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_providers.dart';
import '../../settings/providers/sync_providers.dart';
import '../../../shared/widgets/offline_banner.dart';

class MainShell extends ConsumerWidget {
  const MainShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  int _mapStandaloneIndex(int displayIndex) {
    // Display: 0=POS, 1=Toko, 2=Settings → branches: 1, 2, 4
    return switch (displayIndex) {
      0 => 1,
      1 => 2,
      2 => 4,
      _ => displayIndex,
    };
  }

  int _standaloneDisplayIndex(int branchIndex) {
    return switch (branchIndex) {
      1 => 0,
      2 => 1,
      4 => 2,
      _ => 0,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isStandalone =
        ref.watch(authControllerProvider).status == AuthStatus.standalone;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final pendingSync = ref.watch(pendingSyncCountProvider);
    final syncBadge = pendingSync.maybeWhen(
      data: (c) => c > 0 ? c : null,
      orElse: () => null,
    );

    if (isStandalone) {
      final selected = _standaloneDisplayIndex(navigationShell.currentIndex);

      if (wide) {
        return Scaffold(
          body: Column(
            children: [
              const OfflineBanner(),
              Expanded(
                child: Row(
                  children: [
                    NavigationRail(
                      selectedIndex: selected,
                      onDestinationSelected: (i) => _onTap(_mapStandaloneIndex(i)),
                      labelType: NavigationRailLabelType.all,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.point_of_sale_outlined),
                          selectedIcon: Icon(Icons.point_of_sale),
                          label: Text('Kasir'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.storefront_outlined),
                          selectedIcon: Icon(Icons.storefront),
                          label: Text('Toko'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.settings_outlined),
                          selectedIcon: Icon(Icons.settings),
                          label: Text('Pengaturan'),
                        ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: navigationShell),
                  ],
                ),
              ),
            ],
          ),
        );
      }

      return Scaffold(
        body: Column(
          children: [
            const OfflineBanner(),
            Expanded(child: navigationShell),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selected,
          onDestinationSelected: (i) => _onTap(_mapStandaloneIndex(i)),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined),
              selectedIcon: Icon(Icons.point_of_sale),
              label: 'Kasir',
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: 'Toko',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Pengaturan',
            ),
          ],
        ),
      );
    }

    if (wide) {
      return Scaffold(
        body: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: Row(
                children: [
                  NavigationRail(
                    selectedIndex: navigationShell.currentIndex,
                    onDestinationSelected: _onTap,
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      const NavigationRailDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        selectedIcon: Icon(Icons.dashboard),
                        label: Text('Dashboard'),
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.point_of_sale_outlined),
                        selectedIcon: Icon(Icons.point_of_sale),
                        label: Text('POS'),
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.inventory_2_outlined),
                        selectedIcon: Icon(Icons.inventory_2),
                        label: Text('Inventori'),
                      ),
                      const NavigationRailDestination(
                        icon: Icon(Icons.people_outline),
                        selectedIcon: Icon(Icons.people),
                        label: Text('Member'),
                      ),
                      NavigationRailDestination(
                        icon: syncBadge != null
                            ? Badge(
                                label: Text('$syncBadge'),
                                child: const Icon(Icons.settings_outlined),
                              )
                            : const Icon(Icons.settings_outlined),
                        selectedIcon: syncBadge != null
                            ? Badge(
                                label: Text('$syncBadge'),
                                child: const Icon(Icons.settings),
                              )
                            : const Icon(Icons.settings),
                        label: const Text('Pengaturan'),
                      ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: navigationShell),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'POS',
          ),
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Inventori',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Member',
          ),
          NavigationDestination(
            icon: syncBadge != null
                ? Badge(label: Text('$syncBadge'), child: const Icon(Icons.settings_outlined))
                : const Icon(Icons.settings_outlined),
            selectedIcon: syncBadge != null
                ? Badge(label: Text('$syncBadge'), child: const Icon(Icons.settings))
                : const Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}