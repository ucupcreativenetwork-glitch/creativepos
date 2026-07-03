import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/views/change_password_screen.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/server_setup_screen.dart';
import '../../features/auth/views/two_factor_screen.dart';
import '../../features/dashboard/views/dashboard_screen.dart';
import '../../features/inventory/views/inventory_screen.dart';
import '../../features/standalone/views/standalone_hub_screen.dart';
import '../../features/standalone/views/standalone_setup_screen.dart';
import '../../features/pos/views/pos_screen.dart';
import '../../features/members/views/members_hub_screen.dart';
import '../../features/operations/views/operations_hub_screen.dart';
import '../../features/settings/views/settings_screen.dart';
import '../../features/settings/views/sync_screen.dart';
import '../../features/shell/views/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorDashboard = GlobalKey<NavigatorState>(debugLabel: 'dashboard');
final _shellNavigatorPos = GlobalKey<NavigatorState>(debugLabel: 'pos');
final _shellNavigatorInventory = GlobalKey<NavigatorState>(debugLabel: 'inventory');
final _shellNavigatorMembers = GlobalKey<NavigatorState>(debugLabel: 'members');
final _shellNavigatorSettings = GlobalKey<NavigatorState>(debugLabel: 'settings');

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/login' ||
          loc == '/server-setup' ||
          loc == '/standalone-setup' ||
          loc == '/two-factor' ||
          loc == '/change-password';

      if (auth.status == AuthStatus.unknown || auth.isLoading) {
        return null;
      }

      if (auth.status == AuthStatus.needsServer && loc != '/server-setup') {
        return '/server-setup';
      }

      if (auth.status == AuthStatus.standalone) {
        if (isAuthRoute ||
            loc == '/dashboard' ||
            loc == '/members' ||
            loc == '/sync' ||
            loc.startsWith('/operations')) {
          return '/pos';
        }
        return null;
      }

      if ((auth.status == AuthStatus.unauthenticated ||
              auth.status == AuthStatus.needsBiometric) &&
          !isAuthRoute) {
        return '/login';
      }

      if (auth.status == AuthStatus.needs2fa && loc != '/two-factor') {
        return '/two-factor';
      }

      if (auth.status == AuthStatus.needsPasswordChange &&
          loc != '/change-password') {
        return '/change-password';
      }

      if (auth.status == AuthStatus.authenticated && isAuthRoute) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/server-setup',
        builder: (_, __) => const ServerSetupScreen(),
      ),
      GoRoute(
        path: '/standalone-setup',
        builder: (_, __) => const StandaloneSetupScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/two-factor',
        builder: (_, __) => const TwoFactorScreen(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (_, __) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/operations',
        builder: (_, state) {
          final tabParam = state.uri.queryParameters['tab'] ?? 'notifications';
          const tabKeys = {'delivery', 'crm', 'notifications'};
          if (tabKeys.contains(tabParam)) {
            return OperationsHubScreen(initialTabKey: tabParam);
          }
          final tab = int.tryParse(tabParam) ?? 0;
          return OperationsHubScreen(initialTab: tab);
        },
      ),
      GoRoute(
        path: '/sync',
        builder: (_, __) => const SyncScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorDashboard,
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (_, __) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorPos,
            routes: [
              GoRoute(
                path: '/pos',
                builder: (_, __) => const PosScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorInventory,
            routes: [
              GoRoute(
                path: '/inventory',
                builder: (context, __) {
                  final auth = ProviderScope.containerOf(context)
                      .read(authControllerProvider);
                  if (auth.status == AuthStatus.standalone) {
                    return const StandaloneHubScreen();
                  }
                  return const InventoryScreen();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorMembers,
            routes: [
              GoRoute(
                path: '/members',
                builder: (_, __) => const MembersHubScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSettings,
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, __) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});