import 'package:flutter_test/flutter_test.dart';

import 'package:kawach/main.dart';

void main() {
  testWidgets('Kawach splash renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KawachApp());
    await tester.pumpAndSettle();

    expect(find.text('Kawach'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
