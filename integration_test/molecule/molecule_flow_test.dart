// integration_test/molecule/molecule_flow_test.dart
//
// Home → molecules list → molecule screen → ask-with-molecule round trip.
// Drives the real app against the live core (tap-free: MIUI blocks adb input).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rexone_mobile/main.dart' as app;
import 'package:rexone_mobile/modules/ai/ai.dart';
import 'package:rexone_mobile/modules/auth/auth.dart';
import 'package:rexone_mobile/modules/home/home.dart';
import 'package:rexone_mobile/modules/molecule/molecule.dart';
import 'package:rexone_mobile/routes/routes.dart';
import 'package:rexone_mobile/services/services.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home lists molecules and ask-with-molecule works', (
    tester,
  ) async {
    app.main();

    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (find.byType(HomePage).evaluate().isNotEmpty) break;
      if (find.byType(TextField).evaluate().isNotEmpty) break;
    }
    if (find.byType(HomePage).evaluate().isEmpty) {
      debugPrint('KEY SESSION_BOOTSTRAP — signing in as super@admin.com');
      final auth = Get.find<AuthController>();
      auth.email.value = 'super@admin.com';
      auth.password.value = '111111';
      // The Myanmar network drops TLS handshakes intermittently — retry the
      // sign-in a few times before giving up.
      for (var attempt = 1; attempt <= 3; attempt++) {
        try {
          await auth.signIn();
        } catch (error) {
          debugPrint('MOLTEST signin attempt $attempt threw: $error');
        }
        for (var i = 0; i < 40; i++) {
          await tester.pump(const Duration(milliseconds: 500));
          if (find.byType(HomePage).evaluate().isNotEmpty) break;
        }
        if (find.byType(HomePage).evaluate().isNotEmpty) break;
        debugPrint('MOLTEST signin attempt $attempt did not reach home — retrying');
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
    expect(find.byType(HomePage), findsOneWidget, reason: 'home available');

    // The molecule list (categories) must arrive.
    final categories = Get.find<CategoryService>();
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (categories.categories.isNotEmpty) break;
    }
    debugPrint(
      'MOLTEST molecules=${categories.categories.map((c) => c.name).toList()}',
    );
    expect(
      categories.categories,
      isNotEmpty,
      reason: 'super@admin has at least one molecule on prod',
    );

    final molecule = categories.categories.first;

    // Home now renders the molecules list (replaced the recent-atoms list).
    expect(find.text(molecule.name), findsWidgets);
    debugPrint('MOLTEST home shows "${molecule.name}"');

    // Open the molecule screen; its atoms settle (empty is fine).
    AppRoutes.toMolecule(moleculeId: molecule.id, moleculeName: molecule.name);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.byType(MoleculePage).evaluate().isNotEmpty) break;
    }
    expect(find.byType(MoleculePage), findsOneWidget);
    final moleculeController = MoleculeController.active;
    expect(moleculeController, isNotNull);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (!moleculeController!.isLoading.value) break;
    }
    debugPrint(
      'MOLTEST molecule page atoms=${moleculeController!.atoms.length} '
      'hasError=${moleculeController.hasError.value}',
    );
    expect(moleculeController.hasError.value, isFalse);

    Get.back();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.byType(HomePage).evaluate().isNotEmpty) break;
    }

    // Ask-with-molecule: the whole molecule is pinned as context from the
    // route arguments alone.
    AppRoutes.toAi(
      mode: 'ask',
      moleculeId: molecule.id,
      moleculeName: molecule.name,
    );
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.byType(AiPage).evaluate().isNotEmpty) break;
    }
    expect(find.byType(AiPage), findsOneWidget);

    final ai = AiController.active;
    expect(ai, isNotNull);
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (ai!.contextMolecule.value != null) break;
    }
    expect(
      ai!.contextMolecule.value?.id,
      molecule.id,
      reason: 'whole molecule pinned as context',
    );
    debugPrint('MOLTEST ask context=${ai.contextMolecule.value?.name}');

    // A real question round-trips through the async job and gets a reply.
    await ai.sendMessage('Reply with exactly: MOLECULE OK');
    var replied = false;
    for (var i = 0; i < 90; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      final assistant = ai.messages
          .where(
            (m) => !m.isUser && m.id != 'welcome' && m.content.trim().isNotEmpty,
          )
          .toList();
      if (assistant.isNotEmpty && !ai.isProcessing.value) {
        replied = true;
        final text = assistant.last.content;
        debugPrint(
          'MOLTEST reply=${text.substring(0, text.length.clamp(0, 120))}',
        );
        break;
      }
    }
    expect(replied, isTrue, reason: 'assistant reply arrived');
    Get.closeAllSnackbars();
  });
}
