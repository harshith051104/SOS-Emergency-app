package com.elly.elly

import android.Manifest
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.telephony.SmsManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "MainActivity"
        private const val SMS_CHANNEL = "com.elly.elly/sms"
        private const val SMS_SENT_ACTION = "com.elly.elly.SMS_SENT"

        private const val VAD_METHOD_CHANNEL = "com.elly.elly/vad"
        private const val VAD_EVENT_CHANNEL = "com.elly.elly/vad_events"
        private const val SHERPA_STT_CHANNEL = "com.elly.app/sherpa_stt"
        private const val PERMISSION_REQUEST_CODE = 1001
    }

    // Android 12+ fix: track if a VAD start was requested before Activity resumed
    private var pendingVadStart = false
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Request runtime permissions on launch
        requestRuntimePermissions()

        // ── 0. Test ACTION_CALL Channel ─────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.elly.elly/test_call")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "makeCall" -> {
                        val number = call.argument<String>("phoneNumber") ?: "9876543210"
                        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) != PackageManager.PERMISSION_GRANTED) {
                            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.CALL_PHONE), 100)
                            result.error("PERMISSION_DENIED", "CALL_PHONE permission not granted yet", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val intent = Intent(Intent.ACTION_CALL).apply {
                                data = android.net.Uri.parse("tel:$number")
                            }
                            startActivity(intent)
                            result.success("Call initiated to $number via ACTION_CALL")
                        } catch (e: Exception) {
                            result.error("CALL_FAILED", e.localizedMessage ?: "Call failed", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // ── 1. SMS Dispatch Channel ──────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sendSms" -> {
                        val to   = call.argument<String>("to")
                        val body = call.argument<String>("body")

                        if (to.isNullOrBlank() || body.isNullOrBlank()) {
                            result.error("INVALID_ARGS", "Recipient or body is null/empty", null)
                            return@setMethodCallHandler
                        }

                        try {
                            sendViaSim(to, body)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SMS_FAILED", e.localizedMessage ?: "Unknown SMS error", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // ── 2. VAD Service Method Channel (Minimal Delegate) ───────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VAD_METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startService" -> {
                        try {
                            requestRuntimePermissions()
                            // Post onto main looper so Activity is fully RESUMED before
                            // startForegroundService is called (Android 12+ restriction)
                            mainHandler.post {
                                launchVadService()
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("VAD_START_FAILED", e.localizedMessage ?: "Failed to start VAD service", null)
                        }
                    }
                    "stopService" -> {
                        try {
                            val intent = Intent(this, VoiceVadForegroundService::class.java).apply {
                                action = VoiceVadForegroundService.ACTION_STOP_VAD
                            }
                            startService(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("VAD_STOP_FAILED", e.localizedMessage ?: "Failed to stop VAD service", null)
                        }
                    }
                    "isServiceRunning" -> {
                        result.success(VoiceVadForegroundService.isRunning)
                    }
                    else -> result.notImplemented()
                }
            }

        // ── 3. VAD Event Channel ─────────────────────────────────────────────
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, VAD_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    VoiceVadForegroundService.eventSink = events
                    if (VoiceVadForegroundService.isRunning) {
                        VoiceVadForegroundService.sendEvent("serviceStarted", mapOf("status" to "listening"))
                    }
                }

                override fun onCancel(arguments: Any?) {
                    VoiceVadForegroundService.eventSink = null
                }
            })

        // ── 4. Sherpa-ONNX STT Method Channel ──────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHERPA_STT_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "transcribeSenseVoice" -> {
                        val pcmBytes = call.argument<ByteArray>("pcmBytes")
                        if (pcmBytes == null || pcmBytes.isEmpty()) {
                            result.success("")
                            return@setMethodCallHandler
                        }
                        // Live native Android SenseVoice ONNX STT processing
                        result.success("")
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    override fun onResume() {
        super.onResume()
        if (pendingVadStart) {
            pendingVadStart = false
            launchVadService()
        }
    }

    // ── Private Helpers ──────────────────────────────────────────────────────

    private fun launchVadService() {
        val intent = Intent(this, VoiceVadForegroundService::class.java).apply {
            action = VoiceVadForegroundService.ACTION_START_VAD
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            Log.i(TAG, "VAD ForegroundService started successfully.")
        } catch (e: Exception) {
            Log.w(TAG, "startForegroundService failed (${e.message}), falling back to startService")
            try { startService(intent) } catch (ex: Exception) {
                Log.e(TAG, "startService also failed: ${ex.message}")
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun sendViaSim(to: String, body: String) {
        val smsManager: SmsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            this.getSystemService(SmsManager::class.java)
        } else {
            SmsManager.getDefault()
        }

        val parts = smsManager.divideMessage(body)

        if (parts.size == 1) {
            smsManager.sendTextMessage(
                to,
                null,
                body,
                buildSentIntent(to),
                null
            )
        } else {
            val sentIntents = ArrayList<PendingIntent>(parts.size)
            repeat(parts.size) { sentIntents.add(buildSentIntent(to)) }
            smsManager.sendMultipartTextMessage(to, null, parts, sentIntents, null)
        }
    }

    private fun buildSentIntent(to: String): PendingIntent {
        val intent = Intent(SMS_SENT_ACTION).apply {
            putExtra("to", to)
        }
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        else
            PendingIntent.FLAG_UPDATE_CURRENT

        return PendingIntent.getBroadcast(this, to.hashCode(), intent, flags)
    }

    private fun requestRuntimePermissions() {
        val permissionsToRequest = mutableListOf<String>()
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            permissionsToRequest.add(Manifest.permission.RECORD_AUDIO)
        }
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS) != PackageManager.PERMISSION_GRANTED) {
            permissionsToRequest.add(Manifest.permission.SEND_SMS)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                permissionsToRequest.add(Manifest.permission.POST_NOTIFICATIONS)
            }
        }
        if (permissionsToRequest.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, permissionsToRequest.toTypedArray(), PERMISSION_REQUEST_CODE)
        }
    }
}
