// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:harvestguard_ai/main.dart';
import 'package:harvestguard_ai/services/app_localizations.dart';

void main() {
  testWidgets('language selection opens the login screen', (tester) async {
    final languageController = AppLanguageController();
    await languageController.load();

    await tester.pumpWidget(HarvestGuardAI(languageController: languageController));

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to HarvestGuard AI'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });
}
