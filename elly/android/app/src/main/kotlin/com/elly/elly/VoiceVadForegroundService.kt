package com.elly.elly

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.util.Log
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

class VoiceVadForegroundService : Service() {

    companion object {
        private const val TAG = "VoiceVadService"
        const val NOTIFICATION_ID = 1002
        const val CHANNEL_ID = "elly_voice_vad_channel"

        const val ACTION_START_VAD = "com.elly.elly.ACTION_START_VAD"
        const val ACTION_STOP_VAD = "com.elly.elly.ACTION_STOP_VAD"

        var isRunning: Boolean = false
            private set

        var eventSink: EventChannel.EventSink? = null
        private val mainHandler = Handler(Looper.getMainLooper())

        fun sendEvent(eventName: String, data: Map<String, Any?> = emptyMap()) {
            val payload = HashMap<String, Any?>()
            payload["event"] = eventName
            payload["timestamp"] = System.currentTimeMillis()
            payload.putAll(data)
            mainHandler.post {
                try {
                    eventSink?.success(payload)
                } catch (e: Exception) {
                    Log.e(TAG, "Failed sending event to Flutter sink: ${e.message}")
                }
            }
        }
    }

    private val binder = LocalBinder()
    private var audioRecord: AudioRecord? = null
    private var isRecording = false
    private var recordingThread: Thread? = null

    private var sileroEngine: SileroOnnxVadEngine? = null

    private var audioManager: AudioManager? = null
    private var audioReceiverRegistered = false

    // Pre-roll buffer: keeps the last 5 frames (~160ms) so they can be
    // replayed to Flutter immediately when speech onset is declared.
    private val preRollBuffer = ArrayDeque<ByteArray>(5)
    private val preRollMaxFrames = 5
    private val noisyAudioReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (AudioManager.ACTION_AUDIO_BECOMING_NOISY == intent?.action) {
                Log.i(TAG, "Audio output becoming noisy (headset unplugged)")
                sendEvent("audioRoutingChanged", mapOf("reason" to "headset_unplugged"))
            }
        }
    }

    inner class LocalBinder : Binder() {
        fun getService(): VoiceVadForegroundService = this@VoiceVadForegroundService
    }

    override fun onBind(intent: Intent?): IBinder = binder

    override fun onCreate() {
        super.onCreate()
        Log.i(TAG, "VoiceVadForegroundService created")
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        sileroEngine = SileroOnnxVadEngine(this)
        createNotificationChannel()
        registerReceivers()
    }

    override fun onDestroy() {
        Log.i(TAG, "VoiceVadForegroundService destroying...")
        stopAudioCaptureThread()
        sileroEngine?.close()
        sileroEngine = null
        unregisterReceivers()
        isRunning = false
        super.onDestroy()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        Log.i(TAG, "onStartCommand received action: $action")

        when (action) {
            ACTION_STOP_VAD -> {
                stopVadService()
                return START_NOT_STICKY
            }
            else -> {
                sileroEngine?.resetStates()
                startVadService()
                return START_STICKY
            }
        }
    }

    private fun startVadService() {
        if (isRunning) {
            Log.i(TAG, "Service is already running")
            return
        }

        try {
            val notification = createNotification()
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    startForeground(
                        NOTIFICATION_ID,
                        notification,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
                    )
                } else {
                    startForeground(NOTIFICATION_ID, notification)
                }
            } catch (e: Exception) {
                Log.w(TAG, "startForeground exception: ${e.message}, running in service mode")
                try {
                    startForeground(NOTIFICATION_ID, notification)
                } catch (_: Exception) {}
            }
            isRunning = true
            sendEvent("serviceStarted", mapOf("status" to "listening"))
            startAudioCaptureThread()
        } catch (e: Exception) {
            Log.e(TAG, "Failed starting foreground service: ${e.message}", e)
            sendEvent("error", mapOf("message" to (e.localizedMessage ?: "Failed to start service")))
            stopSelf()
        }
    }

    private fun stopVadService() {
        Log.i(TAG, "Stopping VoiceVadForegroundService...")
        stopAudioCaptureThread()
        isRunning = false
        sendEvent("serviceStopped")
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun startAudioCaptureThread() {
        if (isRecording) return

        // Request transient speech audio focus to un-mute hardware mic on Knox/OneUI
        try {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            if (audioManager != null) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val focusRequest = android.media.AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE)
                        .setAudioAttributes(
                            android.media.AudioAttributes.Builder()
                                .setUsage(android.media.AudioAttributes.USAGE_ASSISTANT)
                                .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SPEECH)
                                .build()
                        )
                        .build()
                    audioManager.requestAudioFocus(focusRequest)
                } else {
                    @Suppress("DEPRECATION")
                    audioManager.requestAudioFocus(null, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE)
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "AudioFocus request warning: ${e.message}")
        }

        val sampleRate = 16000
        val channelConfig = AudioFormat.CHANNEL_IN_MONO
        val audioFormat = AudioFormat.ENCODING_PCM_16BIT
        val minBufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)
        val bufferSize = Math.max(minBufferSize, 2048)

        val audioSources = intArrayOf(
            MediaRecorder.AudioSource.MIC,
            MediaRecorder.AudioSource.DEFAULT,
            MediaRecorder.AudioSource.CAMCORDER,
            MediaRecorder.AudioSource.VOICE_RECOGNITION,
            MediaRecorder.AudioSource.VOICE_COMMUNICATION,
            MediaRecorder.AudioSource.UNPROCESSED
        )

        var initializedRecord: AudioRecord? = null

        for (source in audioSources) {
            try {
                val rec = AudioRecord(
                    source,
                    sampleRate,
                    channelConfig,
                    audioFormat,
                    bufferSize
                )
                if (rec.state == AudioRecord.STATE_INITIALIZED) {
                    initializedRecord = rec
                    Log.i(TAG, "Successfully initialized AudioRecord with source: $source")
                    break
                } else {
                    rec.release()
                }
            } catch (e: Exception) {
                Log.w(TAG, "AudioRecord init failed for source $source: ${e.message}")
            }
        }

        if (initializedRecord == null) {
            Log.e(TAG, "AudioRecord failed to initialize on all audio sources")
            sendEvent("error", mapOf("message" to "Microphone hardware initialization failed"))
            return
        }

        audioRecord = initializedRecord

        try {
            audioRecord?.startRecording()
            isRecording = true

            recordingThread = Thread({
                val buffer = ShortArray(512) // 32ms frames @ 16kHz
                var logCounter = 0
                while (isRecording && !Thread.currentThread().isInterrupted) {
                    val readSize = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        audioRecord?.read(buffer, 0, buffer.size, AudioRecord.READ_BLOCKING) ?: 0
                    } else {
                        audioRecord?.read(buffer, 0, buffer.size) ?: 0
                    }

                    if (readSize > 0) {
                        evaluatePcmFrame(buffer, readSize)
                    } else {
                        logCounter++
                        if (logCounter % 50 == 1) {
                            Log.w(TAG, "AudioRecord read returned $readSize")
                        }
                        try {
                            Thread.sleep(10)
                        } catch (e: InterruptedException) {
                            break
                        }
                    }
                }
            }, "VoiceVadAudioCapture")

            recordingThread?.start()
            Log.i(TAG, "Audio capture thread started successfully")
        } catch (e: SecurityException) {
            Log.e(TAG, "Permission denied for AudioRecord: ${e.message}")
            sendEvent("error", mapOf("message" to "Microphone permission revoked"))
        } catch (e: Exception) {
            Log.e(TAG, "Exception starting audio recording: ${e.message}", e)
            sendEvent("error", mapOf("message" to (e.localizedMessage ?: "Recording error")))
        }
    }

    private fun stopAudioCaptureThread() {
        isRecording = false
        recordingThread?.interrupt()
        recordingThread = null

        try {
            if (audioRecord?.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
                audioRecord?.stop()
            }
            audioRecord?.release()
            audioRecord = null
            Log.i(TAG, "Audio capture thread stopped cleanly")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping AudioRecord: ${e.message}")
        }
    }

    // ── Dynamic Hardware AudioSource Auto-Switching ──────────────────────
    private var lastSpeechState = false
    private var speechFrameCount = 0
    private var silenceFrameCount = 0
    private val speechThreshold = 0.35f
    private val negThreshold = 0.20f

    private var currentSourceIndex = 0
    private var zeroAmplitudeFrameCount = 0
    private var frameCounter = 0

    private val audioSources = intArrayOf(
        MediaRecorder.AudioSource.MIC,
        MediaRecorder.AudioSource.VOICE_RECOGNITION,
        MediaRecorder.AudioSource.DEFAULT,
        MediaRecorder.AudioSource.CAMCORDER,
        MediaRecorder.AudioSource.VOICE_COMMUNICATION,
        MediaRecorder.AudioSource.UNPROCESSED
    )

    private fun switchAudioSource(newSource: Int) {
        try {
            audioRecord?.stop()
            audioRecord?.release()
        } catch (e: Exception) {
            Log.w(TAG, "Stop error during audio source switch: ${e.message}")
        }

        val sampleRate = 16000
        val channelConfig = AudioFormat.CHANNEL_IN_MONO
        val audioFormat = AudioFormat.ENCODING_PCM_16BIT
        val minBufferSize = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)
        val bufferSize = Math.max(minBufferSize, 2048)

        try {
            val rec = AudioRecord(newSource, sampleRate, channelConfig, audioFormat, bufferSize)
            if (rec.state == AudioRecord.STATE_INITIALIZED) {
                rec.startRecording()
                audioRecord = rec
                Log.i(TAG, "Successfully auto-switched to AudioRecord Source: $newSource")
                sendEvent("error", mapOf("message" to "🔄 Auto-switched to AudioSource $newSource! Checking mic signal..."))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed switching to AudioSource $newSource: ${e.message}")
            sendEvent("error", mapOf("message" to "❌ Failed AudioSource $newSource: ${e.message}"))
        }
    }

    private fun evaluatePcmFrame(buffer: ShortArray, length: Int) {
        val startTimeNs = System.nanoTime()
        val pcmFloat = FloatArray(length)
        var sumSquares = 0.0
        var maxAmplitude = 0

        for (i in 0 until length) {
            val sampleShort = buffer[i].toInt()
            val absVal = Math.abs(sampleShort)
            if (absVal > maxAmplitude) {
                maxAmplitude = absVal
            }
            val sampleFloat = sampleShort / 32768.0f  // normalize to [-1.0, 1.0] — no gain
            pcmFloat[i] = sampleFloat
            sumSquares += (sampleFloat * sampleFloat).toDouble()
        }
        val rms = Math.sqrt(sumSquares / length)

        // Detect silent mic channels (pure 0s) and auto-switch audio source
        if (maxAmplitude == 0) {
            zeroAmplitudeFrameCount++
            if (zeroAmplitudeFrameCount >= 20) {
                zeroAmplitudeFrameCount = 0
                val oldSource = audioSources[currentSourceIndex]
                currentSourceIndex = (currentSourceIndex + 1) % audioSources.size
                val newSource = audioSources[currentSourceIndex]
                val msg = "⚠️ AudioSource $oldSource returned pure 0s. Auto-switching to Source $newSource..."
                Log.w(TAG, msg)
                sendEvent("error", mapOf("message" to msg))
                switchAudioSource(newSource)
            }
        } else {
            zeroAmplitudeFrameCount = 0
        }

        // 1. Official Silero VAD ONNX Neural Inference Pass
        val engine = sileroEngine
        val rawProb = engine?.processFrame(pcmFloat) ?: 0.0f
        val elapsedMs = (System.nanoTime() - startTimeNs) / 1_000_000.0

        // Hardware amplitude guard: only boost speechProb if amplitude indicates real voice.
        // 3500 / 32767 ≈ 10.7% — filters out quiet ambient noise while still catching soft speech.
        val isHardwareVoiceDetected = maxAmplitude > 3500
        val speechProbability = if (isHardwareVoiceDetected) {
            Math.max(rawProb, 0.85f)
        } else {
            rawProb  // trust the ONNX model when quiet
        }

        // Official Silero VAD Hysteresis State Machine
        val isSpeechFrame = speechProbability >= 0.35f

        if (isSpeechFrame) {
            speechFrameCount++
            silenceFrameCount = 0
        } else {
            silenceFrameCount++
            speechFrameCount = 0
        }

        // Periodic Telemetry Update (Every ~96ms)
        frameCounter++
        if (frameCounter % 3 == 0) {
            sendEvent("vadTelemetryUpdate", mapOf(
                "probability" to speechProbability,
                "rawProb" to rawProb,
                "rms" to rms,
                "maxAmplitude" to maxAmplitude,
                "readSize" to length,
                "isSpeechFrame" to isSpeechFrame,
                "inferenceMs" to elapsedMs
            ))
        }
        if (frameCounter % 10 == 0) {
            Log.i(TAG, "PCM Diagnostic: readSize=$length, maxAmp=$maxAmplitude, rms=${"%.6f".format(rms)}, rawProb=${"%.3f".format(rawProb)}, speechProb=${"%.3f".format(speechProbability)}, isSpeech=$isSpeechFrame")
        }

        // Onset: 3 consecutive speech frames (~96ms) required to avoid noise bursts triggering a session.
        // Offset: 10 silence frames (~320ms) or 3s max continuous speech.
        if (!lastSpeechState && speechFrameCount >= 3) {
            lastSpeechState = true

            // 1. Signal speech onset first so the Flutter buffer service starts accumulating
            sendEvent("speechDetected", mapOf(
                "probability" to speechProbability,
                "rms" to rms,
                "maxAmplitude" to maxAmplitude,
                "inferenceMs" to elapsedMs
            ))
            Log.i(TAG, "🗣️ Official Silero ONNX Speech Detected! (prob=$speechProbability, maxAmp=$maxAmplitude, latency=${elapsedMs}ms)")

            // 2. Replay pre-roll frames (captured before onset) into the now-active buffer
            for (preFrame in preRollBuffer) {
                sendEvent("pcmFrame", mapOf(
                    "pcm" to preFrame,
                    "probability" to speechProbability,
                    "rms" to rms,
                    "maxAmplitude" to maxAmplitude,
                    "inferenceMs" to elapsedMs
                ))
            }
            preRollBuffer.clear()
        } else if (lastSpeechState && (silenceFrameCount >= 10 || speechFrameCount >= 95)) {
            lastSpeechState = false
            speechFrameCount = 0
            silenceFrameCount = 0
            sendEvent("speechEnded", mapOf(
                "probability" to speechProbability,
                "rms" to rms,
                "maxAmplitude" to maxAmplitude,
                "inferenceMs" to elapsedMs
            ))
            Log.i(TAG, "🔇 Official Silero ONNX Speech Ended. (prob=$speechProbability)")
        }

        // Stream raw PCM bytes to Flutter during speech for STT.
        // Also accumulate a rolling pre-roll ring buffer for pre-onset context.
        val pcmBytes = ByteArray(length * 2)
        for (i in 0 until length) {
            val sample = buffer[i].toInt()
            pcmBytes[i * 2] = (sample and 0xFF).toByte()
            pcmBytes[i * 2 + 1] = ((sample shr 8) and 0xFF).toByte()
        }

        if (lastSpeechState) {
            // Active speech session: stream directly to Flutter
            sendEvent("pcmFrame", mapOf(
                "pcm" to pcmBytes,
                "probability" to speechProbability,
                "rms" to rms,
                "maxAmplitude" to maxAmplitude,
                "inferenceMs" to elapsedMs
            ))
        } else {
            // Not yet in a session: keep rolling pre-roll buffer
            if (preRollBuffer.size >= preRollMaxFrames) preRollBuffer.removeFirst()
            preRollBuffer.addLast(pcmBytes)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "ELLY Voice Protection Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Background Voice Activity Detection for ELLY Emergency Protection"
                setShowBadge(false)
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            else
                PendingIntent.FLAG_UPDATE_CURRENT
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        return builder
            .setContentTitle("ELLY Voice Protection")
            .setContentText("Voice activity monitoring active")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }

    private fun registerReceivers() {
        if (!audioReceiverRegistered) {
            try {
                registerReceiver(noisyAudioReceiver, IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY))
                audioReceiverRegistered = true
            } catch (e: Exception) {
                Log.w(TAG, "Could not register noisy audio receiver: ${e.message}")
            }
        }
    }

    private fun unregisterReceivers() {
        if (audioReceiverRegistered) {
            try {
                unregisterReceiver(noisyAudioReceiver)
                audioReceiverRegistered = false
            } catch (e: Exception) {
                Log.w(TAG, "Error unregistering receiver: ${e.message}")
            }
        }
    }
}
