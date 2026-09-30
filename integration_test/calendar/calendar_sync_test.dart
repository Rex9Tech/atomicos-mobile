// integration_test/calendar/calendar_sync_test.dart
//
// Device-calendar sync, end to end through the REAL native bridge:
// permission check → calendar list → create → update in place → remove.
// The calendar permissions must be pre-granted for the app
// (adb shell pm grant com.rex9.uat.atomic android.permission.READ_CALENDAR /
// WRITE_CALENDAR) because system permission dialogs can't be driven from a
// test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rexone_mobile/main.dart' as app;
import 'package:rexone_mobile/modules/auth/auth.dart';
import 'package:rexone_mobile/modules/home/home.dart';
import 'package:rexone_mobile/services/services.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('meeting syncs into the device calendar', (tester) async {
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

    final service = Get.find<DeviceCalendarService>();

    final perms = await service.ensurePermissions();
    debugPrint('CALTEST perms=$perms');
    expect(perms, isTrue, reason: 'calendar permissions must be pre-granted');

    final calendars = await service.availableCalendars();
    debugPrint(
      'CALTEST calendars=${calendars.map((c) => "${c.name}<${c.accountName}>").join(" | ")}',
    );
    expect(calendars, isNotEmpty, reason: 'a writable calendar must exist');

    // --- Create ---
    final start = DateTime.now().add(const Duration(hours: 2));
    final created = await service.syncMeeting(
      atomId: 'itest-atom',
      title: 'AtomicOS sync test',
      start: start,
    );
    debugPrint('CALTEST create result=$created');
    expect(created, CalendarSyncResult.synced);
    final link = service.linkFor('itest-atom');
    expect(link, isNotNull);
    debugPrint('CALTEST link=${link!.eventId}@cal${link.calendarId}');

    // --- Update in place (same event id) ---
    final updated = await service.syncMeeting(
      atomId: 'itest-atom',
      title: 'AtomicOS sync test',
      start: start.add(const Duration(hours: 1)),
    );
    expect(updated, CalendarSyncResult.synced);
    final linkAfter = service.linkFor('itest-atom');
    debugPrint('CALTEST after update event=${linkAfter?.eventId} date=${linkAfter?.date}');
    expect(linkAfter?.eventId, link.eventId, reason: 'one event per atom');

    // --- Remove ---
    final removed = await service.removeMeeting('itest-atom');
    debugPrint('CALTEST removed=$removed');
    expect(removed, isTrue);
    expect(service.linkFor('itest-atom'), isNull);

    await Future<void>.delayed(const Duration(seconds: 2));
  });
}
