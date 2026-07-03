import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/constants/api_paths.dart';
import '../core/network/dio_client.dart';
import '../features/auth/providers/auth_providers.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.updateAvailable,
    required this.currentVersion,
    required this.currentBuildNumber,
    this.latestVersion,
    this.latestBuildNumber,
    this.forceUpdate = false,
    this.releaseNotes,
    this.downloadUrl,
    this.fileSize,
    this.checksumSha256,
  });

  final bool updateAvailable;
  final String currentVersion;
  final int currentBuildNumber;
  final String? latestVersion;
  final int? latestBuildNumber;
  final bool forceUpdate;
  final String? releaseNotes;
  final String? downloadUrl;
  final int? fileSize;
  final String? checksumSha256;

  factory AppUpdateInfo.fromJson(
    Map<String, dynamic> json, {
    required String currentVersion,
    required int currentBuild,
  }) {
    return AppUpdateInfo(
      updateAvailable: json['update_available'] == true,
      currentVersion: currentVersion,
      currentBuildNumber: currentBuild,
      latestVersion: json['latest_version'] as String?,
      latestBuildNumber: json['latest_build_number'] as int?,
      forceUpdate: json['force_update'] == true,
      releaseNotes: json['release_notes'] as String?,
      downloadUrl: json['download_url'] as String?,
      fileSize: json['file_size'] as int?,
      checksumSha256: json['checksum_sha256'] as String?,
    );
  }

  static const none = AppUpdateInfo(
    updateAvailable: false,
    currentVersion: '',
    currentBuildNumber: 0,
  );
}

class UpdateService {
  UpdateService(this._ref);

  final Ref _ref;

  Future<AppUpdateInfo> checkForUpdate() async {
    if (!Platform.isAndroid) return AppUpdateInfo.none;

    final info = await PackageInfo.fromPlatform();
    final dio = _ref.read(dioProvider);

    try {
      final response = await dio.getApi<Map<String, dynamic>>(
        ApiPaths.mobileVersion,
        queryParameters: {
          'platform': 'android',
          'current_version': info.version,
          'build_number': int.tryParse(info.buildNumber) ?? 1,
        },
        parser: (data) => data as Map<String, dynamic>,
      );

      return AppUpdateInfo.fromJson(
        response.data ?? {},
        currentVersion: info.version,
        currentBuild: int.tryParse(info.buildNumber) ?? 1,
      );
    } catch (e) {
      debugPrint('Update check failed: $e');
      return AppUpdateInfo.none;
    }
  }

  Future<void> downloadAndInstall({
    required String downloadUrl,
    required void Function(double progress) onProgress,
  }) async {
    if (!Platform.isAndroid) {
      throw Exception('Update hanya tersedia di Android.');
    }

    if (await Permission.requestInstallPackages.request().isDenied) {
      throw Exception('Izin instalasi aplikasi diperlukan.');
    }

    final dir = await getTemporaryDirectory();
    final savePath = '${dir.path}/creativepos_update.apk';

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 10),
      ),
    );

    await dio.download(
      downloadUrl,
      savePath,
      onReceiveProgress: (received, total) {
        if (total > 0) onProgress(received / total);
      },
    );

    final result = await OpenFilex.open(savePath);
    if (result.type != ResultType.done) {
      throw Exception(result.message);
    }
  }
}

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService(ref);
});

final appUpdateInfoProvider =
    FutureProvider.autoDispose<AppUpdateInfo>((ref) async {
  final server = ref.watch(serverUrlProvider);
  if (server == null || server.isEmpty) return AppUpdateInfo.none;
  return ref.read(updateServiceProvider).checkForUpdate();
});