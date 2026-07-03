import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/biometric_service.dart';
import '../providers/auth_providers.dart';
import '../providers/biometric_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _remember = true;
  var _obscure = true;
  var _biometricAvailable = false;
  var _biometricEnabled = false;
  BiometricLoginType _biometricType = BiometricLoginType.generic;
  var _autoBiometricAttempted = false;
  var _showPasswordForm = false;

  @override
  void initState() {
    super.initState();
    _loadRemembered();
    _loadBiometricState();
  }

  Future<void> _loadRemembered() async {
    final email =
        await ref.read(authRepositoryProvider).getRememberedEmail();
    if (email != null) _emailController.text = email;
  }

  Future<void> _loadBiometricState() async {
    final service = ref.read(biometricServiceProvider);
    final available = await service.isAvailable();
    final enabled = await ref.read(authRepositoryProvider).isBiometricEnabled();
    final loginType = await service.getLoginType();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
      _biometricType = loginType;
    });
    if (ref.read(authControllerProvider).status == AuthStatus.needsBiometric) {
      await _tryAutoBiometric();
    }
  }

  Future<void> _tryAutoBiometric() async {
    if (_autoBiometricAttempted || !_biometricEnabled || !_biometricAvailable) {
      return;
    }
    final auth = ref.read(authControllerProvider);
    if (auth.status != AuthStatus.needsBiometric || auth.isLoading) return;
    _autoBiometricAttempted = true;
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (mounted) await _biometricLogin();
  }

  Future<void> _setBiometricEnabled(bool value) async {
    if (value) {
      final hasToken = await ref.read(authRepositoryProvider).hasStoredToken();
      if (!hasToken) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Login dulu dengan email & password sebelum mengaktifkan biometrik',
              ),
            ),
          );
        }
        return;
      }
      final ok = await ref.read(biometricServiceProvider).authenticate(
            reason: 'Konfirmasi untuk mengaktifkan login ${_biometricLabel()}',
          );
      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Autentikasi biometrik dibatalkan')),
          );
        }
        return;
      }
    }
    await ref.read(authRepositoryProvider).setBiometricEnabled(value);
    if (mounted) setState(() => _biometricEnabled = value);
  }

  String _biometricLabel() =>
      ref.read(biometricServiceProvider).labelFor(_biometricType);

  IconData _biometricIcon() {
    switch (_biometricType) {
      case BiometricLoginType.face:
        return Icons.face;
      case BiometricLoginType.fingerprint:
        return Icons.fingerprint;
      case BiometricLoginType.generic:
        return Icons.lock_outline;
    }
  }

  Future<void> _biometricLogin() async {
    final ok = await ref.read(biometricServiceProvider).authenticate(
          reason: 'Masuk ke CreativePOS dengan ${_biometricLabel()}',
        );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Autentikasi ${_biometricLabel()} gagal atau dibatalkan'),
        ),
      );
      return;
    }

    final success =
        await ref.read(authControllerProvider.notifier).completeBiometricLogin();
    if (!mounted) return;
    if (success) {
      context.go('/dashboard');
      return;
    }
    final error = ref.read(authControllerProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? 'Sesi tidak ditemukan. Masuk dengan email dan password.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan password wajib diisi')),
      );
      return;
    }

    final ok = await ref.read(authControllerProvider.notifier).login(
          email: email,
          password: password,
          remember: _remember,
        );
    if (!mounted) return;
    final status = ref.read(authControllerProvider).status;
    if (status == AuthStatus.needs2fa) {
      context.go('/two-factor');
      return;
    }
    if (ok && status == AuthStatus.authenticated) {
      if (_biometricAvailable && !_biometricEnabled) {
        final enable = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Aktifkan ${_biometricLabel()}?'),
            content: Text(
              'Login berikutnya bisa pakai ${_biometricLabel()} tanpa mengetik password.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Nanti'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Aktifkan'),
              ),
            ],
          ),
        );
        if (enable == true) {
          await _setBiometricEnabled(true);
        }
      }
      if (mounted) context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final server = ref.watch(serverUrlProvider);
    final biometricUnlock = auth.status == AuthStatus.needsBiometric;
    final showBiometricLogin =
        _biometricAvailable &&
        (biometricUnlock || _biometricEnabled);
    final showCredentials = !biometricUnlock || _showPasswordForm;

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.needsBiometric &&
          previous?.status != AuthStatus.needsBiometric) {
        _autoBiometricAttempted = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _tryAutoBiometric();
        });
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.point_of_sale, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'CreativePOS',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      server ?? 'Server belum diatur',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      biometricUnlock
                          ? 'Buka kunci aplikasi'
                          : 'Masuk ke akun Anda',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (biometricUnlock) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Gunakan ${_biometricLabel()} untuk melanjutkan',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (showBiometricLogin) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: auth.isLoading ? null : _biometricLogin,
                          icon: Icon(_biometricIcon(), size: 26),
                          label: Text('Masuk dengan ${_biometricLabel()}'),
                        ),
                      ),
                      if (biometricUnlock) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: () =>
                                setState(() => _showPasswordForm = true),
                            child: const Text('Masuk dengan email & password'),
                          ),
                        ),
                      ],
                      if (showCredentials) ...[
                        const SizedBox(height: 16),
                        const Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('atau'),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                    if (showCredentials) ...[
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure ? Icons.visibility : Icons.visibility_off,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: _remember,
                            onChanged: (v) =>
                                setState(() => _remember = v ?? true),
                          ),
                          const Text('Ingat saya'),
                          const Spacer(),
                          TextButton(
                            onPressed: () => context.go('/server-setup'),
                            child: const Text('Ganti server'),
                          ),
                        ],
                      ),
                      if (_biometricAvailable && !biometricUnlock) ...[
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Login ${_biometricLabel()}'),
                          subtitle: const Text(
                            'Wajib verifikasi biometrik saat membuka aplikasi',
                          ),
                          value: _biometricEnabled,
                          onChanged: auth.isLoading
                              ? null
                              : (v) => _setBiometricEnabled(v),
                        ),
                      ],
                      if (auth.error != null) ...[
                        Text(
                          auth.error!,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                        const SizedBox(height: 12),
                      ],
                      FilledButton(
                        onPressed: auth.isLoading ? null : _login,
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Masuk'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}