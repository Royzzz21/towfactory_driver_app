// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:tf_driver_app/main.dart';
import 'package:tf_driver_app/core/di/service_locator.dart';
import 'package:tf_driver_app/presentation/router/app_router.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: '.env');
    await initServiceLocator();
  });

  testWidgets('App loads', (WidgetTester tester) async {
    final router = getAppRouter();
    await tester.pumpWidget(MyApp(router: router));
    await tester.pump();

    // Advance past splash delay (1.5s) so no timer is pending when test ends
    await tester.pump(const Duration(seconds: 2));

    // App has built and shows a screen (Scaffold is on splash, login, home)
    expect(find.byType(Scaffold), findsWidgets);
  });
}
