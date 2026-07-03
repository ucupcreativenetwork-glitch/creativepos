import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'local_database/database_helper.dart';
import 'local_database/offline_queue_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('FlutterError: ${details.exceptionAsString()}');
    }
  };

  await runZonedGuarded(() async {
    await initializeDateFormatting('id_ID');
    await Hive.initFlutter();
    await Hive.openBox('offline_meta');
    await DatabaseHelper.instance.database;
    await OfflineQueueRepository().resetStuckSyncing();

    runApp(
      const ProviderScope(
        child: CreativePosApp(),
      ),
    );
  }, (error, stack) {
    if (kDebugMode) {
      debugPrint('Uncaught error: $error\n$stack');
    }
  });
}