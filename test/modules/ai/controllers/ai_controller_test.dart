// test/modules/ai/controllers/ai_controller_test.dart
import 'dart:async';

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
  late FakeSpeechService fakeSpeech;
  late FakePermissionService fakePermissions;
  late FakeRecordingService fakeRecording;
  late FakeHomeService fakeHome;
  late AiController controller;

  AtomModel atomModel(String id, String title) => AtomModel(
    id: id,
    title: title,
    source: 'note',
    status: 'completed',
    createdAt: '2026-09-01T00:00:00Z',
    updatedAt: '2026-09-01T00:00:00Z',
  );

  setUp(() {
    Get.testMode = true;
    fakeAi = FakeAiService();
    fakeSpeech = FakeSpeechService();
    fakePermissions = FakePermissionService();
    fakeRecording = FakeRecordingService();
    fakeHome = FakeHomeService();

    Get.put<AiService>(fakeAi);
    Get.put<SpeechService>(fakeSpeech);
    Get.put<PermissionService>(fakePermissions);
    Get.put<RecordingService>(fakeRecording);
    Get.put<HomeService>(fakeHome);

    controller = Get.put(AiController());
  });

  tearDown(() {
    Get.reset();
  });

  group('AiController - History & Messages', () {
    test('loadHistory provides default welcome greeting when history is empty', () async {
      fakeAi.historyResponse = const PaginatedResponse<AiMessageModel>(
        records: [],
        message: 'OK',
        statusCode: 200,
        success: true,
      );

      await controller.loadHistory();

      expect(controller.messages.length, equals(1));
      expect(controller.messages.first.id, equals('welcome'));
      expect(controller.messages.first.role, equals(EChatRole.assistant.name));
    });

    test('loadHistory loads message history and updates currentRoomId', () async {
      final mockMessages = [
        AiMessageModel(
          id: 'msg_1',
          role: EChatRole.user.name,
          content: 'Hello AI',
          roomId: 'room_abc',
          createdAt: DateTime.now().toIso8601String(),
        ),
        AiMessageModel(
          id: 'msg_2',
          role: EChatRole.assistant.name,
          content: 'Hello! How can I help?',
          roomId: 'room_abc',
          createdAt: DateTime.now().toIso8601String(),
        ),
      ];

      fakeAi.historyResponse = PaginatedResponse<AiMessageModel>(
        records: mockMessages,
        message: 'OK',
        statusCode: 200,
        success: true,
      );

      await controller.loadHistory('room_abc');

      expect(controller.messages.length, equals(2));
      expect(controller.currentRoomId.value, equals('room_abc'));
      expect(controller.isProcessing.value, isFalse);
    });

    test('sendMessage creates optimistic message and posts to chat service', () async {
      fakeAi.chatResponse = ApiResponse.success(
        message: 'Queued',
        statusCode: 200,
        data: AiMessageModel(
          id: 'msg_1',
          role: EChatRole.assistant.name,
          content: 'Hello',
          roomId: 'room_123',
          createdAt: DateTime.now().toIso8601String(),
        ),
      );

      await controller.sendMessage('Test message');

      expect(controller.messages.any((m) => m.content == 'Test message'), isTrue);
      expect(controller.currentRoomId.value, equals('room_123'));
    });

    test('sendMessage ignores whitespace-only message', () async {
      final countBefore = controller.messages.length;

      await controller.sendMessage('   ');

      expect(controller.messages.length, equals(countBefore));
    });
  });

  group('AiController - Room Management', () {
    test('loadRooms populates rooms list', () async {
      final mockRooms = [
        AiRoomModel(
          id: 'r_1',
          title: 'First Chat',
          messageCount: 5,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
          processing: false,
        ),
      ];

      fakeAi.roomsResponse = PaginatedResponse<AiRoomModel>(
        records: mockRooms,
        message: 'OK',
        statusCode: 200,
        success: true,
      );

      await controller.loadRooms();

      expect(controller.rooms.length, equals(1));
      expect(controller.rooms.first.id, equals('r_1'));
      expect(controller.rooms.first.title, equals('First Chat'));
    });

    test('selectRoom updates room observables and triggers history reload', () {
      final room = AiRoomModel(
        id: 'r_selected',
        title: 'Project Discussion',
        messageCount: 10,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        processing: false,
      );

      controller.selectRoom(room);

      expect(controller.currentRoomId.value, equals('r_selected'));
      expect(controller.currentRoomTitle.value, equals('Project Discussion'));
      expect(
        controller.entryMode.value,
        equals('ask'),
        reason: 'selecting a conversation must open the chat, not details',
      );
      expect(
        controller.askStage.value,
        equals('prompt_result'),
        reason:
            'selecting a conversation must show the thread, not the '
            'new-conversation landing',
      );
    });

    test('room-less loadHistory targets the currently open room', () async {
      controller.currentRoomId.value = 'r_current';
      fakeAi.historyResponse = PaginatedResponse<AiMessageModel>(
        records: [
          AiMessageModel(
            id: 'm1',
            role: EChatRole.assistant.name,
            content: 'hello',
            roomId: 'r_current',
            createdAt: DateTime.now().toIso8601String(),
          ),
        ],
        message: 'OK',
        statusCode: 200,
        success: true,
      );

      await controller.loadHistory();

      expect(
        fakeAi.lastHistoryRoomId,
        equals('r_current'),
        reason: 'a room-less load must not fall back to a different room',
      );
      expect(controller.messages.single.content, equals('hello'));
    });

    test('stale history responses are dropped when a newer load wins', () async {
      final msgA = AiMessageModel(
        id: 'm_a',
        role: EChatRole.assistant.name,
        content: 'A',
        roomId: 'room_a',
        createdAt: DateTime.now().toIso8601String(),
      );
      final msgB = AiMessageModel(
        id: 'm_b',
        role: EChatRole.assistant.name,
        content: 'B',
        roomId: 'room_b',
        createdAt: DateTime.now().toIso8601String(),
      );

      fakeAi.historyResponse = PaginatedResponse<AiMessageModel>(
        records: [msgA],
        message: 'OK',
        statusCode: 200,
        success: true,
      );
      fakeAi.delayFirstHistory = Completer<void>();

      final firstLoad = controller.loadHistory('room_a'); // parked in flight
      await Future<void>.delayed(Duration.zero);

      fakeAi.historyResponse = PaginatedResponse<AiMessageModel>(
        records: [msgB],
        message: 'OK',
        statusCode: 200,
        success: true,
      );
      await controller.loadHistory('room_b'); // the newer load finishes first
      expect(controller.messages.single.content, equals('B'));

      fakeAi.delayFirstHistory!.complete(); // room_a's response arrives late
      await firstLoad;
      await Future<void>.delayed(Duration.zero);
      expect(
        controller.messages.single.content,
        equals('B'),
        reason: 'the late room_a response must not overwrite room_b',
      );
    });

    test('createNewRoom creates and prepends room to list', () async {
      fakeAi.createRoomResponse = ApiResponse.success(
        message: 'Created',
        statusCode: 201,
        data: AiRoomModel(
          id: 'r_new',
          title: 'Custom Topic',
          messageCount: 0,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
          processing: false,
        ),
      );

      await controller.createNewRoom('Custom Topic');

      expect(controller.rooms.any((r) => r.id == 'r_new'), isTrue);
      expect(controller.currentRoomId.value, equals('r_new'));
    });

    test('deleteRoom removes room from rooms list and resets currentRoomId if deleted', () async {
      final room = AiRoomModel(
        id: 'r_del',
        title: 'To Delete',
        messageCount: 1,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        processing: false,
      );

      controller.rooms.assignAll([room]);
      controller.currentRoomId.value = 'r_del';

      fakeAi.deleteRoomResponse = ApiResponse.success(message: 'Deleted', statusCode: 200);

      await controller.deleteRoom('r_del');

      expect(controller.rooms, isEmpty);
      expect(controller.currentRoomId.value, isNull);
    });

    test('renameRoom updates room title in list and updates currentRoomTitle if matching', () async {
      final room = AiRoomModel(
        id: 'r_ren',
        title: 'Original Title',
        messageCount: 1,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        processing: false,
      );

      controller.rooms.assignAll([room]);
      controller.currentRoomId.value = 'r_ren';
      controller.currentRoomTitle.value = 'Original Title';

      fakeAi.renameRoomResponse = ApiResponse.success(
        message: 'Renamed',
        statusCode: 200,
        data: room.copyWith(title: 'Updated Title'),
      );

      await controller.renameRoom('r_ren', 'Updated Title');

      expect(controller.rooms.first.title, equals('Updated Title'));
      expect(controller.currentRoomTitle.value, equals('Updated Title'));
    });

    test('sendMessage extracts roomId from response.meta when provided', () async {
      fakeAi.chatResponse = ApiResponse.success(
        message: 'Queued',
        statusCode: 200,
        data: AiMessageModel(
          id: 'msg_meta',
          role: EChatRole.assistant.name,
          content: 'Meta response',
          roomId: '',
          createdAt: DateTime.now().toIso8601String(),
        ),
        meta: {AiKeys.roomId: 'room_from_meta'},
      );

      await controller.sendMessage('Check meta room id');

      expect(controller.currentRoomId.value, equals('room_from_meta'));
    });

    test('sendMessage replaces optimistic message with returned chunked messages', () async {
      final chunk1 = AiMessageModel(
        id: 'msg_c1',
        role: EChatRole.user.name,
        content: 'Part 1 of long prompt',
        roomId: 'room_chunks',
        createdAt: DateTime.now().toIso8601String(),
      );
      final chunk2 = AiMessageModel(
        id: 'msg_c2',
        role: EChatRole.user.name,
        content: 'Part 2 of long prompt',
        roomId: 'room_chunks',
        createdAt: DateTime.now().toIso8601String(),
      );

      fakeAi.chatResponse = ApiResponse.success(
        message: 'Queued',
        statusCode: 200,
        data: chunk1,
        meta: {
          AiKeys.roomId: 'room_chunks',
          AiKeys.messages: [chunk1.toJson(), chunk2.toJson()],
        },
      );

      await controller.sendMessage('Part 1 of long promptPart 2 of long prompt');

      expect(controller.messages.length, equals(2));
      expect(controller.messages[0].id, equals('msg_c1'));
      expect(controller.messages[1].id, equals('msg_c2'));
      expect(controller.currentRoomId.value, equals('room_chunks'));
    });
  });

  group('AiController - Molecule context', () {
    test(
      'a molecule context carries every atom of the molecule with the question',
      () async {
        fakeHome.pages.addAll([
          [atomModel('m1', 'Standup notes'), atomModel('m2', 'Launch plan')],
        ]);

        controller.attachContextMolecule(
          const CategoryModel(id: 'mol-1', name: 'Work'),
        );

        // One context at a time — a molecule replaces any pinned atom.
        expect(controller.contextAtom.value, isNull);
        expect(controller.contextMolecule.value?.id, 'mol-1');

        await controller.sendMessage('Summarise my work molecule');

        final request = fakeAi.lastChatRequest;
        expect(request, isNotNull);
        expect(request!.context, isNotNull);
        expect(request.context, contains('molecule "Work"'));
        expect(request.context, contains('Standup notes'));
        expect(request.context, contains('Launch plan'));
        expect(fakeHome.requestedCategoryIds, contains('mol-1'));
      },
    );

    test('clearing the molecule context drops it from the next send', () async {
      fakeHome.pages.addAll([
        [atomModel('m1', 'Standup notes')],
      ]);

      controller.attachContextMolecule(
        const CategoryModel(id: 'mol-1', name: 'Work'),
      );
      controller.clearContextMolecule();

      await controller.sendMessage('No context question');

      expect(fakeAi.lastChatRequest?.context, isNull);
    });

    test('an empty molecule still sends a usable context note', () async {
      controller.attachContextMolecule(
        const CategoryModel(id: 'mol-empty', name: 'Empty'),
      );

      await controller.sendMessage('Anything in this molecule?');

      expect(
        fakeAi.lastChatRequest?.context,
        contains('no atoms in this molecule yet'),
      );
    });
  });
}
