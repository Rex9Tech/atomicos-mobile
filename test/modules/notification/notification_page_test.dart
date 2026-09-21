// test/modules/notification/notification_page_test.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rexone_mobile/design/design.dart';
import 'package:rexone_mobile/locales/app_translations.dart';
import 'package:rexone_mobile/models/models.dart';
import 'package:rexone_mobile/modules/home/pages/widgets/notification_bell.dart';
import 'package:rexone_mobile/modules/notification/notification.dart';

import '../../mocks/test_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeNotificationService fakeService;

  const longLink =
      'https://atomicos.khantsithu.tech/v1/atoms/70923048-f608-4a0e-9d53-a87d31245129/details?source=push&campaign=weekly-digest&ref=mobile';

  NotificationModel item({
    required String id,
    String? link,
    bool read = false,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id,
      title: 'Weekly digest for your atomic meetings',
      message:
          'Your meeting summary from yesterday is ready to review with the team.',
      link: link,
      read: read,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  Future<void> pumpPage(WidgetTester tester, {required Locale locale}) async {
    tester.view.physicalSize = const Size(1125, 2436); // 375 x 812 @3x
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: locale,
        theme: Design.theme.light,
        home: const NotificationPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    Get.testMode = true;
    fakeService = FakeNotificationService();
    Get.put<NotificationService>(fakeService);
    Get.put(NotificationController());
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('renders without overflow in Burmese with a long link', (
    tester,
  ) async {
    fakeService.unreadCount = 128;
    fakeService.notificationsResponse = PaginatedResponse<NotificationModel>(
      records: [
        item(id: 'n1', link: longLink),
        item(
          id: 'n2',
          read: true,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ],
      message: 'OK',
      statusCode: 200,
      success: true,
    );

    await pumpPage(tester, locale: const Locale('my', 'MM'));

    expect(tester.takeException(), isNull);
    expect(
      find.text('Weekly digest for your atomic meetings'),
      findsNWidgets(2),
    );
  });

  testWidgets('renders without overflow in English with a long link', (
    tester,
  ) async {
    fakeService.unreadCount = 128;
    fakeService.notificationsResponse = PaginatedResponse<NotificationModel>(
      records: [item(id: 'n1', link: longLink)],
      message: 'OK',
      statusCode: 200,
      success: true,
    );

    await pumpPage(tester, locale: const Locale('en', 'US'));

    expect(tester.takeException(), isNull);
  });

  testWidgets('notifications sheet renders without overflow', (tester) async {
    fakeService.unreadCount = 128;
    fakeService.notificationsResponse = PaginatedResponse<NotificationModel>(
      records: [
        item(id: 'n1', link: longLink),
        item(
          id: 'n2',
          read: true,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ],
      message: 'OK',
      statusCode: 200,
      success: true,
    );

    tester.view.physicalSize = const Size(1125, 2436); // 375 x 812 @3x
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('my', 'MM'),
        theme: Design.theme.light,
        home: const Scaffold(),
      ),
    );

    unawaited(showNotificationsSheet());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text('Weekly digest for your atomic meetings'),
      findsNWidgets(2),
    );

    Get.back();
    await tester.pumpAndSettle();
  });
}
