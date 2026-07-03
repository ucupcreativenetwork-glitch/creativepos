import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creativepos_mobile/features/auth/views/server_setup_screen.dart';

void main() {
  testWidgets('ServerSetupScreen shows connection form', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ServerSetupScreen()),
      ),
    );

    expect(find.text('CreativePOS'), findsOneWidget);
    expect(find.text('Hubungkan ke server toko Anda'), findsOneWidget);
    expect(find.text('Alamat Server'), findsOneWidget);
  });
}