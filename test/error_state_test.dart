// Widget test for ErrorState widget
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omniforge_ai/core/errors/failures.dart';
import 'package:omniforge_ai/presentation/widgets/error_state.dart';

void main() {
  group('ErrorState', () {
    testWidgets('displays failure message', (tester) async {
      const failure = NetworkFailure(message: 'No internet connection');
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorState(failure: failure),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No internet connection'), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry provided', (tester) async {
      const failure = ServerFailure();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorState(
              failure: failure,
              onRetry: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('hides retry button when onRetry is null', (tester) async {
      const failure = ServerFailure();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorState(failure: failure),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('shows correct title for NetworkFailure', (tester) async {
      const failure = NetworkFailure();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorState(failure: failure)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Connection Error'), findsOneWidget);
    });

    testWidgets('shows correct title for UnauthorizedFailure', (tester) async {
      const failure = UnauthorizedFailure();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorState(failure: failure)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Authentication Required'), findsOneWidget);
    });
  });

  group('EmptyState', () {
    testWidgets('renders icon and title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'Nothing here yet',
            ),
          ),
        ),
      );
      // `EmptyState` uses `flutter_animate` (`.animate().fadeIn(...)`), which
      // schedules `Timer`s for the animation. Without pumping them out, the
      // test framework's `!timersPending` invariant fires after the widget
      // tree is disposed.
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('Nothing here yet'), findsOneWidget);
    });

    testWidgets('shows action button when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.add,
              title: 'Empty',
              actionLabel: 'Add Item',
              onAction: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Add Item'), findsOneWidget);
    });
  });
}
