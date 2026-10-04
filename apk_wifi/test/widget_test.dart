import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:apk_wifi/main.dart';

void main() {
  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SimaNetApp());

    // Verify that login elements exist.
    expect(find.text('Sign in to your\nAccount'), findsOneWidget);
    expect(find.byIcon(Icons.fingerprint), findsOneWidget);
  });
}
