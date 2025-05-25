// test/widget_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:bepbuddy/main.dart';

void main() {
  testWidgets('App starts on Summary screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BEPBuddyApp());

    // Your initial screen is Summary, so look for text "Summary"
    expect(find.text('Summary'), findsOneWidget);
  });
}