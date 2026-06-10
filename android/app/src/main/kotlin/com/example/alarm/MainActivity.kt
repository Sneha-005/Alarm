package com.example.alarm

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private val CHANNEL = "com.example.alarm/alarm"
  private val PERMISSION_REQUEST_CODE = 100

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
      when (call.method) {
        "requestExactAlarmsPermission" -> {
          if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Android 12+ requires runtime permission request for SCHEDULE_EXACT_ALARM
            if (ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.SCHEDULE_EXACT_ALARM
              ) == PackageManager.PERMISSION_DENIED
            ) {
              ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.SCHEDULE_EXACT_ALARM),
                PERMISSION_REQUEST_CODE
              )
            }
          }
          result.success(null)
        }
        else -> result.notImplemented()
      }
    }
  }
}
