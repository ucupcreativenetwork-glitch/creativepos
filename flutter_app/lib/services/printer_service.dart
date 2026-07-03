import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../local_database/offline_queue.dart';
import 'receipt_builder.dart';
import 'receipt_template.dart';

enum PrintFailureReason {
  notConfigured,
  permissionDenied,
  bluetoothOff,
  connectFailed,
  writeFailed,
  unsupportedPlatform,
}

class PrintResult {
  const PrintResult({
    required this.success,
    required this.message,
    this.reason,
  });

  final bool success;
  final String message;
  final PrintFailureReason? reason;

  factory PrintResult.ok([String message = 'Struk dikirim ke printer']) =>
      PrintResult(success: true, message: message);

  factory PrintResult.fail(
    String message, {
    PrintFailureReason? reason,
  }) =>
      PrintResult(success: false, message: message, reason: reason);
}

class PrinterConfig {
  const PrinterConfig({
    this.macAddress,
    this.printerName,
    this.paperWidthMm = 58,
    this.autoPrint = true,
  });

  final String? macAddress;
  final String? printerName;
  final int paperWidthMm;
  final bool autoPrint;

  bool get isConfigured => macAddress != null && macAddress!.isNotEmpty;

  PaperSize get paperSize =>
      paperWidthMm >= 80 ? PaperSize.mm80 : PaperSize.mm58;

  PrinterConfig copyWith({
    String? macAddress,
    String? printerName,
    int? paperWidthMm,
    bool? autoPrint,
  }) {
    return PrinterConfig(
      macAddress: macAddress ?? this.macAddress,
      printerName: printerName ?? this.printerName,
      paperWidthMm: paperWidthMm ?? this.paperWidthMm,
      autoPrint: autoPrint ?? this.autoPrint,
    );
  }

  Map<String, dynamic> toMap() => {
        'mac_address': macAddress,
        'printer_name': printerName,
        'paper_width_mm': paperWidthMm,
        'auto_print': autoPrint,
      };

  factory PrinterConfig.fromMap(Map<dynamic, dynamic> map) {
    return PrinterConfig(
      macAddress: map['mac_address'] as String?,
      printerName: map['printer_name'] as String?,
      paperWidthMm: map['paper_width_mm'] as int? ?? 58,
      autoPrint: map['auto_print'] as bool? ?? true,
    );
  }
}

class BluetoothPrinterInfo {
  const BluetoothPrinterInfo({required this.name, required this.macAddress});

  final String name;
  final String macAddress;
}

class PrinterService {
  static const _configKey = 'printer_config';
  static const _lastMacKey = 'printer_last_connected_mac';

  Future<Box> _box() => Hive.openBox(OfflineQueue.hiveBoxName);

  Future<PrinterConfig> getConfig() async {
    final box = await _box();
    final raw = box.get(_configKey);
    if (raw is Map) {
      return PrinterConfig.fromMap(raw);
    }
    return const PrinterConfig();
  }

  Future<void> saveConfig(PrinterConfig config) async {
    final box = await _box();
    await box.put(_configKey, config.toMap());
  }

  Future<PrintResult> requestBluetoothAccess() async {
    if (kIsWeb || Platform.isWindows) {
      return PrintResult.fail(
        'Printer Bluetooth hanya tersedia di Android/iOS',
        reason: PrintFailureReason.unsupportedPlatform,
      );
    }

    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      final sdk = info.version.sdkInt;
      if (sdk >= 31) {
        var status = await Permission.bluetoothConnect.status;
        if (!status.isGranted) {
          status = await Permission.bluetoothConnect.request();
        }
        if (!status.isGranted) {
          return PrintResult.fail(
            'Izin Bluetooth ditolak. Buka Pengaturan > Aplikasi > CreativePOS > Izin > Perangkat di sekitar.',
            reason: PrintFailureReason.permissionDenied,
          );
        }

        var scan = await Permission.bluetoothScan.status;
        if (!scan.isGranted) {
          scan = await Permission.bluetoothScan.request();
        }
        if (!scan.isGranted) {
          return PrintResult.fail(
            'Izin pemindaian Bluetooth ditolak.',
            reason: PrintFailureReason.permissionDenied,
          );
        }
      } else {
        var location = await Permission.locationWhenInUse.status;
        if (!location.isGranted) {
          location = await Permission.locationWhenInUse.request();
        }
        if (!location.isGranted) {
          return PrintResult.fail(
            'Izin lokasi diperlukan untuk printer Bluetooth di Android ini.',
            reason: PrintFailureReason.permissionDenied,
          );
        }
      }
    }

    final granted = await PrintBluetoothThermal.isPermissionBluetoothGranted;
    if (!granted) {
      return PrintResult.fail(
        'Izin Bluetooth belum aktif. Cek pengaturan perangkat.',
        reason: PrintFailureReason.permissionDenied,
      );
    }

    return PrintResult.ok();
  }

  Future<PrintResult> _ensureBluetoothOn() async {
    final enabled = await PrintBluetoothThermal.bluetoothEnabled;
    if (!enabled) {
      return PrintResult.fail(
        'Bluetooth mati. Nyalakan Bluetooth di pengaturan HP.',
        reason: PrintFailureReason.bluetoothOff,
      );
    }
    return PrintResult.ok();
  }

  Future<List<BluetoothPrinterInfo>> listPairedPrinters() async {
    if (kIsWeb || Platform.isWindows) return [];

    final access = await requestBluetoothAccess();
    if (!access.success) return [];

    final bt = await _ensureBluetoothOn();
    if (!bt.success) return [];

    final devices = await PrintBluetoothThermal.pairedBluetooths;
    return devices
        .map(
          (d) => BluetoothPrinterInfo(
            name: d.name,
            macAddress: d.macAdress,
          ),
        )
        .toList();
  }

  Future<bool> connect(String macAddress) async {
    if (kIsWeb || Platform.isWindows) return false;

    final access = await requestBluetoothAccess();
    if (!access.success) return false;

    final bt = await _ensureBluetoothOn();
    if (!bt.success) return false;

    await disconnect();
    final ok = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
    if (ok) {
      final box = await _box();
      await box.put(_lastMacKey, macAddress);
    }
    return ok;
  }

  Future<bool> isConnected() async {
    if (kIsWeb || Platform.isWindows) return false;
    return PrintBluetoothThermal.connectionStatus;
  }

  Future<bool> disconnect() async {
    if (kIsWeb || Platform.isWindows) return false;
    try {
      return await PrintBluetoothThermal.disconnect;
    } catch (_) {
      return false;
    }
  }

  Future<PrintResult> printReceipt(ReceiptData data) async {
    final config = await getConfig();
    if (!config.isConfigured) {
      return PrintResult.fail(
        'Printer belum dikonfigurasi. Buka Pengaturan > Printer.',
        reason: PrintFailureReason.notConfigured,
      );
    }

    final access = await requestBluetoothAccess();
    if (!access.success) return access;

    final bt = await _ensureBluetoothOn();
    if (!bt.success) return bt;

    try {
      final template = await ReceiptTemplateService().getTemplate();
      final bytes = await ReceiptBuilder.buildBytes(
        data: data,
        paperSize: config.paperSize,
        template: template,
      );
      return _writeBytes(config.macAddress!, bytes);
    } catch (e) {
      debugPrint('printReceipt error: $e');
      return PrintResult.fail(
        'Gagal menyiapkan data struk: $e',
        reason: PrintFailureReason.writeFailed,
      );
    }
  }

  Future<PrintResult> printTestPage() async {
    return printReceipt(
      ReceiptData(
        businessName: 'CreativePOS',
        transactionNumber: 'TEST-001',
        items: const [
          ReceiptItem(
            name: 'Test Item',
            quantity: 1,
            unitPrice: 10000,
            subtotal: 10000,
          ),
        ],
        subtotal: 10000,
        grandTotal: 10000,
        payments: const [ReceiptPayment(name: 'Tunai', amount: 10000)],
        completedAt: DateTime.now(),
      ),
    );
  }

  Future<PrintResult> _writeBytes(String mac, List<int> bytes) async {
    if (kIsWeb || Platform.isWindows) {
      return PrintResult.fail(
        'Platform tidak didukung',
        reason: PrintFailureReason.unsupportedPlatform,
      );
    }

    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        var connected = await isConnected();
        if (!connected) {
          await disconnect();
          connected = await PrintBluetoothThermal.connect(macPrinterAddress: mac);
        }
        if (!connected) {
          debugPrint('Printer connect attempt $attempt failed for $mac');
          await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
          continue;
        }

        final ok = await PrintBluetoothThermal.writeBytes(bytes);
        if (ok) {
          return PrintResult.ok();
        }

        debugPrint('Printer writeBytes attempt $attempt failed');
        await disconnect();
        await Future<void>.delayed(Duration(milliseconds: 300 * attempt));
      } catch (e) {
        debugPrint('Printer _writeBytes attempt $attempt: $e');
        await disconnect();
        await Future<void>.delayed(Duration(milliseconds: 300 * attempt));
      }
    }

    return PrintResult.fail(
      'Gagal mengirim ke printer. Pastikan printer menyala, ter-pair, dan dalam jangkauan.',
      reason: PrintFailureReason.writeFailed,
    );
  }
}

final printerServiceProvider = Provider<PrinterService>((ref) {
  return PrinterService();
});

final printerConfigProvider =
    FutureProvider.autoDispose<PrinterConfig>((ref) async {
  return ref.watch(printerServiceProvider).getConfig();
});