package com.rex9.uat.atomic

import android.app.Activity
import android.content.ContentUris
import android.content.ContentValues
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
 */
object CalendarBridge {
    const val CHANNEL = "atomicos/calendar"
    const val PERMISSION_REQUEST_CODE = 8412

    val PERMISSIONS = arrayOf(
        android.Manifest.permission.READ_CALENDAR,
        android.Manifest.permission.WRITE_CALENDAR,
    )

    fun handle(activity: Activity, call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "hasPermissions" -> result.success(hasPermissions(activity))
                "listCalendars" -> result.success(listCalendars(activity))
                "createOrUpdateEvent" -> result.success(upsertEvent(activity, call))
                "deleteEvent" -> result.success(deleteEvent(activity, call))
                else -> result.notImplemented()
            }
        } catch (error: SecurityException) {
            result.error("permission_denied", error.message, null)
        } catch (error: Exception) {
            result.error("calendar_error", error.message, null)
        }
    }

    fun hasPermissions(activity: Activity): Boolean = PERMISSIONS.all {
        ContextCompat.checkSelfPermission(activity, it) == PackageManager.PERMISSION_GRANTED
    }

    private fun listCalendars(activity: Activity): List<Map<String, Any?>> {
        val calendars = mutableListOf<Map<String, Any?>>()
        val projection = arrayOf(
            CalendarContract.Calendars._ID,
            CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
            CalendarContract.Calendars.ACCOUNT_NAME,
            CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL,
        )
        activity.contentResolver.query(
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

    private fun upsertEvent(activity: Activity, call: MethodCall): String? {
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
            if (activity.contentResolver.update(uri, values, null, null) > 0) {
                return eventId
            }
            // The event was deleted in the calendar app — fall through and
            // create a fresh one so the meeting is never silently lost.
        }

        val newUri = activity.contentResolver
            .insert(CalendarContract.Events.CONTENT_URI, values) ?: return null
        val newId = newUri.lastPathSegment ?: return null
        if (reminderMinutes != null && reminderMinutes >= 0) {
            try {
                activity.contentResolver.insert(
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

    private fun deleteEvent(activity: Activity, call: MethodCall): Boolean {
        val eventId = call.argument<String>("eventId") ?: return false
        val uri = ContentUris.withAppendedId(
            CalendarContract.Events.CONTENT_URI,
            eventId.toLong(),
        )
        return activity.contentResolver.delete(uri, null, null) > 0
    }
}
