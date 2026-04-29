import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:players_info/app/app.dart';

void main() {
  testWidgets('App renderiza MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const Cs2PlayersApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
