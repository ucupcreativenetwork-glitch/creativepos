import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_providers.dart';

class StandaloneSetupScreen extends ConsumerStatefulWidget {
  const StandaloneSetupScreen({super.key});

  @override
  ConsumerState<StandaloneSetupScreen> createState() =>
      _StandaloneSetupScreenState();
}

class _StandaloneSetupScreenState extends ConsumerState<StandaloneSetupScreen> {
  final _businessController = TextEditingController();
  final _ownerController = TextEditingController(text: 'Kasir');
  var _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _businessController.dispose();
    _ownerController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final business = _businessController.text.trim();
    if (business.isEmpty) {
      setState(() => _error = 'Nama toko wajib diisi');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final ok = await ref.read(authControllerProvider.notifier).activateStandalone(
          businessName: business,
          ownerName: _ownerController.text.trim().isEmpty
              ? 'Kasir'
              : _ownerController.text.trim(),
        );

    if (!mounted) return;
    if (ok) {
      context.go('/pos');
    } else {
      final auth = ref.read(authControllerProvider);
      setState(() {
        _isLoading = false;
        _error = auth.error ?? 'Gagal mengaktifkan mode standalone';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Container(
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
                child: const Icon(Icons.storefront, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 20),
              Text(
                'Mode Standalone',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kelola toko langsung di HP tanpa server. '
                'Tambah produk, stok via scan barcode, dan jualan di kasir.',
                style: TextStyle(color: AppColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _businessController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama Toko',
                  hintText: 'Warung Bu Siti',
                  prefixIcon: Icon(Icons.store_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ownerController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama Kasir / Pemilik',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isLoading ? null : _start,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.rocket_launch_outlined),
                label: Text(_isLoading ? 'Menyiapkan...' : 'Mulai Toko Mandiri'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.posGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading ? null : () => context.go('/server-setup'),
                child: const Text('Kembali ke mode server'),
              ),
              const SizedBox(height: 24),
              Card(
                color: AppColors.posGreenLight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: AppColors.posGreen, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Yang bisa Anda lakukan',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.posGreenDark,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _feature(Icons.qr_code_scanner, 'Scan barcode untuk tambah stok'),
                      _feature(Icons.add_box_outlined, 'Tambah produk manual'),
                      _feature(Icons.point_of_sale, 'Kasir POS offline penuh'),
                      _feature(Icons.print_outlined, 'Cetak struk Bluetooth'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.posGreenDark),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}