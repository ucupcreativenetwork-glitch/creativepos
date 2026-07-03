import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_messenger.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_providers.dart';
import 'services/fcm_service.dart';
import 'services/remote_agent_service.dart';
import 'services/sync_service.dart';
import 'services/update_service.dart';
import 'shared/widgets/auth_splash_overlay.dart';
import 'shared/widgets/update_dialog.dart';

class CreativePosApp extends ConsumerWidget {
  const CreativePosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return _SyncBootstrap(
      child: _RemoteAgentBootstrap(
        child: _FcmBootstrap(
          child: _UpdateBootstrap(
            child: AuthSplashOverlay(
              child: MaterialApp.router(
                title: 'CreativePOS',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light(),
                scaffoldMessengerKey: rootScaffoldMessengerKey,
                routerConfig: router,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RemoteAgentBootstrap extends ConsumerStatefulWidget {
  const _RemoteAgentBootstrap({required this.child});

  final Widget child;

  @override
  ConsumerState<_RemoteAgentBootstrap> createState() =>
      _RemoteAgentBootstrapState();
}

class _RemoteAgentBootstrapState extends ConsumerState<_RemoteAgentBootstrap> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_startAgent);
  }

  Future<void> _startAgent() async {
    await ref.read(remoteAgentServiceProvider).start();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated ||
          next.status == AuthStatus.standalone) {
        ref.read(remoteAgentServiceProvider).start();
      } else {
        ref.read(remoteAgentServiceProvider).stop();
      }
    });

    return widget.child;
  }
}

class _UpdateBootstrap extends ConsumerStatefulWidget {
  const _UpdateBootstrap({required this.child});

  final Widget child;

  @override
  ConsumerState<_UpdateBootstrap> createState() => _UpdateBootstrapState();
}

class _UpdateBootstrapState extends ConsumerState<_UpdateBootstrap>
    with WidgetsBindingObserver {
  AppUpdateInfo? _lastShown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(_checkUpdate);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkUpdate();
    }
  }

  Future<void> _checkUpdate() async {
    final auth = ref.read(authControllerProvider);
    if (auth.status != AuthStatus.authenticated &&
        auth.status != AuthStatus.standalone &&
        auth.status != AuthStatus.needsServer) {
      return;
    }

    final info = await ref.read(updateServiceProvider).checkForUpdate();
    if (!info.updateAvailable || info.downloadUrl == null) return;
    if (_lastShown?.latestBuildNumber == info.latestBuildNumber) return;

    _lastShown = info;
    if (!mounted) return;
    await showUpdateDialog(context, ref, info);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _SyncBootstrap extends ConsumerStatefulWidget {
  const _SyncBootstrap({required this.child});

  final Widget child;

  @override
  ConsumerState<_SyncBootstrap> createState() => _SyncBootstrapState();
}

class _SyncBootstrapState extends ConsumerState<_SyncBootstrap> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(syncServiceProvider).startAutoSync());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _FcmBootstrap extends ConsumerStatefulWidget {
  const _FcmBootstrap({required this.child});

  final Widget child;

  @override
  ConsumerState<_FcmBootstrap> createState() => _FcmBootstrapState();
}

class _FcmBootstrapState extends ConsumerState<_FcmBootstrap> {
  bool _registered = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(fcmServiceProvider).initialize();
      _tryRegister();
    });
  }

  void _tryRegister() {
    if (_registered) return;
    final auth = ref.read(authControllerProvider);
    if (auth.status == AuthStatus.authenticated) {
      _registered = true;
      ref.read(fcmServiceProvider).registerIfAuthenticated();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated &&
          prev?.status != AuthStatus.authenticated) {
        _registered = true;
        ref.read(fcmServiceProvider).registerIfAuthenticated();
      }
      if (next.status != AuthStatus.authenticated) {
        _registered = false;
      }
    });

    return widget.child;
  }
}