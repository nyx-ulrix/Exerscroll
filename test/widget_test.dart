import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exerscroll/main.dart';

void main() {
  testWidgets('ExerScroll loads', (tester) async {
    await tester.pumpWidget(const ExerScrollApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
