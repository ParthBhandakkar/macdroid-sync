import 'package:flutter_test/flutter_test.dart';
import 'package:macdroid/main.dart';

void main() {
  testWidgets('macDroid app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MacDroidApp());
    expect(find.text('macDroid'), findsWidgets);
  });
}
