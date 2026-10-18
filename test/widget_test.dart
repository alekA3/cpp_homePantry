// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:home_pantry/main.dart';

void main() {
  testWidgets('Google sign-in option is available on login and registration', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PantryApp());

    expect(find.text('Увійти через Google'), findsOneWidget);
    await tester.ensureVisible(find.text('Немає акаунта? Зареєструватися'));
    await tester.tap(find.text('Немає акаунта? Зареєструватися'));
    await tester.pumpAndSettle();

    expect(find.text('Увійти через Google'), findsOneWidget);
    expect(find.text('Зареєструватися'), findsOneWidget);
  });

  testWidgets('Top-right account control opens profile inside the app shell', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PantryApp());

    await tester.tap(find.text('Увійти'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Олександр Половенко'));
    await tester.pumpAndSettle();

    expect(find.text('Профіль'), findsOneWidget);
    expect(find.text('ЗМІНА ПАРОЛЯ'), findsOneWidget);
    expect(find.text('Комора'), findsOneWidget);
  });
}
