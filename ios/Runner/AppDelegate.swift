import BackgroundTasks
import EventKit
import Flutter
import MediaPlayer
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var mediaDownloadLiveActivityChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    application.beginReceivingRemoteControlEvents()

    // Background calendar sync — BGTaskScheduler handlers must be registered
    // before the app finishes launching.
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: CalendarBackgroundSync.taskIdentifier,
      using: nil
    ) { task in
      guard let refreshTask = task as? BGAppRefreshTask else { return }
      CalendarBackgroundSync.shared.handle(task: refreshTask)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()

    let nowPlayingChannel = FlutterMethodChannel(
      name: "atomic/now_playing",
      binaryMessenger: messenger
    )
    nowPlayingChannel.setMethodCallHandler { call, result in
      let center = MPNowPlayingInfoCenter.default()
      switch call.method {
      case "setPlaybackState":
        let playing = (call.arguments as? [String: Any])?["playing"] as? Bool ?? false
        if #available(iOS 13.0, *) {
          center.playbackState = playing ? .playing : .paused
        }
        if var info = center.nowPlayingInfo {
          info[MPNowPlayingInfoPropertyPlaybackRate] = playing ? 1.0 : 0.0
          center.nowPlayingInfo = info
        }
        result(nil)
      case "clear":
        center.nowPlayingInfo = nil
        if #available(iOS 13.0, *) {
          center.playbackState = .stopped
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let mediaChannel = FlutterMethodChannel(
      name: "atomic/media_download_live_activity",
      binaryMessenger: messenger
    )
    mediaDownloadLiveActivityChannel = mediaChannel
    mediaChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "takePending":
        result(MediaDownloadLiveActivityActionStore.takePending())
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    NotificationCenter.default.addObserver(
      forName: MediaDownloadLiveActivityActionStore.didEnqueueNotification,
      object: nil,
      queue: .main
    ) { [weak self] notification in
      self?.mediaDownloadLiveActivityChannel?.invokeMethod(
        "action",
        arguments: notification.userInfo
      )
    }

    // ===== Google Calendar integration — same channel contract as Android =====
    CalendarBridge.shared.attach(messenger: messenger)
    CalendarBackgroundSync.shared.attach(mainMessenger: messenger)

    FlutterMethodChannel(name: "atomicos/calendar", binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        CalendarBridge.shared.handle(call: call, result: result)
      }

    CalendarWatcher.shared.attach(
      FlutterMethodChannel(name: "atomicos/calendar_events", binaryMessenger: messenger)
    )
  }
}

// MARK: - Google Calendar (EventKit) — twin of the Android CalendarBridge

/// EventKit-backed calendar bridge. Method names and payload shapes mirror
/// `CalendarBridge.kt` so the Dart layer is platform-agnostic.
final class CalendarBridge {
  static let shared = CalendarBridge()
  private let store = EKEventStore()

  func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "hasPermissions":
      result(hasPermissions())
    case "requestPermissions":
      requestPermissions(result: result)
    case "listCalendars":
      result(listCalendars())
    case "listUpcomingEvents":
      result(listUpcomingEvents(call: call))
    case "createOrUpdateEvent":
      result(upsertEvent(call: call))
    case "deleteEvent":
      result(deleteEvent(call: call))
    case "startWatching":
      CalendarWatcher.shared.start()
      result(true)
    case "stopWatching":
      CalendarWatcher.shared.stop()
      result(true)
    case "scheduleBackgroundSync":
      CalendarBackgroundSync.shared.schedule()
      result(true)
    case "cancelBackgroundSync":
      CalendarBackgroundSync.shared.cancel()
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func hasPermissions() -> Bool {
    let status = EKEventStore.authorizationStatus(for: .event)
    if #available(iOS 17.0, *) {
      return status == .fullAccess
    }
    return status == .authorized
  }

  private func requestPermissions(result: @escaping FlutterResult) {
    if #available(iOS 17.0, *) {
      store.requestFullAccessToEvents { granted, _ in
        DispatchQueue.main.async { result(granted) }
      }
    } else {
      store.requestAccess(to: .event) { granted, _ in
        DispatchQueue.main.async { result(granted) }
      }
    }
  }

  private func listCalendars() -> [[String: Any?]] {
    store.calendars(for: .event).map { calendar in
      [
        "id": calendar.calendarIdentifier,
        "name": calendar.title,
        "accountName": calendar.source?.title ?? "",
        "isReadOnly": !calendar.allowsContentModifications,
      ]
    }
  }

  private func listUpcomingEvents(call: FlutterMethodCall) -> [[String: Any?]] {
    let args = call.arguments as? [String: Any]
    let startMillis = (args?["startMillis"] as? NSNumber)?.doubleValue
      ?? Date().timeIntervalSince1970 * 1000
    let endMillis = (args?["endMillis"] as? NSNumber)?.doubleValue
      ?? startMillis + 7 * 24 * 60 * 60 * 1000
    let start = Date(timeIntervalSince1970: startMillis / 1000)
    let end = Date(timeIntervalSince1970: endMillis / 1000)
    let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
    return store.events(matching: predicate)
      .filter { $0.status != .canceled }
      .sorted { $0.startDate < $1.startDate }
      .map { event in
        [
          "eventId": event.eventIdentifier ?? "",
          "calendarId": event.calendar?.calendarIdentifier ?? "",
          "title": event.title ?? "",
          "startMillis": Int(event.startDate.timeIntervalSince1970 * 1000),
          "endMillis": Int(event.endDate.timeIntervalSince1970 * 1000),
          "allDay": event.isAllDay,
        ]
      }
  }

  private func upsertEvent(call: FlutterMethodCall) -> String? {
    let args = call.arguments as? [String: Any]
    guard
      let calendarId = args?["calendarId"] as? String,
      let startMillis = (args?["startMillis"] as? NSNumber)?.doubleValue,
      let endMillis = (args?["endMillis"] as? NSNumber)?.doubleValue
    else { return nil }

    let title = args?["title"] as? String ?? "AtomicOS meeting"
    let description = args?["description"] as? String
    let reminderMinutes = (args?["reminderMinutes"] as? NSNumber)?.intValue

    let event: EKEvent
    var isNew = false
    if let eventId = args?["eventId"] as? String, !eventId.isEmpty,
       let existing = store.event(withIdentifier: eventId) {
      event = existing
    } else {
      event = EKEvent(eventStore: store)
      isNew = true
    }

    if let calendar = store.calendar(withIdentifier: calendarId) {
      event.calendar = calendar
    } else if let fallback = store.defaultCalendarForNewEvents {
      event.calendar = fallback
    } else {
      return nil
    }

    event.title = title
    event.notes = description
    event.startDate = Date(timeIntervalSince1970: startMillis / 1000)
    event.endDate = Date(timeIntervalSince1970: endMillis / 1000)
    if isNew, let minutes = reminderMinutes, minutes >= 0 {
      event.addAlarm(EKAlarm(relativeOffset: TimeInterval(-minutes * 60)))
    }

    do {
      try store.save(event, span: .thisEvent)
      return event.eventIdentifier
    } catch {
      return nil
    }
  }

  private func deleteEvent(call: FlutterMethodCall) -> Bool {
    guard
      let eventId = (call.arguments as? [String: Any])?["eventId"] as? String,
      let event = store.event(withIdentifier: eventId)
    else { return false }
    do {
      try store.remove(event, span: .thisEvent)
      return true
    } catch {
      return false
    }
  }
}

// MARK: - Live calendar observer (EKEventStoreChanged)

/// Notifies Dart when the calendar store changes (debounced), so reminders
/// re-arm within seconds while the app is alive — the twin of CalendarWatcher.kt.
final class CalendarWatcher {
  static let shared = CalendarWatcher()
  private var channel: FlutterMethodChannel?
  private var observer: NSObjectProtocol?
  private var pending: DispatchWorkItem?

  func attach(_ methodChannel: FlutterMethodChannel) {
    channel = methodChannel
  }

  func start() {
    guard observer == nil else { return }
    observer = NotificationCenter.default.addObserver(
      forName: .EKEventStoreChanged,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.schedule()
    }
  }

  func stop() {
    if let observer = observer {
      NotificationCenter.default.removeObserver(observer)
      self.observer = nil
    }
    pending?.cancel()
    pending = nil
  }

  private func schedule() {
    pending?.cancel()
    let work = DispatchWorkItem { [weak self] in
      self?.channel?.invokeMethod("calendarChanged", arguments: nil)
    }
    pending = work
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: work)
  }
}

// MARK: - Background calendar sync (BGAppRefreshTask)

/// Opportunistic background refresh — iOS decides when it runs (typically
/// every few hours, not a fixed 15-minute cadence). If the app process is
/// alive it pokes the main engine; otherwise it boots a headless engine and
/// runs the same `calendarSyncMain` entry point as Android.
final class CalendarBackgroundSync {
  static let shared = CalendarBackgroundSync()
  static let taskIdentifier = "com.rex9.atomic.uat.calendar-sync"

  private var mainMessenger: FlutterBinaryMessenger?
  private var headlessEngine: FlutterEngine?

  func attach(mainMessenger: FlutterBinaryMessenger) {
    self.mainMessenger = mainMessenger
  }

  func schedule() {
    let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
    request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
    do {
      try BGTaskScheduler.shared.submit(request)
    } catch {
      // Background refresh unavailable (simulator, disabled in settings) —
      // the app-open refresh still covers the user.
    }
  }

  func cancel() {
    BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.taskIdentifier)
  }

  func handle(task: BGAppRefreshTask) {
    // BG tasks are one-shot — re-arm for the next window immediately.
    schedule()

    // Process alive (suspended, not killed): the main engine is there — just
    // poke it and let the Dart layer re-arm reminders.
    if let messenger = mainMessenger {
      FlutterMethodChannel(
        name: "atomicos/calendar_events",
        binaryMessenger: messenger
      ).invokeMethod("calendarChanged", arguments: nil)
      task.setTaskCompleted(success: true)
      return
    }

    runHeadlessSync(task: task)
  }

  private func runHeadlessSync(task: BGAppRefreshTask) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self, self.headlessEngine == nil else {
        task.setTaskCompleted(success: false)
        return
      }

      let engine = FlutterEngine(name: "atomicos-calendar-sync", project: nil)
      GeneratedPluginRegistrant.register(with: engine)
      let messenger = engine.binaryMessenger

      FlutterMethodChannel(name: "atomicos/calendar", binaryMessenger: messenger)
        .setMethodCallHandler { call, result in
          CalendarBridge.shared.handle(call: call, result: result)
        }

      FlutterMethodChannel(name: "atomicos/calendar_sync", binaryMessenger: messenger)
        .setMethodCallHandler { [weak self] call, result in
          if call.method == "done" {
            result(nil)
            self?.headlessEngine?.destroyContext()
            self?.headlessEngine = nil
            task.setTaskCompleted(success: true)
          } else {
            result(FlutterMethodNotImplemented)
          }
        }

      self.headlessEngine = engine
      engine.run(withEntrypoint: "calendarSyncMain", libraryURI: nil)

      // Safety net — never leave the BG task hanging.
      DispatchQueue.main.asyncAfter(deadline: .now() + 90) { [weak self] in
        if self?.headlessEngine != nil {
          self?.headlessEngine?.destroyContext()
          self?.headlessEngine = nil
          task.setTaskCompleted(success: false)
        }
      }
    }
  }
}
