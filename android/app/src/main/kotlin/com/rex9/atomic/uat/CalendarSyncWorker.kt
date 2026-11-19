package com.rex9.atomic.uat

import android.content.Context
import android.util.Log
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Periodic (~15 min) fallback for the calendar live sync: boots a headless
 * Flutter engine, runs the meeting-reminder refresh (`calendarSyncMain`), and
 * shuts the engine down. Skipped while the main engine is alive — the
 * in-process ContentObserver already handles calendar changes then.
 */
class CalendarSyncWorker(
    context: Context,
    params: WorkerParameters,
) : Worker(context, params) {
    override fun doWork(): Result {
        if (AppProcessState.mainEngineAlive) return Result.success()

        val latch = CountDownLatch(1)
        var engine: FlutterEngine? = null
        return try {
            engine = FlutterEngine(applicationContext)
            GeneratedPluginRegistrant.registerWith(engine!!)
            val messenger = engine!!.dartExecutor.binaryMessenger

            // The headless Dart side talks to the same calendar bridge.
            MethodChannel(messenger, CalendarBridge.CHANNEL)
                .setMethodCallHandler { call, result ->
                    CalendarBridge.handle(applicationContext, call, result)
                }
            MethodChannel(messenger, "atomicos/calendar_sync")
                .setMethodCallHandler { call, result ->
                    if (call.method == "done") {
                        result.success(null)
                        latch.countDown()
                    } else {
                        result.notImplemented()
                    }
                }

            engine!!.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint(
                    FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                    "calendarSyncMain",
                ),
            )

            val finished = latch.await(90, TimeUnit.SECONDS)
            if (finished) {
                Log.d(TAG, "background calendar sync finished")
                Result.success()
            } else {
                Log.w(TAG, "background calendar sync timed out")
                Result.retry()
            }
        } catch (error: Exception) {
            Log.w(TAG, "background calendar sync failed", error)
            Result.retry()
        } finally {
            try {
                engine?.destroy()
            } catch (_: Exception) {
                // Engine teardown is best-effort.
            }
        }
    }

    companion object {
        private const val TAG = "CalendarSyncWorker"
        private const val WORK_NAME = "atomicos_calendar_sync"

        fun schedule(context: Context) {
            val request = PeriodicWorkRequestBuilder<CalendarSyncWorker>(
                15,
                TimeUnit.MINUTES,
            )
                .setConstraints(
                    Constraints.Builder()
                        .setRequiresBatteryNotLow(true)
                        .build(),
                )
                .build()
            WorkManager.getInstance(context.applicationContext)
                .enqueueUniquePeriodicWork(
                    WORK_NAME,
                    ExistingPeriodicWorkPolicy.KEEP,
                    request,
                )
            Log.d(TAG, "periodic background sync scheduled")
        }

        fun cancel(context: Context) {
            WorkManager.getInstance(context.applicationContext)
                .cancelUniqueWork(WORK_NAME)
            Log.d(TAG, "periodic background sync cancelled")
        }
    }
}
