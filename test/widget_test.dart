// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:shop/main.dart';
import 'package:shop/services/marketplace_state.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('Arabic marketplace opens on onboarding',
      (WidgetTester tester) async {
    await tester.pumpWidget(MarketplaceScope(
      notifier: MarketplaceState(),
      child: const MyApp(),
    ));
    await tester.pump();

    expect(find.text('تخطي'), findsOneWidget);
  });
}
