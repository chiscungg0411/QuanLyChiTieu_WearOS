package com.chiscung.quanlychitieu

import android.content.ComponentName
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.wear.watchface.complications.datasource.ComplicationDataSourceUpdateRequester

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.chiscung.quanlychitieu/complication"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateComplication" -> {
                    try {
                        val requester = ComplicationDataSourceUpdateRequester.create(
                            applicationContext,
                            ComponentName(applicationContext, VFinanceComplicationService::class.java)
                        )
                        requester.requestUpdateAll()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UPDATE_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
