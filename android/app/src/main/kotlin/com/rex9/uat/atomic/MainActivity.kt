package com.rex9.uat.atomic

import android.content.pm.PackageManager
import android.os.Build
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
