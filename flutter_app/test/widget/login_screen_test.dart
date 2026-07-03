import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:creativepos_mobile/features/auth/views/login_screen.dart';

void main() {
  testWidgets('LoginScreen shows email and password fields', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Masuk ke akun Anda'), findsOneWidget);
    await tester.ensureVisible(find.byType(FilledButton));
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Ingat saya'), findsOneWidget);
  });
}