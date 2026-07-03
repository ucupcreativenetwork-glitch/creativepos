import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../features/auth/providers/auth_providers.dart';

class AuthSplashOverlay extends ConsumerWidget {
  const AuthSplashOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final showSplash =
        auth.status == AuthStatus.unknown || auth.isLoading;

    return Stack(
      children: [
        child,
        if (showSplash)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Logo(),
                    SizedBox(height: 24),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.posGreen,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Memuat aplikasi...',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.posGreen, AppColors.posGreenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: const Text(
        'CP',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
    );
  }
}