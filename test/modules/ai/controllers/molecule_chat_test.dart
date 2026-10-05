// test/modules/ai/controllers/molecule_chat_test.dart
//
// One chat per molecule: asking about a molecule opens (or reuses) that
// molecule's own conversation; plain rooms drop any stale molecule context.
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/models/models.dart';
import 'package:rexone_mobile/modules/ai/ai.dart';
import 'package:rexone_mobile/modules/home/data/models/models.dart';
import 'package:rexone_mobile/modules/home/services/home.service.dart';
import 'package:rexone_mobile/services/services.dart';

import '../../../mocks/test_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAiService fakeAi;
  late AiController controller;

  AiRoomModel room(
    String id,
    String title, {
    String? categoryId,
    int messageCount = 0,
  }) => AiRoomModel(
    id: id,
    title: title,
    messageCount: messageCount,
    createdAt: '2026-10-06T00:00:00Z',
    updatedAt: '2026-10-06T00:00:00Z',
    processing: false,
    categoryId: categoryId,
  );

  setUp(() {
    Get.testMode = true;
    fakeAi = FakeAiService();
    Get.put<AiService>(fakeAi);
    Get.put<SpeechService>(FakeSpeechService());
    Get.put<PermissionService>(FakePermissionService());
    Get.put<RecordingService>(FakeRecordingService());
    Get.put<HomeService>(FakeHomeService());
    Get.put<CategoryService>(FakeCategoryService());
    controller = Get.put(AiController());
  });

  tearDown(Get.reset);

  test('openMoleculeChat asks the server for the molecule room and opens it',
      () async {
    const molecule = CategoryModel(id: 'cat-1', name: 'General');
    fakeAi.createRoomResponse = ApiResponse.success(
      message: 'ok',
      statusCode: 201,
      data: room('room-cat-1', 'General', categoryId: 'cat-1'),
    );

    await controller.openMoleculeChat(molecule);
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(fakeAi.lastCreateRoomRequest?.categoryId, 'cat-1');
    expect(controller.currentRoomId.value, 'room-cat-1');
    expect(controller.contextMolecule.value?.id, 'cat-1');
    expect(controller.currentMoleculeName.value, 'General');
  });

  test('selectRoom clears the molecule context for plain chats', () async {
    controller.contextMolecule.value =
        const CategoryModel(id: 'cat-9', name: 'Stale');

    controller.selectRoom(room('room-plain', 'Plain chat'));
    await Future<void>.delayed(Duration.zero);

    expect(controller.currentRoomId.value, 'room-plain');
    expect(controller.contextMolecule.value, isNull);
    expect(controller.currentMoleculeName.value, isNull);
  });

  test('selectRoom re-pins the molecule for a molecule room', () async {
    controller.selectRoom(room('room-cat-2', 'Nova', categoryId: 'cat-2'));
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(controller.contextMolecule.value?.id, 'cat-2');
    expect(controller.currentMoleculeName.value, 'Nova');
  });
}
