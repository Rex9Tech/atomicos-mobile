// TEMP preview harness — renders affected popup surfaces to goldens so the
// visual result can be reviewed. Not part of the permanent suite; delete
// after review.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rexone_mobile/design/design.dart';

Widget _pill(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  final colors = context.colors;
  final typo = context.typo;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: colors.neumo,
      gradient: colors.neumoGradient,
      borderRadius: BorderRadius.circular(999),
      boxShadow: colors.neumoShadowSoft,
    ),
    child: Row(
      children: [
        Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            color: colors.neumo,
            gradient: colors.neumoGradient,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: colors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: typo.labelLarge.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                subtitle,
                style: typo.caption.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

void main() {
  testWidgets('popup surfaces preview (light + dark)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final themes = <String, ThemeData>{
      'light': Design.theme.light,
      'dark': Design.theme.dark,
    };

    for (final entry in themes.entries) {
      final name = entry.key;
      await tester.pumpWidget(
        MaterialApp(
          theme: entry.value,
          home: Builder(
            builder: (context) {
              final colors = context.colors;
              return Scaffold(
                backgroundColor: colors.neumo,
                body: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppCard(
                          child: Column(
                            children: [
                              AppListTile(
                                leading: const Icon(
                                  Icons.palette_outlined,
                                  size: 20,
                                ),
                                title: const Text('Appearance'),
                                onTap: () {},
                              ),
                              AppListTile(
                                leading: const Icon(
                                  Icons.category_outlined,
                                  size: 20,
                                ),
                                title: const Text('Categories'),
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _pill(
                          context,
                          icon: Icons.mic_none_rounded,
                          title: 'Capture now',
                          subtitle: 'Record and transcribe',
                        ),
                        const SizedBox(height: 12),
                        _pill(
                          context,
                          icon: Icons.upload_file_outlined,
                          title: 'Import',
                          subtitle: 'Audio, video or document',
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => showModalBottomSheet<void>(
                            context: context,
                            builder: (_) => Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: colors.neumo,
                                gradient: colors.neumoGradient,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: colors.neumoShadow,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'New Atom',
                                    style: context.typo.headline4.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _pill(
                                    context,
                                    icon: Icons.mic_none_rounded,
                                    title: 'Capture now',
                                    subtitle: 'Record and transcribe',
                                  ),
                                  const SizedBox(height: 10),
                                  _pill(
                                    context,
                                    icon: Icons.edit_note_outlined,
                                    title: 'Write a note',
                                    subtitle: 'Start from scratch',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          child: const Text('Open sheet'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              title: const Text('Rename'),
                              content: const Text('My atom'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(),
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          ),
                          child: const Text('Open dialog'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/popup_base_$name.png'),
      );

      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/popup_sheet_$name.png'),
      );
      await tester.tapAt(const Offset(180, 60));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/popup_dialog_$name.png'),
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    }
  });
}
