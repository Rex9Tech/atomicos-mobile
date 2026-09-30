// integration_test/atom_details/atom_delete_test.dart
//
// Atom delete, end to end: creates a throwaway atom through the real API,
// loads its details, deletes it via the controller, then verifies it is gone
// from the library and can no longer be fetched.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rexone_mobile/main.dart' as app;
import 'package:rexone_mobile/modules/atom_create/atom_create.dart';
import 'package:rexone_mobile/modules/atom_details/atom_details.dart';
import 'package:rexone_mobile/modules/auth/auth.dart';
import 'package:rexone_mobile/modules/home/home.dart';
import 'package:rexone_mobile/routes/routes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('deleting an atom removes it from the library', (tester) async {
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
      await auth.signIn();
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 500));
        if (find.byType(HomePage).evaluate().isNotEmpty) break;
      }
    }
    expect(find.byType(HomePage), findsOneWidget, reason: 'home available');

    // --- Create a throwaway atom through the real API. ---
    final create = await Get.find<AtomCreateService>().createFromNote(
      const AtomFromNoteRequest(
        title: 'e2e delete probe',
        note: 'throwaway atom created by the delete E2E test',
      ),
    );
    expect(create.success, isTrue, reason: 'probe atom created');
    final atomId = create.data?.id ?? '';
    expect(atomId, isNotEmpty);
    debugPrint('DELTEST created atom=$atomId');

    // --- Open its details screen (real route + controller lifecycle). ---
    AppRoutes.toAtomDetail(atomId: atomId);
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (Get.isRegistered<AtomDetailsController>()) break;
    }
    final controller = Get.find<AtomDetailsController>();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (controller.atom.value != null) break;
    }
    debugPrint('DELTEST loaded atom=${controller.atom.value?.title}');
    expect(controller.atom.value?.id, atomId);

    // --- Delete it. ---
    final deleted = await controller.deleteAtom();
    debugPrint('DELTEST delete result=$deleted');
    expect(deleted, isTrue);

    // --- Gone from the library list. ---
    final list = await Get.find<HomeService>().getAtoms(limit: 100);
    final stillThere = list.records.where((a) => a.id == atomId).toList();
    debugPrint('DELTEST remaining matches=${stillThere.length}');
    expect(stillThere, isEmpty, reason: 'atom must be gone from the library');

    // --- And no longer fetchable by id. ---
    final fetch = await Get.find<HomeService>().getAtom(atomId);
    debugPrint('DELTEST refetch success=${fetch.success}');
    expect(fetch.success, isFalse, reason: 'discarded atom is not fetchable');

    // Simulate the real post-delete navigation (back to home) and settle any
    // live toast animations so teardown has no active tickers.
    Get.until((route) => route.isFirst);
    Get.closeAllSnackbars();
    await tester.pump(const Duration(seconds: 1));
    await Future<void>.delayed(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  });
}
