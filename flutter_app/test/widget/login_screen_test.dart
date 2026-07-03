import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:creativepos_mobile/core/storage/secure_storage_service.dart';
import 'package:creativepos_mobile/features/auth/views/login_screen.dart';

import '../helpers/widget_test_harness.dart';

void main() {
  testWidgets('LoginScreen shows email and password fields', (tester) async {
    await tester.pumpWidget(
      buildTestApp(
        home: const LoginScreen(),
        storageSeed: {
          StorageKeys.serverUrl: 'http://10.110.1.15:8000',
        },
      ),
    );
    await pumpUntilSettled(tester);

    expect(find.text('Masuk ke akun Anda'), findsOneWidget);
    await tester.ensureVisible(find.byType(FilledButton));
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Ingat saya'), findsOneWidget);
  });
}