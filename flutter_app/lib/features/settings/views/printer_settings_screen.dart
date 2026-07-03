import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../services/printer_service.dart';
import 'receipt_template_screen.dart';

class PrinterSettingsScreen extends ConsumerStatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  ConsumerState<PrinterSettingsScreen> createState() =>
      _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends ConsumerState<PrinterSettingsScreen> {
  List<BluetoothPrinterInfo> _printers = [];
  PrinterConfig _config = const PrinterConfig();
  bool _loading = false;
  bool _connected = false;
  String? _message;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = ref.read(printerServiceProvider);
    final config = await service.getConfig();
    final connected = await service.isConnected();
    if (mounted) {
      setState(() {
        _config = config;
        _connected = connected;
      });
    }
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _loading = true;
      _message = null;
      _permissionDenied = false;
    });
    try {
      final result =
          await ref.read(printerServiceProvider).requestBluetoothAccess();
      setState(() {
        _message = result.message;
        _permissionDenied =
            !result.success && result.reason == PrintFailureReason.permissionDenied;
      });
      if (result.success) {
        await _scanPrinters();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _scanPrinters() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final service = ref.read(printerServiceProvider);
      final devices = await service.listPairedPrinters();
      setState(() {
        _printers = devices;
        _message = devices.isEmpty
            ? 'Tidak ada printer ter-pair. Pair dulu di Pengaturan Bluetooth Android.'
            : 'Pilih printer dari daftar (${devices.length} ditemukan)';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectPrinter(BluetoothPrinterInfo printer) async {
    final service = ref.read(printerServiceProvider);
    final ok = await service.connect(printer.macAddress);
    final config = _config.copyWith(
      macAddress: printer.macAddress,
      printerName: printer.name,
    );
    await service.saveConfig(config);
    ref.invalidate(printerConfigProvider);
    if (mounted) {
      setState(() {
        _config = config;
        _connected = ok;
        _message = ok
            ? 'Terhubung ke ${printer.name}'
            : 'Gagal terhubung ke ${printer.name}. Pastikan printer menyala.';
      });
    }
  }

  Future<void> _testPrint() async {
    final result = await ref.read(printerServiceProvider).printTestPage();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Printer ESC/POS')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Cara setup printer',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '1. Pair printer di Pengaturan Bluetooth HP\n'
                    '2. Izinkan izin Bluetooth & Perangkat di sekitar\n'
                    '3. Pilih printer di bawah\n'
                    '4. Tes cetak sebelum transaksi',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Printer Aktif',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(_config.printerName ?? 'Belum dikonfigurasi'),
                  if (_config.macAddress != null)
                    Text(
                      _config.macAddress!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _connected ? 'Status: Terhubung' : 'Status: Tidak terhubung',
                    style: TextStyle(
                      color: _connected ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Cetak otomatis setelah checkout'),
            subtitle: const Text(
              'Jika gagal, Anda tetap bisa cetak ulang dari layar struk',
            ),
            value: _config.autoPrint,
            onChanged: (v) async {
              final updated = _config.copyWith(autoPrint: v);
              await ref.read(printerServiceProvider).saveConfig(updated);
              ref.invalidate(printerConfigProvider);
              setState(() => _config = updated);
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Atur bentuk struk / nota'),
            subtitle: const Text('Header, footer, dan tampilan item'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReceiptTemplateScreen()),
            ),
          ),
          ListTile(
            title: const Text('Lebar kertas'),
            trailing: DropdownButton<int>(
              value: _config.paperWidthMm,
              items: const [
                DropdownMenuItem(value: 58, child: Text('58 mm')),
                DropdownMenuItem(value: 80, child: Text('80 mm')),
              ],
              onChanged: (v) async {
                if (v == null) return;
                final updated = _config.copyWith(paperWidthMm: v);
                await ref.read(printerServiceProvider).saveConfig(updated);
                ref.invalidate(printerConfigProvider);
                setState(() => _config = updated);
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _loading ? null : _requestPermissions,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.bluetooth),
                  label: const Text('Izin & Cari Printer'),
                ),
              ),
              const SizedBox(width: 12),
              if (_config.isConfigured)
                FilledButton.tonalIcon(
                  onPressed: _testPrint,
                  icon: const Icon(Icons.print),
                  label: const Text('Test'),
                ),
            ],
          ),
          if (_permissionDenied) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: openAppSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Buka Pengaturan Aplikasi'),
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 16),
          ..._printers.map(
            (p) => ListTile(
              leading: const Icon(Icons.print_outlined),
              title: Text(p.name.isNotEmpty ? p.name : 'Printer'),
              subtitle: Text(p.macAddress),
              trailing: _config.macAddress == p.macAddress
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () => _selectPrinter(p),
            ),
          ),
        ],
      ),
    );
  }
}