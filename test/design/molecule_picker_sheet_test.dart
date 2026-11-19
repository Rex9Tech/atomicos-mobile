// test/design/molecule_picker_sheet_test.dart
//
// The post-recording molecule chooser: tapping a molecule returns its id,
// dismissing returns null (leave uncategorized), and an empty molecule list
// never opens a sheet at all.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/locales/app_translations.dart';
import 'package:rexone_mobile/modules/home/data/models/category.model.dart';
import 'package:rexone_mobile/services/services.dart';

import '../mocks/test_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.put<CategoryService>(FakeCategoryService());
  });

  tearDown(Get.reset);

  Future<void> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        theme: Design.theme.light,
        home: const Scaffold(body: SizedBox()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tapping a molecule returns its id', (tester) async {
    Get.find<CategoryService>().categories.assignAll(const [
      CategoryModel(id: 'cat-general', name: 'General'),
      CategoryModel(id: 'cat-nova', name: 'Nova'),
    ]);

    await pumpHost(tester);
    String? picked;
    showMoleculePickerSheet().then((value) => picked = value);
    await tester.pumpAndSettle();

    expect(find.text('General'), findsOneWidget);
    expect(find.text('Nova'), findsOneWidget);

    await tester.tap(find.text('Nova'));
    await tester.pumpAndSettle();

    expect(picked, 'cat-nova');
  });

  testWidgets('dismissing returns null (leave uncategorized)', (tester) async {
    Get.find<CategoryService>().categories.assignAll(const [
      CategoryModel(id: 'cat-general', name: 'General'),
    ]);

    await pumpHost(tester);
    String? picked = 'unset';
    showMoleculePickerSheet().then((value) => picked = value);
    await tester.pumpAndSettle();

    // Tap the barrier above the sheet to dismiss it.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(picked, isNull);
  });

  testWidgets('an empty molecule list never opens the sheet', (tester) async {
    await pumpHost(tester);

    final result = await showMoleculePickerSheet();
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(find.text('Select molecule'), findsNothing);
  });

  group('ask chooser (showMoleculePickerForAsk)', () {
    testWidgets('lists neurons and resolves with the picked one', (
      tester,
    ) async {
      Get.find<CategoryService>().categories.assignAll(const [
        CategoryModel(id: 'cat-general', name: 'General'),
        CategoryModel(id: 'cat-nova', name: 'Nova'),
      ]);

      await pumpHost(tester);
      CategoryModel? picked;
      showMoleculePickerForAsk().then((value) => picked = value);
      await tester.pumpAndSettle();

      expect(find.text('Select neuron'), findsOneWidget);
      await tester.tap(find.text('Nova'));
      await tester.pumpAndSettle();

      expect(picked?.id, 'cat-nova');
    });

    testWidgets('an empty neuron list still opens with the create row', (
      tester,
    ) async {
      await pumpHost(tester);
      CategoryModel? picked = const CategoryModel(id: 'unset', name: '');
      showMoleculePickerForAsk().then((value) => picked = value);
      await tester.pumpAndSettle();

      expect(find.text('No neurons yet'), findsOneWidget);
      expect(find.text('Create new neuron'), findsOneWidget);

      // Dismissing cancels the ask — no neuron chosen, no route.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(picked, isNull);
    });

    testWidgets('creating a neuron resolves the sheet with it', (tester) async {
      await pumpHost(tester);
      CategoryModel? picked;
      showMoleculePickerForAsk().then((value) => picked = value);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create new neuron'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Deep Work');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(picked?.name, 'Deep Work');
      expect(picked?.id.isNotEmpty, isTrue);

      // Let the "Neuron added" snackbar time out before the test ends.
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
    });
  });
}
