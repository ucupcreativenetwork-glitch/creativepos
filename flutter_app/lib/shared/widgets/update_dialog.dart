import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/update_service.dart';

Future<void> showUpdateDialog(
  BuildContext context,
  WidgetRef ref,
  AppUpdateInfo info,
) async {
  var downloading = false;
  var progress = 0.0;
  String? error;

  await showDialog<void>(
    context: context,
    barrierDismissible: !info.forceUpdate,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => PopScope(
        canPop: !info.forceUpdate && !downloading,
        child: AlertDialog(
          icon: const Icon(Icons.system_update, size: 40),
          title: Text(
            info.forceUpdate ? 'Update Wajib' : 'Update Tersedia',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Versi ${info.latestVersion} (build ${info.latestBuildNumber}) '
                'siap diunduh.',
              ),
              if (info.releaseNotes != null &&
                  info.releaseNotes!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  info.releaseNotes!,
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
              ],
              if (downloading) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 8),
                Text('${(progress * 100).toStringAsFixed(0)}%'),
              ],
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              ],
            ],
          ),
          actions: [
            if (!info.forceUpdate && !downloading)
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Nanti'),
              ),
            FilledButton(
              onPressed: downloading
                  ? null
                  : () async {
                      setState(() {
                        downloading = true;
                        error = null;
                        progress = 0;
                      });
                      try {
                        await ref.read(updateServiceProvider).downloadAndInstall(
                              downloadUrl: info.downloadUrl!,
                              onProgress: (p) => setState(() => progress = p),
                            );
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setState(() {
                          downloading = false;
                          error = e.toString();
                        });
                      }
                    },
              child: Text(downloading ? 'Mengunduh...' : 'Update Sekarang'),
            ),
          ],
        ),
      ),
    ),
  );
}