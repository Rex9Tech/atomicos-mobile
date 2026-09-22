// test/design/design_tokens_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rexone_mobile/design/design.dart';

void main() {
  group('Design Constants & Tokens', () {
    test('Badge variants and aliases are defined correctly', () {
      expect(EBadgeVariant.values, contains(EBadgeVariant.info));
      expect(EBadgeVariant.values, contains(EBadgeVariant.success));
      expect(EBadgeVariant.values, contains(EBadgeVariant.warning));
      expect(EBadgeVariant.values, contains(EBadgeVariant.error));
      expect(EBadgeVariant.values, contains(EBadgeVariant.neon));
      expect(EBadgeVariant.values, contains(EBadgeVariant.primary));
      expect(EBadgeVariant.values, contains(EBadgeVariant.secondary));
      expect(EBadgeVariant.values, contains(EBadgeVariant.defaultVariant));

      // Type aliases
      const BadgeType bType = EBadgeVariant.success;
      const BadgeVariant bVariant = EBadgeVariant.success;
      expect(bType, equals(bVariant));
    });

    test('Badge string constants match web tokens', () {
      expect(BadgeVariants.defaultVariant, 'default');
      expect(BadgeVariants.neon, 'neon');
      expect(BadgeVariants.primary, 'primary');
      expect(BadgeVariants.secondary, 'secondary');
      expect(BadgeVariants.success, 'success');
      expect(BadgeVariants.warning, 'warning');
      expect(BadgeVariants.error, 'error');
      expect(BadgeVariants.info, 'info');

      expect(BadgeStatuses.active, 'active');
      expect(BadgeStatuses.expired, 'expired');
      expect(BadgeStatuses.revoked, 'revoked');
      expect(BadgeStatuses.trialing, 'trialing');

      expect(BadgePriorities.critical, 'critical');
      expect(BadgePriorities.urgent, 'urgent');
      expect(BadgePriorities.high, 'high');
      expect(BadgePriorities.medium, 'medium');
      expect(BadgePriorities.normal, 'normal');
      expect(BadgePriorities.low, 'low');

      expect(BadgeRoles.superAdmin, 'super_admin');
      expect(BadgeRoles.admin, 'admin');
    });

    test('Typography token classes are fully constantized and defined', () {
      expect(AppFontSizes.h1, 32.0);
      expect(AppFontSizes.h2, 28.0);
      expect(AppFontSizes.h3, 24.0);
      expect(AppFontSizes.h4, 20.0);
      expect(AppFontSizes.bodyLarge, 16.0);
      expect(AppFontSizes.bodyMedium, 14.0);
      expect(AppFontSizes.bodySmall, 12.0);
      expect(AppFontSizes.caption, 12.0);
      expect(AppFontSizes.button, 16.0);

      expect(AppFontWeights.light, FontWeight.w300);
      expect(AppFontWeights.regular, FontWeight.w400);
      expect(AppFontWeights.medium, FontWeight.w500);
      expect(AppFontWeights.semiBold, FontWeight.w600);
      expect(AppFontWeights.bold, FontWeight.w700);

      expect(AppLineHeights.tight, 1.2);
      expect(AppLineHeights.snug, 1.3);
      expect(AppLineHeights.normal, 1.4);
      expect(AppLineHeights.relaxed, 1.5);

      expect(AppLetterSpacings.tight, -0.5);
      expect(AppLetterSpacings.normal, 0.0);
      expect(AppLetterSpacings.wide, 0.5);
      expect(AppLetterSpacings.wider, 1.2);
    });

    test(
      'AppTypography getters produce expected styles with correct token values',
      () {
        expect(Design.typo.headline1.fontSize, AppFontSizes.h1);
        expect(Design.typo.headline1.fontWeight, AppFontWeights.bold);
        expect(Design.typo.headline1.height, AppLineHeights.tight);
        expect(Design.typo.headline1.letterSpacing, AppLetterSpacings.tight);

        expect(Design.typo.bodyLarge.fontSize, AppFontSizes.bodyLarge);
        expect(Design.typo.bodyLarge.fontWeight, AppFontWeights.regular);
        expect(Design.typo.bodyLarge.height, AppLineHeights.relaxed);

        expect(Design.typo.button.fontSize, AppFontSizes.button);
        expect(Design.typo.button.fontWeight, AppFontWeights.semiBold);
        expect(Design.typo.button.height, AppLineHeights.tight);
        expect(Design.typo.button.letterSpacing, AppLetterSpacings.wide);

        expect(Design.typo.caption.fontSize, AppFontSizes.caption);
        expect(Design.typo.caption.fontWeight, AppFontWeights.regular);
        expect(Design.typo.caption.height, AppLineHeights.normal);
      },
    );

    testWidgets('neumo uses raised dual shadows', (tester) async {
      late List<BoxShadow> raised;
      late Color fill;

      await tester.pumpWidget(
        MaterialApp(
          theme: Design.theme.light,
          home: Builder(
            builder: (context) {
              raised = context.colors.neumoShadow;
              fill = context.colors.neumo;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(raised, hasLength(2));

      // Classic neumo: same clay as the page — dual shadows carry the depth.
      expect(fill, equals(Design.theme.light.scaffoldBackgroundColor));

      // White highlight top-left; cool shade bottom-right.
      expect(raised[0].offset.dx, lessThan(0));
      expect(raised[0].offset.dy, lessThan(0));
      expect(raised[1].offset.dx, greaterThan(0));
      expect(raised[1].offset.dy, greaterThan(0));
    });

    testWidgets('inset shadows mirror the raised pair', (tester) async {
      late List<BoxShadow> inset;

      await tester.pumpWidget(
        MaterialApp(
          theme: Design.theme.light,
          home: Builder(
            builder: (context) {
              inset = context.colors.neumoInsetShadow;
              return const SizedBox();
            },
          ),
        ),
      );

      // Shade bleeds in from the top-left, highlight from the bottom-right —
      // the opposite of a raised surface, which is what reads as a well.
      expect(inset.first.offset.dx, greaterThan(0));
      expect(inset.first.offset.dy, greaterThan(0));
      expect(inset.last.offset.dx, lessThan(0));
      expect(inset.last.offset.dy, lessThan(0));
      expect(inset.last.color, equals(Colors.white.withValues(alpha: 0.9)));
    });

    testWidgets('inset surface paints shadow inside its own bounds', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: Design.theme.light,
          home: Scaffold(
            body: Center(
              child: AppNeumoSurface(
                depth: ENeumoDepth.inset,
                width: 200,
                height: 80,
                child: const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );

      // A foregroundDecoration is what clips the shadow to the shape; a plain
      // boxShadow would spill outside and read as elevation instead.
      final box = tester.widget<Container>(
        find.descendant(
          of: find.byType(AppNeumoSurface),
          matching: find.byType(Container),
        ),
      );
      expect(box.foregroundDecoration, isNotNull);
      expect(tester.takeException(), isNull);
    });
  });
}
