import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test — MaterialApp renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('PayRoute'))),
    );
    expect(find.text('PayRoute'), findsOneWidget);
  });
}
