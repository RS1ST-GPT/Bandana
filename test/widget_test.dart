import 'package:flutter_test/flutter_test.dart';

import 'package:bandana/main.dart';

void main() {
  testWidgets('App shell renders bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const BandanaApp());

    // Verify bottom navigation bar exists with all 4 destinations.
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Record'), findsOneWidget);
    expect(find.text('Live'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
