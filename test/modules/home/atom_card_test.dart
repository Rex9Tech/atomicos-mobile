// test/modules/home/atom_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/modules/home/data/models/atom.model.dart';
import 'package:rexone_mobile/modules/home/pages/widgets/atom_card.dart';

void main() {
  testWidgets('atom card truncates the body and caps the title', (
    tester,
  ) async {
    final longBody = List.generate(120, (i) => 'word$i').join(' ');
    final longTitle =
        'A very long atom title that should never exceed two lines of '
        'space in the card layout no matter how much text is passed in';

    final atom = AtomModel(
      id: 'a1',
      title: longTitle,
      source: 'asset',
      status: 'completed',
      note: longBody,
      createdAt: '2026-09-18T00:00:00Z',
      updatedAt: '2026-09-18T00:00:00Z',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: Design.theme.light,
        home: Scaffold(
          body: SingleChildScrollView(child: AtomCard(atom: atom)),
        ),
      ),
    );

    // Body: truncated well before the end of the note, with an ellipsis.
    final rendered = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((text) => text.text.toPlainText())
        .join('\n');
    expect(rendered.contains('word119'), isFalse);
    expect(rendered.contains('…'), isTrue);

    // Title: capped to two lines with an ellipsis.
    final titleWidget = tester.widget<Text>(find.text(longTitle));
    expect(titleWidget.maxLines, 2);
    expect(titleWidget.overflow, TextOverflow.ellipsis);
  });

  testWidgets('short bodies render in full', (tester) async {
    final atom = AtomModel(
      id: 'a2',
      title: 'Short note',
      source: 'note',
      status: 'draft',
      note: 'Just a short summary.',
      createdAt: '2026-09-18T00:00:00Z',
      updatedAt: '2026-09-18T00:00:00Z',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: Design.theme.light,
        home: Scaffold(
          body: SingleChildScrollView(child: AtomCard(atom: atom)),
        ),
      ),
    );

    expect(find.textContaining('Just a short summary.'), findsOneWidget);
  });
}
