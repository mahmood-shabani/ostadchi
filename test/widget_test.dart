import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ostadchi/app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'selected_city': 'آبادان'});
  });

  testWidgets('home shell shows navigation and marketplace categories',
      (WidgetTester tester) async {
    await tester.pumpWidget(const OstadchiApp());
    await tester.pumpAndSettle();

    expect(find.text('استادچی'), findsOneWidget);
    expect(find.text('خانه'), findsOneWidget);
    expect(find.text('جست‌وجو'), findsOneWidget);
    expect(find.text('درخواست‌ها'), findsOneWidget);
    expect(find.text('حساب من'), findsOneWidget);
    expect(find.text('دسته‌بندی خدمات'), findsOneWidget);
  });

  testWidgets('search navigation responds to tap', (WidgetTester tester) async {
    await tester.pumpWidget(const OstadchiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('جست‌وجو').last);
    await tester.pumpAndSettle();

    expect(find.text('جست‌وجوی استادکار'), findsOneWidget);
  });
}
