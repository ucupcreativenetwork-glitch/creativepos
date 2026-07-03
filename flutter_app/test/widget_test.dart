import 'package:flutter_test/flutter_test.dart';

import 'package:creativepos_mobile/features/auth/views/server_setup_screen.dart';

import 'helpers/widget_test_harness.dart';

void main() {
  testWidgets('ServerSetupScreen shows connection form', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp(home: const ServerSetupScreen()));
    await pumpUntilSettled(tester);

    expect(find.text('CreativePOS'), findsOneWidget);
    expect(find.text('Hubungkan ke server toko Anda'), findsOneWidget);
    expect(find.text('Alamat Server'), findsOneWidget);
  });
}