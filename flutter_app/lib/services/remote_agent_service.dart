import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import '../features/auth/providers/auth_providers.dart';
import 'remote_agent_repository.dart';
import 'sync_service.dart';
import 'update_service.dart';

const _installIdKey = 'creativepos_install_id';
const _agentVersion = '1.0.0';

final remoteAgentServiceProvider = Provider<RemoteAgentService>((ref) {
  return RemoteAgentService(ref);
});

class RemoteAgentService {
  RemoteAgentService(this._ref);

  final Ref _ref;
  Timer? _heartbeatTimer;
  Timer? _pollTimer;
  String? _fingerprint;
  String? _installId;
  bool _running = false;

  Future<void> start() async {
    if (_running) return;
    final auth = _ref.read(authControllerProvider);
    if (auth.status != AuthStatus.authenticated &&
        auth.status != AuthStatus.standalone) {
      return;
    }

    _running = true;
    await _ensureIdentity();
    await _register();
    _heartbeatTimer?.cancel();
    _pollTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 2), (_) => _heartbeat());
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _pollCommands());
    await _pollCommands();
  }

  void stop() {
    _running = false;
    _heartbeatTimer?.cancel();
    _pollTimer?.cancel();
    _heartbeatTimer = null;
    _pollTimer = null;
  }

  Future<void> handleRemoteCommand(Map<String, dynamic> command) async {
    final id = command['id'] as int?;
    final name = command['command']?.toString() ?? '';
    if (id == null || _fingerprint == null) return;

    try {
      final result = await _executeCommand(name);
      await _ref.read(remoteAgentRepositoryProvider).completeCommand(
            commandId: id,
            fingerprint: _fingerprint!,
            status: 'completed',
            result: result,
          );
    } catch (e) {
      await _ref.read(remoteAgentRepositoryProvider).completeCommand(
            commandId: id,
            fingerprint: _fingerprint!,
            status: 'failed',
            result: e.toString(),
          );
    }
  }

  Future<void> _ensureIdentity() async {
    final box = await Hive.openBox('offline_meta');
    _installId = box.get(_installIdKey) as String?;
    if (_installId == null || _installId!.isEmpty) {
      _installId = const Uuid().v4();
      await box.put(_installIdKey, _installId);
    }

    if (!kIsWeb && Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      _fingerprint = info.id;
    } else {
      _fingerprint = _installId;
    }
  }

  Future<Map<String, dynamic>> _collectDeviceInfo() async {
    final package = await PackageInfo.fromPlatform();
    var platform = 'unknown';
    var osVersion = '';
    var model = '';
    String? macAddress;

    if (!kIsWeb && Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      platform = 'android';
      osVersion = 'Android ${info.version.release} (SDK ${info.version.sdkInt})';
      model = '${info.manufacturer} ${info.model}';
      macAddress = info.id;
    }

    return {
      'device_name': model.isNotEmpty ? 'CreativePOS $model' : 'CreativePOS Android',
      'fingerprint': _fingerprint,
      'install_id': _installId,
      'platform': platform,
      'app_version': package.version,
      'build_number': int.tryParse(package.buildNumber),
      'os_version': osVersion,
      'device_model': model,
      'mac_address': macAddress,
      'api_base_url': _ref.read(apiBaseUrlProvider),
      'agent_version': _agentVersion,
    };
  }

  Future<void> _register() async {
    final payload = await _collectDeviceInfo();
    await _ref.read(remoteAgentRepositoryProvider).register(payload);
  }

  Future<void> _heartbeat() async {
    if (_fingerprint == null) return;
    final package = await PackageInfo.fromPlatform();
    await _ref.read(remoteAgentRepositoryProvider).heartbeat({
      'fingerprint': _fingerprint,
      'app_version': package.version,
      'build_number': int.tryParse(package.buildNumber),
    });
  }

  Future<void> _pollCommands() async {
    if (_fingerprint == null) return;
    try {
      final commands =
          await _ref.read(remoteAgentRepositoryProvider).pendingCommands(_fingerprint!);
      for (final command in commands) {
        await handleRemoteCommand(command);
      }
    } catch (e) {
      debugPrint('Remote command poll failed: $e');
    }
  }

  Future<String> _executeCommand(String command) async {
    switch (command) {
      case 'ping':
        return 'pong';
      case 'collect_info':
        final info = await _collectDeviceInfo();
        await _uploadDiagnostics('device_info', jsonEncode(info), title: 'Device Info');
        return 'device info uploaded';
      case 'collect_logs':
        await _uploadDiagnostics(
          'logs',
          'CreativePOS remote log snapshot at ${DateTime.now().toIso8601String()}',
          title: 'App Logs Snapshot',
        );
        return 'logs uploaded';
      case 'check_update':
        final update = await _ref.read(updateServiceProvider).checkForUpdate();
        return jsonEncode({
          'update_available': update.updateAvailable,
          'latest_version': update.latestVersion,
          'latest_build_number': update.latestBuildNumber,
        });
      case 'clear_cache':
        return 'cache clear requested (restart app to fully apply)';
      case 'force_sync':
        final result = await _ref.read(syncServiceProvider).syncPending();
        return 'synced=${result.synced}, failed=${result.failed}';
      case 'open_remote_assist':
        return 'remote assist ready — gunakan ADB/Scrcpy dengan fingerprint $_fingerprint';
      default:
        throw UnsupportedError('Unknown command: $command');
    }
  }

  Future<void> _uploadDiagnostics(
    String type,
    String content, {
    String? title,
    Map<String, dynamic>? metadata,
  }) async {
    if (_fingerprint == null) return;
    await _ref.read(remoteAgentRepositoryProvider).uploadDiagnostics(
          fingerprint: _fingerprint!,
          type: type,
          content: content,
          title: title,
          metadata: metadata,
        );
  }
}