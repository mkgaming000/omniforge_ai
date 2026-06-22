// Widget test for GlassCard
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omniforge_ai/presentation/widgets/glass_card.dart';

void main() {
  group('GlassCard', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassCard(
              child: Text('Test content'),
            ),
          ),
        ),
      );
      expect(find.text('Test content'), findsOneWidget);
    });

    testWidgets('applies blur filter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassCard(blur: 30, child: SizedBox.shrink()),
          ),
        ),
      );
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('uses custom radius', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassCard(
              radius: 8,
              child: SizedBox.shrink(),
            ),
          ),
        ),
      );
      final clip = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clip.borderRadius, equals(BorderRadius.circular(8)));
    });

    testWidgets('respects padding property', (tester) async {
      const padding = EdgeInsets.all(24);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassCard(
              padding: padding,
              child: Text('X'),
            ),
          ),
        ),
      );
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(ClipRRect),
          matching: find.byType(Container),
        ),
      );
      expect(container.padding, equals(padding));
    });
  });
}
