// This is a basic Flutter widget test for the Discovaa app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:discovaa/app/app.dart';
import 'package:discovaa/app/dependency_injection/service_locator.dart';

void main() {
  setUpAll(() async {
    // Initialize dependencies for testing
    await configureDependencies();
  });

  testWidgets('Discovaa app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: DiscovaaApp()));

    // Verify that the app loads successfully
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Discovaa app navigation test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: DiscovaaApp()));

    // Wait for the app to initialize
    await tester.pumpAndSettle();

    // The app should navigate to the initial route (splash screen)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
