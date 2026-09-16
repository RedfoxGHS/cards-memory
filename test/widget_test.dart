import 'package:flutter_test/flutter_test.dart';

import 'package:cards_memory/main.dart';

void main() {
  testWidgets('App starts and shows title', (WidgetTester tester) async {
    await tester.pumpWidget(const CardsMemoryApp());
    await tester.pump();
    expect(find.text('Cards Memory'), findsOneWidget);
  });
}
