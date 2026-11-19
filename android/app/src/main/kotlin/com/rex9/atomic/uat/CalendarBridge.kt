package com.rex9.atomic.uat

import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.pm.PackageManager
import android.provider.CalendarContract
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

/**
 * Minimal bridge to the DEVICE calendar provider (CalendarContract).
 *
 * Meetings are written straight into the user's own calendar through the
 * provider — no "save the event" hand-off in a second app — so they show up
 * in the built-in calendar apps automatically.
 *
 * Also hosts the live-sync controls: the calendar-change observer
 * (CalendarWatcher) and the periodic background sync (CalendarSyncWorker).
 */
object CalendarBridge {
    const val CHANNEL = "atomicos/calendar"
    const val PERMISSION_REQUEST_CODE = 8412

    val PERMISSIONS = arrayOf(
        android.Manifest.permission.READ_CALENDAR,
        android.Manifest.permission.WRITE_CALENDAR,
    )

    fun handle(context: Context, call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "hasPermissions" -> result.success(hasPermissions(context))
                "listCalendars" -> result.success(listCalendars(context))
                "createOrUpdateEvent" -> result.success(upsertEvent(context, call))
                "deleteEvent" -> result.success(deleteEvent(context, call))
                "listUpcomingEvents" -> result.success(listUpcomingEvents(context, call))
                "startWatching" -> {
                    CalendarWatcher.start(context)
                    result.success(true)
                }
                "stopWatching" -> {
                    CalendarWatcher.stop(context)
                    result.success(true)
                }
                "scheduleBackgroundSync" -> {
                    CalendarSyncWorker.schedule(context)
                    result.success(true)
                }
                "cancelBackgroundSync" -> {
                    CalendarSyncWorker.cancel(context)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        } catch (error: SecurityException) {
            result.error("permission_denied", error.message, null)
        } catch (error: Exception) {
            result.error("calendar_error", error.message, null)
        }
    }

    fun hasPermissions(context: Context): Boolean = PERMISSIONS.all {
        ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
    }

    private fun listCalendars(context: Context): List<Map<String, Any?>> {
        val calendars = mutableListOf<Map<String, Any?>>()
        val projection = arrayOf(
            CalendarContract.Calendars._ID,
            CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
            CalendarContract.Calendars.ACCOUNT_NAME,
            CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL,
        )
        context.contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            null,
            null,
            null,
        )?.use { cursor ->
            while (cursor.moveToNext()) {
                val accessLevel = cursor.getInt(3)
                calendars.add(
                    mapOf(
                        "id" to cursor.getString(0),
                        "name" to (cursor.getString(1) ?: ""),
                        "accountName" to (cursor.getString(2) ?: ""),
                        "isReadOnly" to
                            (accessLevel < CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR),
                    ),
                )
            }
        }
        return calendars
    }

    /**
     * Reads upcoming events (the user's Google account included) between two
     * instants. Cancelled events are skipped.
     */
    private fun listUpcomingEvents(context: Context, call: MethodCall): List<Map<String, Any?>> {
        val startMillis =
            call.argument<Number>("startMillis")?.toLong() ?: System.currentTimeMillis()
        val endMillis =
            call.argument<Number>("endMillis")?.toLong()
                ?: (startMillis + 7L * 24L * 60L * 60L * 1000L)

        val events = mutableListOf<Map<String, Any?>>()
        val projection = arrayOf(
            CalendarContract.Instances.EVENT_ID,
            CalendarContract.Instances.CALENDAR_ID,
            CalendarContract.Instances.TITLE,
            CalendarContract.Instances.BEGIN,
            CalendarContract.Instances.END,
            CalendarContract.Instances.ALL_DAY,
        )
        val builder = CalendarContract.Instances.CONTENT_URI.buildUpon()
        ContentUris.appendId(builder, startMillis)
        ContentUris.appendId(builder, endMillis)

        context.contentResolver.query(
            builder.build(),
            projection,
            CalendarContract.Instances.STATUS + " != " + CalendarContract.Events.STATUS_CANCELED,
            null,
            CalendarContract.Instances.BEGIN + " ASC",
        )?.use { cursor ->
            while (cursor.moveToNext()) {
                events.add(
                    mapOf(
                        "eventId" to cursor.getString(0),
                        "calendarId" to cursor.getString(1),
                        "title" to (cursor.getString(2) ?: ""),
                        "startMillis" to cursor.getLong(3),
                        "endMillis" to cursor.getLong(4),
                        "allDay" to (cursor.getInt(5) == 1),
                    ),
                )
            }
        }
        return events
    }

    private fun upsertEvent(context: Context, call: MethodCall): String? {
        val calendarId = call.argument<String>("calendarId") ?: return null
        val eventId = call.argument<String>("eventId")
        val title = call.argument<String>("title") ?: "AtomicOS meeting"
        val description = call.argument<String>("description")
        val startMillis = call.argument<Number>("startMillis")?.toLong() ?: return null
        val endMillis = call.argument<Number>("endMillis")?.toLong() ?: return null
        val reminderMinutes = call.argument<Number>("reminderMinutes")?.toInt()

        val values = ContentValues().apply {
            put(CalendarContract.Events.CALENDAR_ID, calendarId.toLong())
            put(CalendarContract.Events.TITLE, title)
            put(CalendarContract.Events.DTSTART, startMillis)
            put(CalendarContract.Events.DTEND, endMillis)
            put(CalendarContract.Events.EVENT_TIMEZONE, TimeZone.getDefault().id)
            if (!description.isNullOrEmpty()) {
                put(CalendarContract.Events.DESCRIPTION, description)
            }
        }

        if (!eventId.isNullOrEmpty()) {
            val uri = ContentUris.withAppendedId(
                CalendarContract.Events.CONTENT_URI,
                eventId.toLong(),
            )
            if (context.contentResolver.update(uri, values, null, null) > 0) {
                return eventId
            }
            // The event was deleted in the calendar app — fall through and
            // create a fresh one so the meeting is never silently lost.
        }

        val newUri = context.contentResolver
            .insert(CalendarContract.Events.CONTENT_URI, values) ?: return null
        val newId = newUri.lastPathSegment ?: return null
        if (reminderMinutes != null && reminderMinutes >= 0) {
            try {
                context.contentResolver.insert(
                    CalendarContract.Reminders.CONTENT_URI,
                    ContentValues().apply {
                        put(CalendarContract.Reminders.EVENT_ID, newId.toLong())
                        put(CalendarContract.Reminders.MINUTES, reminderMinutes)
                        put(
                            CalendarContract.Reminders.METHOD,
                            CalendarContract.Reminders.METHOD_ALERT,
                        )
                    },
                )
            } catch (ignored: Exception) {
                // A reminder is a nicety — never fail the sync over it.
            }
        }
        return newId
    }

    private fun deleteEvent(context: Context, call: MethodCall): Boolean {
        val eventId = call.argument<String>("eventId") ?: return false
        val uri = ContentUris.withAppendedId(
            CalendarContract.Events.CONTENT_URI,
            eventId.toLong(),
        )
        return context.contentResolver.delete(uri, null, null) > 0
    }
}
