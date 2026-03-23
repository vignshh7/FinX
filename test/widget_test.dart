import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finx/main.dart';

void main() {
  testWidgets('FinX app boots and shows loading UI', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Depending on async theme/auth initialization, the app can render either
    // the immediate loading shell or the splash screen, both with a progress indicator.
    expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
  });
}
