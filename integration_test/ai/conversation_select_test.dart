// integration_test/ai/conversation_select_test.dart
//
// Regression: selecting a conversation must show ITS thread —
//  - "choose conversation → routes to atom details / shows new conversation"
//    (entryMode must be 'ask' and askStage 'prompt_result', not 'landing').
//  - selecting the empty "New Conversation" room correctly returns to the
//    landing (that room has nothing to show).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rexone_mobile/main.dart' as app;
import 'package:rexone_mobile/modules/ai/ai.dart';
import 'package:rexone_mobile/modules/auth/auth.dart';
import 'package:rexone_mobile/modules/home/home.dart';
import 'package:rexone_mobile/routes/routes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('selecting a conversation shows its thread', (tester) async {
    app.main();

    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (find.byType(HomePage).evaluate().isNotEmpty) break;
      if (find.byType(TextField).evaluate().isNotEmpty) break;
    }
    if (find.byType(HomePage).evaluate().isEmpty) {
      debugPrint('🔑 SESSION_BOOTSTRAP — signing in as super@admin.com');
      final auth = Get.find<AuthController>();
      auth.email.value = 'super@admin.com';
      auth.password.value = '111111';
      await auth.signIn();
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (find.byType(HomePage).evaluate().isNotEmpty) break;
      }
    }
    expect(find.byType(HomePage), findsOneWidget, reason: 'home available');

    AppRoutes.toAi(mode: 'ask');
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (AiController.active != null) break;
    }
    final controller = AiController.active!;

    await controller.loadRooms();
    debugPrint(
      '🛋 rooms: ${controller.rooms.map((r) => '"${r.title}" id=${r.id} msgs=${r.messageCount}').join(' | ')}',
    );
    expect(controller.rooms, isNotEmpty, reason: 'rooms list should load');

    // --- Case 1: a real conversation must open its thread. ---
    final realRoom = controller.rooms.firstWhere(
      (r) => r.title.startsWith('What are the key points'),
      orElse: () => controller.rooms.firstWhere((r) => r.messageCount > 0),
    );
    debugPrint('🛋 selecting "${realRoom.title}" (${realRoom.id})');

    controller.selectRoom(realRoom);
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (controller.messages.any((m) => m.id != 'welcome')) break;
    }
    debugPrint(
      '🛋 after select: roomId=${controller.currentRoomId.value} '
      'messages=${controller.messages.length} '
      'stage=${controller.askStage.value} entry=${controller.entryMode.value} '
      'first="${controller.messages.isNotEmpty ? controller.messages.first.content : ''}"',
    );
    expect(controller.currentRoomId.value, realRoom.id);
    expect(
      controller.askStage.value,
      equals('prompt_result'),
      reason: 'the conversation thread must render, not the landing',
    );
    expect(
      controller.messages.where((m) => m.id != 'welcome'),
      isNotEmpty,
      reason: 'history should render for the selected conversation',
    );
    expect(
      controller.messages.any((m) => m.content.startsWith('M-A')),
      isTrue,
      reason: 'the selected room\'s own messages should load',
    );
    expect(find.textContaining('M-A'), findsWidgets,
        reason: 'the thread bubbles should be on screen');

    // --- Case 2: the empty "New Conversation" room shows the landing. ---
    final emptyRoom = controller.rooms.firstWhere(
      (r) => r.messageCount == 0,
      orElse: () => realRoom,
    );
    if (!identical(emptyRoom, realRoom)) {
      debugPrint('🛋 selecting empty "${emptyRoom.title}"');
      controller.selectRoom(emptyRoom);
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (controller.askStage.value == 'landing' &&
            controller.messages.every((m) => m.id == 'welcome')) {
          break;
        }
      }
      // Let any in-flight loads settle, then assert the room stayed empty.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(
        controller.messages.every((m) => m.id == 'welcome'),
        isTrue,
        reason: 'an empty conversation shows the welcome state',
      );
    }

    // --- Case 3: going back to the real conversation still works. ---
    controller.selectRoom(realRoom);
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (controller.messages.any((m) => m.content.startsWith('M-A'))) break;
    }
    expect(controller.askStage.value, equals('prompt_result'));
    expect(controller.messages.any((m) => m.content.startsWith('M-A')), isTrue);

    await Future<void>.delayed(const Duration(seconds: 2));
  });
}
