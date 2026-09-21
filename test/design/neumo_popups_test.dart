// test/design/neumo_popups_test.dart
//
// Same-material popup regression guards:
// - bottom sheets must be transparent so their neumo containers paint alone
//   (the Material default painted a near-white layer under every sheet),
// - dialogs must sit on the neumo tone, not the near-white surface,
// - list tiles must stay transparent so neumo cards show through
//   (a surface fill rendered every settings card near-white).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rexone_mobile/design/design.dart';

void main() {
  group('Neumo popup surfaces', () {
    test('bottom sheet theme is transparent (containers paint themselves)', () {
      for (final theme in [Design.theme.light, Design.theme.dark]) {
        expect(theme.bottomSheetTheme.backgroundColor, Colors.transparent);
        expect(theme.bottomSheetTheme.modalBackgroundColor, Colors.transparent);
        expect(theme.bottomSheetTheme.elevation, 0);
        expect(theme.bottomSheetTheme.modalElevation, 0);
      }
    });

    test('dialog theme uses the same-material neumo tone', () {
      expect(
        Design.theme.light.dialogTheme.backgroundColor,
        Design.colors.day.background,
      );
      expect(
        Design.theme.dark.dialogTheme.backgroundColor,
        Design.colors.night.surface,
      );
    });

    test('osListTile paints transparent by default (no surface fill)', () {
      // On material platforms osListTile renders a Material wrapper; the
      // default fill must be transparent so neumo cards show through.
      final widget = AppListTile.osListTile(
        leading: const Icon(Icons.category_outlined, size: 20),
        title: const Text('Categories'),
      );
      expect(widget, isA<Material>());
      expect((widget as Material).color, Colors.transparent);
    });

    testWidgets('AppListTile stays transparent inside neumo cards', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: Design.theme.light,
          home: Scaffold(
            body: AppCard(
              child: AppListTile(
                leading: const Icon(Icons.category_outlined, size: 20),
                title: const Text('Categories'),
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      final materials = tester.widgetList<Material>(
        find.ancestor(
          of: find.byType(ListTile),
          matching: find.byType(Material),
        ),
      );
      expect(
        materials.any((material) => material.color == Colors.transparent),
        isTrue,
      );
    });
  });
}
