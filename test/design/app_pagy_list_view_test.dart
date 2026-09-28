// test/design/app_pagy_list_view_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/design/design.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableWidget(Widget child) {
    return GetMaterialApp(
      home: Scaffold(body: child),
    );
  }

  group('AppPagyListView', () {
    testWidgets('renders initial loading state when isLoading is true and items is empty', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          AppPagyListView<String>(
            items: const [],
            isLoading: true,
            itemBuilder: (context, item, index) => Text(item),
            onRefresh: () async {},
            onLoadMore: () async {},
          ),
        ),
      );

      expect(find.byType(AppLoading), findsOneWidget);
    });

    testWidgets('renders empty state when items is empty and not loading', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          AppPagyListView<String>(
            items: const [],
            isLoading: false,
            emptyMessage: 'No items available.',
            itemBuilder: (context, item, index) => Text(item),
            onRefresh: () async {},
            onLoadMore: () async {},
          ),
        ),
      );

      expect(find.text('No items available.'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('renders error state with retry button when errorMessage is present and items is empty', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        buildTestableWidget(
          AppPagyListView<String>(
            items: const [],
            errorMessage: 'Network timeout',
            onRetry: () => retried = true,
            itemBuilder: (context, item, index) => Text(item),
            onRefresh: () async {},
            onLoadMore: () async {},
          ),
        ),
      );

      expect(find.text('Network timeout'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retried, isTrue);
    });

    testWidgets('renders list of items and header correctly', (tester) async {
      final items = ['Item 1', 'Item 2', 'Item 3'];

      await tester.pumpWidget(
        buildTestableWidget(
          AppPagyListView<String>(
            items: items,
            header: const Text('Header Section'),
            itemBuilder: (context, item, index) => ListTile(title: Text(item)),
            onRefresh: () async {},
            onLoadMore: () async {},
          ),
        ),
      );

      expect(find.text('Header Section'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Item 3'), findsOneWidget);
    });

    testWidgets('renders bottom loader when isLoadingMore is true', (tester) async {
      final items = ['Item 1', 'Item 2'];

      await tester.pumpWidget(
        buildTestableWidget(
          AppPagyListView<String>(
            items: items,
            isLoadingMore: true,
            itemBuilder: (context, item, index) => ListTile(title: Text(item)),
            onRefresh: () async {},
            onLoadMore: () async {},
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.byType(AppLoading), findsOneWidget);
    });
  });
}
