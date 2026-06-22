// Widget test for Splash Page
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omniforge_ai/presentation/pages/splash_page.dart';

void main() {
  group('SplashPage', () {
    testWidgets('renders app name and tagline', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SplashPage()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('OmniForge AI'), findsOneWidget);
      expect(find.text('One App. Every AI.'), findsOneWidget);
    });

    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SplashPage()));
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('has gradient background', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SplashPage()));
      // SplashPage uses `flutter_animate` (`.animate().fadeIn(...)`), which
      // schedules zero-duration `Timer`s in `_AnimateState._restart`. A bare
      // `pump()` only renders a single frame without advancing the fake clock,
      // so those timers stay pending and trip the framework's
      // `!timersPending` invariant after the widget tree is disposed. Pumping
      // a small duration flushes them (matching the pattern used by the other
      // two SplashPage tests).
      await tester.pump(const Duration(milliseconds: 100));

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(Scaffold),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration;
      expect(decoration, isA<BoxDecoration>());
      expect((decoration as BoxDecoration).gradient, isNotNull);
    });
  });
}
