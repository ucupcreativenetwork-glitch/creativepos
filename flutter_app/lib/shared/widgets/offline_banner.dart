import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../services/connectivity_service.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(authControllerProvider).status == AuthStatus.standalone) {
      return Material(
        color: AppColors.posGreen,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.storefront, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mode Standalone — semua data tersimpan di HP ini',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final mode = ref.watch(connectivityModeProvider);

    return mode.when(
      data: (status) {
        if (status == ConnectivityMode.online) return const SizedBox.shrink();

        final (icon, message, color) = switch (status) {
          ConnectivityMode.noNetwork => (
              Icons.wifi_off,
              'Tidak ada jaringan — data lokal aktif, sync saat server terdeteksi',
              Colors.amber.shade800,
            ),
          ConnectivityMode.serverUnreachable => (
              Icons.dns_outlined,
              'Server tidak terjangkau — POS pakai database lokal, sync otomatis saat server aktif',
              Colors.deepOrange.shade700,
            ),
          ConnectivityMode.online => (Icons.cloud_done, '', Colors.green),
        };

        return Material(
          color: color,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}