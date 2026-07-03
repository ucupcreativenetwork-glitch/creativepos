import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../auth/providers/auth_providers.dart';
import '../../../services/biometric_service.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/update_service.dart';
import '../../../shared/widgets/update_dialog.dart';
import '../../auth/providers/biometric_providers.dart';
import '../providers/feature_providers.dart';
import '../providers/sync_providers.dart';
import '../../../services/standalone_service.dart';
import '../../standalone/providers/standalone_providers.dart';
import 'printer_settings_screen.dart';
import 'receipt_template_screen.dart';
import '../../pos/providers/pos_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '';
  var _biometricEnabled = false;
  var _biometricAvailable = false;
  BiometricLoginType _biometricType = BiometricLoginType.generic;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadBiometric();
  }

  Future<void> _loadBiometric() async {
    final service = ref.read(biometricServiceProvider);
    final enabled = await ref.read(authRepositoryProvider).isBiometricEnabled();
    final available = await service.isAvailable();
    final type = await service.getLoginType();
    if (mounted) {
      setState(() {
        _biometricEnabled = enabled;
        _biometricAvailable = available;
        _biometricType = type;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final hasToken = await ref.read(authRepositoryProvider).hasStoredToken();
      if (!hasToken) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login ulang dulu untuk mengaktifkan biometrik'),
            ),
          );
        }
        return;
      }
      final ok = await ref.read(biometricServiceProvider).authenticate(
            reason:
                'Konfirmasi untuk mengaktifkan ${ref.read(biometricServiceProvider).labelFor(_biometricType)}',
          );
      if (!ok) return;
    }
    await ref.read(authRepositoryProvider).setBiometricEnabled(value);
    if (mounted) setState(() => _biometricEnabled = value);
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = info.version);
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Anda perlu masuk kembali untuk menggunakan aplikasi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  Future<void> _editStandaloneProfile() async {
    final profile = await ref.read(standaloneServiceProvider).getProfile();
    if (profile == null || !mounted) return;

    final businessController = TextEditingController(text: profile.businessName);
    final ownerController = TextEditingController(text: profile.ownerName);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profil Toko'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: businessController,
              decoration: const InputDecoration(labelText: 'Nama Toko'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ownerController,
              decoration: const InputDecoration(labelText: 'Nama Kasir'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) {
      businessController.dispose();
      ownerController.dispose();
      return;
    }

    final businessName = businessController.text.trim();
    final ownerName = ownerController.text.trim();
    businessController.dispose();
    ownerController.dispose();

    await ref.read(standaloneServiceProvider).updateProfile(
          StandaloneProfile(
            businessName: businessName.isEmpty ? profile.businessName : businessName,
            ownerName: ownerName.isEmpty ? profile.ownerName : ownerName,
          ),
        );
    ref.invalidate(standaloneProfileProvider);
    ref.invalidate(settingsOutletsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil toko diperbarui')),
      );
    }
  }

  Future<void> _exitStandalone() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar mode standalone?'),
        content: const Text(
          'Data produk lokal tetap tersimpan di HP. '
          'Anda bisa kembali ke mode server kapan saja.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(authControllerProvider.notifier).exitStandaloneMode();
    if (mounted) context.go('/server-setup');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final session = auth.session;
    final isStandalone = auth.status == AuthStatus.standalone;
    final server = ref.watch(serverUrlProvider);
    final pendingSync = ref.watch(pendingSyncCountProvider);
    final features = ref.watch(tenantFeaturesProvider);
    final profile = ref.watch(standaloneProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          if (session != null)
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(session.user.name),
              subtitle: Text(
                isStandalone
                    ? profile.maybeWhen(
                        data: (p) => p?.businessName ?? 'Mode Standalone',
                        orElse: () => 'Mode Standalone',
                      )
                    : session.user.email,
              ),
            ),
          if (isStandalone)
            ListTile(
              leading: Icon(Icons.storefront, color: Colors.green.shade700),
              title: const Text('Mode Standalone'),
              subtitle: const Text('Toko mandiri — tanpa server'),
            ),
          const Divider(),
          if (!isStandalone)
          Consumer(
            builder: (context, ref, _) {
              final mode = ref.watch(connectivityModeProvider);
              final status = mode.valueOrNull;
              final (icon, color, subtitle) = switch (status) {
                ConnectivityMode.online => (
                    Icons.cloud_done_outlined,
                    Colors.green.shade700,
                    'Server terhubung — sinkron otomatis aktif',
                  ),
                ConnectivityMode.noNetwork => (
                    Icons.wifi_off,
                    Colors.amber.shade800,
                    'Tanpa jaringan — database lokal, sync saat server terdeteksi',
                  ),
                ConnectivityMode.serverUnreachable => (
                    Icons.dns_outlined,
                    Colors.deepOrange.shade700,
                    'Server tidak terjangkau — POS pakai data lokal',
                  ),
                null => (
                    Icons.cloud_queue,
                    Colors.grey,
                    'Memeriksa server...',
                  ),
              };
              return ListTile(
                leading: Icon(icon, color: color),
                title: const Text('Koneksi & Sinkron'),
                subtitle: Text(subtitle),
              );
            },
          ),
          if (isStandalone) ...[
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Profil Toko'),
              subtitle: const Text('Ubah nama toko dan kasir'),
              onTap: _editStandaloneProfile,
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Template Struk'),
              subtitle: const Text('Atur tampilan nota'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReceiptTemplateScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.print_outlined),
              title: const Text('Printer'),
              subtitle: const Text('Bluetooth ESC/POS 58/80mm'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrinterSettingsScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.system_update_alt),
              title: const Text('Cek Update'),
              subtitle: const Text('Unduh versi terbaru'),
              onTap: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  final info = await ref.read(updateServiceProvider).checkForUpdate();
                  if (!mounted) return;
                  if (!info.updateAvailable) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Anda sudah menggunakan versi terbaru')),
                    );
                    return;
                  }
                  if (!context.mounted) return;
                  await showUpdateDialog(context, ref, info);
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(SnackBar(content: Text('Gagal cek update: $e')));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Tentang Aplikasi'),
              subtitle: Text(
                _version.isEmpty ? 'CreativePOS Standalone' : 'CreativePOS Standalone v$_version',
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: Colors.orange),
              title: const Text('Ganti ke Mode Server'),
              subtitle: const Text('Keluar standalone & hubungkan server'),
              onTap: _exitStandalone,
            ),
          ] else ...[
          if (_biometricAvailable)
            SwitchListTile(
              secondary: Icon(
                _biometricType == BiometricLoginType.face
                    ? Icons.face
                    : Icons.fingerprint,
              ),
              title: Text(
                'Login ${ref.read(biometricServiceProvider).labelFor(_biometricType)}',
              ),
              subtitle: const Text(
                'Wajib verifikasi biometrik saat membuka aplikasi',
              ),
              value: _biometricEnabled,
              onChanged: _toggleBiometric,
            ),
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('Server'),
            subtitle: Text(server ?? '-'),
            onTap: () => context.go('/server-setup'),
          ),
          features.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (f) => Column(
              children: [
                if (f.hasDelivery)
                  ListTile(
                    leading: const Icon(Icons.delivery_dining_outlined),
                    title: const Text('Delivery'),
                    subtitle: const Text('Kelola order pengiriman'),
                    onTap: () => context.push(operationsPath('delivery')),
                  ),
                if (f.hasCrm)
                  ListTile(
                    leading: const Icon(Icons.support_agent_outlined),
                    title: const Text('CRM & Support'),
                    subtitle: const Text('Tiket pelanggan & FAQ'),
                    onTap: () => context.push(operationsPath('crm')),
                  ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifikasi'),
            subtitle: const Text('Inbox & push FCM'),
            onTap: () => context.push(operationsPath('notifications')),
          ),
          ListTile(
            leading: const Icon(Icons.print_outlined),
            title: const Text('Printer'),
            subtitle: const Text('Bluetooth ESC/POS 58/80mm'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrinterSettingsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.sync_outlined),
            title: const Text('Sinkronisasi'),
            subtitle: pendingSync.when(
              data: (c) => Text(
                c > 0 ? '$c transaksi menunggu sync' : 'Semua tersinkron',
              ),
              loading: () => const Text('Memuat...'),
              error: (_, __) => const Text('Offline queue'),
            ),
            onTap: () => context.push('/sync'),
          ),
          ListTile(
            leading: const Icon(Icons.system_update_alt),
            title: const Text('Cek Update'),
            subtitle: const Text('Unduh versi terbaru otomatis'),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                final info = await ref.read(updateServiceProvider).checkForUpdate();
                if (!mounted) return;
                if (!info.updateAvailable) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Anda sudah menggunakan versi terbaru'),
                    ),
                  );
                  return;
                }
                if (!context.mounted) return;
                await showUpdateDialog(context, ref, info);
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text('Gagal cek update: $e')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Tentang Aplikasi'),
            subtitle: Text('CreativePOS Mobile v$_version'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Keluar', style: TextStyle(color: Colors.red)),
            onTap: () => _logout(),
          ),
          ],
        ],
      ),
    );
  }
}