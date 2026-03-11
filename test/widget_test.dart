import 'package:flutter_test/flutter_test.dart';

import 'package:ayeyo/app/ayeyo_app.dart';

void main() {
  testWidgets('app shell loads home route', (WidgetTester tester) async {
    await tester.pumpWidget(const AyeyoApp());
    await tester.pumpAndSettle();

    expect(find.text('Ayeyo Delivery'), findsWidgets);
    expect(find.text('Browse restaurants'), findsOneWidget);
  });
}
