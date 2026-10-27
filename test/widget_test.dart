import 'package:flutter_test/flutter_test.dart';
import 'package:ostadchi/main.dart';

void main() {
  testWidgets('home page renders app title', (WidgetTester tester) async {
    await tester.pumpWidget(const OstadchiApp());
    expect(find.text('استادچی'), findsOneWidget);
    expect(find.text('دسته‌بندی خدمات'), findsOneWidget);
  });
}
