package com.rex9.atomic.uat

import android.content.Context
import android.database.ContentObserver
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.CalendarContract
import android.util.Log
import io.flutter.plugin.common.MethodChannel

/**
 * Tracks whether the main Flutter engine is alive — the CalendarSyncWorker
 * skips its headless refresh while the in-process ContentObserver already
 * covers calendar changes.
 */
object AppProcessState {
    @Volatile
    var mainEngineAlive: Boolean = false
}

/**
 * Observes the device calendar (CalendarContract) and notifies Dart when it
 * changes, so meeting reminders re-arm within seconds while the app process
 * is alive. The observer dies with the process — the periodic WorkManager
 * sync (CalendarSyncWorker) is the closed-app fallback.
 */
object CalendarWatcher {
    private const val TAG = "CalendarWatcher"
    private const val DEBOUNCE_MS = 1200L

    private var observer: ContentObserver? = null
    private var channel: MethodChannel? = null
    private val handler = Handler(Looper.getMainLooper())
    private var pending: Runnable? = null

    /** Called from MainActivity when a Flutter engine is configured. */
    fun attach(methodChannel: MethodChannel) {
        channel = methodChannel
    }

    fun start(context: Context) {
        if (observer != null) return
        val appContext = context.applicationContext
        val contentObserver = object : ContentObserver(handler) {
            override fun onChange(selfChange: Boolean) = schedule()
            override fun onChange(selfChange: Boolean, uri: Uri?) = schedule()
        }
        try {
            appContext.contentResolver.registerContentObserver(
                CalendarContract.Events.CONTENT_URI,
                true,
                contentObserver,
            )
            observer = contentObserver
            Log.d(TAG, "calendar observer started")
        } catch (error: Exception) {
            observer = null
            Log.w(TAG, "could not start calendar observer", error)
        }
    }

    fun stop(context: Context) {
        val contentObserver = observer ?: return
        try {
            context.applicationContext.contentResolver
                .unregisterContentObserver(contentObserver)
        } catch (_: Exception) {
            // Already gone — nothing to do.
        }
        observer = null
        pending?.let { handler.removeCallbacks(it) }
        pending = null
        Log.d(TAG, "calendar observer stopped")
    }

    private fun schedule() {
        pending?.let { handler.removeCallbacks(it) }
        val runnable = Runnable {
            Log.d(TAG, "calendar change detected — notifying Dart")
            channel?.invokeMethod("calendarChanged", null)
        }
        pending = runnable
        handler.postDelayed(runnable, DEBOUNCE_MS)
    }
}
