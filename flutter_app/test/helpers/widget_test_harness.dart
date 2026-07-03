import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creativepos_mobile/core/storage/secure_storage_service.dart';
import 'package:creativepos_mobile/features/auth/providers/auth_providers.dart';

Widget buildTestApp({
  required Widget home,
  List<Override> overrides = const [],
  Map<String, String>? storageSeed,
}) {
  return ProviderScope(
    overrides: [
      secureStorageProvider.overrideWithValue(
        SecureStorageService.memory(initial: storageSeed),
      ),
      ...overrides,
    ],
    child: MaterialApp(home: home),
  );
}

Future<void> pumpUntilSettled(WidgetTester tester, {int maxPumps = 20}) async {
  for (var i = 0; i < maxPumps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (!tester.binding.hasScheduledFrame) {
      break;
    }
  }
  await tester.pump();
}