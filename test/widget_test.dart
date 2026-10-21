import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macdroid/main.dart';
import 'package:macdroid/services/macdroid_state.dart';

void main() {
  testWidgets('macDroid app smoke test', (WidgetTester tester) async {
    final state = MacDroidState(autoConnect: false);
    await tester.pumpWidget(
      MaterialApp(
        home: MacDroidShell(state: state),
      ),
    );
    expect(find.text('macDroid'), findsWidgets);
    state.dispose();
  });
}
