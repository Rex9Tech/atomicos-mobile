// test/modules/ai/controllers/molecule_context_test.dart
//
// Molecule chat context: the assistant must know how many atoms the molecule
// holds and receive a digest of EVERY atom — atoms past the old character
// budget used to silently fall off the context entirely.
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/constants/constants.dart';
import 'package:rexone_mobile/models/models.dart';
import 'package:rexone_mobile/modules/ai/ai.dart';
import 'package:rexone_mobile/modules/home/data/models/models.dart';
import 'package:rexone_mobile/modules/home/services/home.service.dart';
import 'package:rexone_mobile/services/services.dart';

import '../../../mocks/test_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAiService fakeAi;
  late FakeHomeService fakeHome;
  late AiController controller;

  AtomModel atom(String id, String title, {String note = ''}) => AtomModel(
    id: id,
    title: title,
    source: 'note',
    status: 'ready',
    note: note,
    createdAt: '2026-10-06T00:00:00Z',
    updatedAt: '2026-10-06T00:00:00Z',
  );

  Future<String> contextFor(String moleculeId, String prompt) async {
    controller.contextMolecule.value = CategoryModel(
      id: moleculeId,
      name: 'Molecule $moleculeId',
    );
    await controller.sendMessage(prompt);
    return fakeAi.lastChatRequest?.context ?? '';
  }

  setUp(() {
    Get.testMode = true;
    fakeAi = FakeAiService();
    fakeHome = FakeHomeService();
    Get.put<AiService>(fakeAi);
    Get.put<SpeechService>(FakeSpeechService());
    Get.put<PermissionService>(FakePermissionService());
    Get.put<RecordingService>(FakeRecordingService());
    Get.put<HomeService>(fakeHome);
    Get.put<CategoryService>(FakeCategoryService());
    controller = Get.put(AiController());
    fakeAi.chatResponse = ApiResponse.success(
      message: 'Queued',
      statusCode: 200,
      data: AiMessageModel(
        id: 'msg_1',
        role: EChatRole.assistant.name,
        content: 'ok',
        roomId: 'room-1',
        createdAt: '2026-10-06T00:00:00Z',
      ),
    );
  });

  tearDown(Get.reset);

  test('the context states the molecule\'s total atom count', () async {
    fakeHome.pages.add([atom('a1', 'Alpha', note: 'alpha note')]);

    final context = await contextFor('cat-1', 'What is this molecule about?');

    expect(context, contains('Molecule cat-1'));
    expect(context, contains('contains 1 atom;'), reason: 'count missing');
    expect(context, contains('Alpha [note]: alpha note'));
    expect(fakeHome.requestedCategoryIds, contains('cat-1'));
  });

  test('EVERY atom appears even when their content exceeds the budget',
      () async {
    final atoms = [
      for (var i = 1; i <= 12; i++) atom('a$i', 'Atom $i', note: 'x' * 4000),
    ];
    fakeHome.pages.add(atoms);

    final context = await contextFor('cat-2', 'Summarize the molecule');

    expect(context, contains('contains 12 atoms;'));
    for (var i = 1; i <= 12; i++) {
      expect(context, contains('Atom $i [note]'), reason: 'atom $i missing');
    }
    // Every atom kept real content, not just its title — including the last
    // one, which the old budget silently cut off.
    expect(context, contains('Atom 1 [note]: xxx'));
    expect(context, contains('Atom 12 [note]: xxx'));
    // The digest stays inside the shared budget (+ wrapper + small slack).
    expect(context.length, lessThan(26000));
  });

  test('short molecules keep their full contents (no trimming)', () async {
    fakeHome.pages.add([
      atom('a1', 'One', note: 'short note one'),
      atom('a2', 'Two', note: 'short note two'),
    ]);

    final context = await contextFor('cat-3', 'Hi');

    expect(context, contains('short note one'));
    expect(context, contains('short note two'));
    expect(context, isNot(contains('…')));
  });

  test('a molecule with no atoms says so explicitly', () async {
    final context = await contextFor('cat-4', 'Hi');
    expect(context, contains('0 atoms'));
  });

  test('when the fetch is capped, the context says how many exist', () async {
    fakeHome.pages.addAll([
      [atom('a1', 'One', note: 'n1'), atom('a2', 'Two', note: 'n2')],
      [atom('a3', 'Three', note: 'n3')],
    ]);

    final context = await contextFor('cat-5', 'Hi');

    // Page one carried 2 atoms but the molecule holds 5? No — 3 across the
    // two pages; the first page can't know about the second, so the header
    // must state the true total from pagination.
    expect(context, contains('contains 3 atoms in total;'));
    expect(context, contains('the first 2 of them'));
    expect(context, contains('One [note]'));
    expect(context, contains('Two [note]'));
  });

  test('small atoms keep full text while large ones share the leftover',
      () async {
    fakeHome.pages.add([
      atom('a1', 'Tiny', note: 'tiny note'),
      atom('a2', 'Big1', note: 'y' * 4000),
      atom('a3', 'Big2', note: 'y' * 4000),
      atom('a4', 'Big3', note: 'y' * 4000),
    ]);

    final context = await contextFor('cat-6', 'Hi');

    // The tiny atom is not sacrificed for the big ones…
    expect(context, contains('Tiny [note]: tiny note'));
    // …and each big atom still carries a substantial slice.
    expect(RegExp(r'Big1 \[note\]: y{1000}').hasMatch(context), isTrue);
    expect(RegExp(r'Big3 \[note\]: y{1000}').hasMatch(context), isTrue);
  });
}
