package com.rex9.uat.atomic

import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private var pendingCalendarPermission: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CalendarBridge.CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "requestPermissions") {
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                        // Calendar permissions are granted at install time pre-M.
                        result.success(true)
                    } else {
                        pendingCalendarPermission = result
                        requestPermissions(
                            CalendarBridge.PERMISSIONS,
                            CalendarBridge.PERMISSION_REQUEST_CODE,
                        )
                    }
                } else {
                    CalendarBridge.handle(this, call, result)
                }
            }

        // Deep-links the permission prompt straight to this app's
        // notification settings screen (the general app-info page hides the
        // toggle one level down — testers could not find it).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "atomicos/notifications")
            .setMethodCallHandler { call, result ->
                if (call.method == "openNotificationSettings") {
                    try {
                        startActivity(
                            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName),
                        )
                        result.success(true)
                    } catch (error: Exception) {
                        result.error("settings_unavailable", error.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == CalendarBridge.PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() &&
                grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            pendingCalendarPermission?.success(granted)
            pendingCalendarPermission = null
        }
    }
}
