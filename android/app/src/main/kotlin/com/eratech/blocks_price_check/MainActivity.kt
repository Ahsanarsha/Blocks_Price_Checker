package com.eratech.blocks_price_check

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.eratech.blocks_price_check/kiosk_mode"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startKioskMode" -> {
                    startLockTask()
                    result.success("Kiosk Mode Started")
                }
                "stopKioskMode" -> {
                    stopLockTask()
                    result.success("Kiosk Mode Stopped")
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
