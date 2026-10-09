import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa/main.dart';

void main() {
  testWidgets('NEXA app renders without Supabase configuration', (tester) async {
    await tester.pumpWidget(const NexaApp(configured: false));
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('NEXA'), findsWidgets);
  });
}
