package com.elly.elly

import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import android.content.Context
import android.util.Log
import java.io.File
import java.nio.FloatBuffer
import java.nio.LongBuffer

/**
 * SileroOnnxVadEngine.kt
 *
 * Kotlin wrapper for the **official** Silero VAD ONNX model
 * (silero-vad/src/silero_vad/data/silero_vad.onnx, 2.3 MB).
 *
 * Official stock-model tensor spec (from silero-vad/examples/onnx_sequence/run.py):
 *   Inputs:
 *     - "input"  : Float32 [1, 576]  — 64-sample context + 512-sample frame
 *     - "state"  : Float32 [2, 1, 128] — LSTM state (hidden + cell concatenated)
 *     - "sr"     : Int64 scalar      — sample rate (16000)
 *   Outputs:
 *     - "output" : Float32 [1, 1]   — speech probability
 *     - "stateN" : Float32 [2, 1, 128] — updated LSTM state
 *
 * Reference: silero-vad/src/silero_vad/utils_vad.py  OnnxWrapper.__call__
 *            silero-vad/examples/onnx_sequence/run.py run_stock()
 */
class SileroOnnxVadEngine(private val context: Context) {

    companion object {
        private const val TAG          = "SileroOnnxVadEngine"
        private const val FRAME_SIZE   = 512   // samples at 16 kHz  (~32 ms)
        private const val CONTEXT_SIZE = 64    // context samples prepended to each frame
        private const val INPUT_SIZE   = FRAME_SIZE + CONTEXT_SIZE  // 576
        private const val SAMPLE_RATE  = 16000L

        // LSTM state dimensions: [2, 1, 128]
        private const val STATE_DIM0 = 2
        private const val STATE_DIM1 = 1
        private const val STATE_DIM2 = 128
    }

    private var ortEnv: OrtEnvironment? = null
    private var ortSession: OrtSession? = null

    // Rolling context window — last 64 samples of the previous frame
    private var context64 = FloatArray(CONTEXT_SIZE)

    // Concatenated LSTM state [2, 1, 128] — matches official OnnxWrapper._state layout
    private var lstmState = Array(STATE_DIM0) { Array(STATE_DIM1) { FloatArray(STATE_DIM2) } }

    private var isInitialized = false

    init {
        initEngine()
    }

    // ── Initialisation ─────────────────────────────────────────────────────────

    private fun initEngine() {
        try {
            ortEnv = OrtEnvironment.getEnvironment()
            val opts = OrtSession.SessionOptions().apply {
                setInterOpNumThreads(1)
                setIntraOpNumThreads(1)
                addCPU(true)
            }
            val modelBytes = loadModelBytes()
            if (modelBytes != null && modelBytes.isNotEmpty()) {
                ortSession = ortEnv?.createSession(modelBytes, opts)
                isInitialized = true
                Log.i(TAG, "🟢 Silero VAD (official) ONNX Session initialized (${modelBytes.size} bytes)")
            } else {
                Log.e(TAG, "🔴 silero_vad.onnx not found in assets – RMS fallback active")
            }
        } catch (e: Exception) {
            Log.e(TAG, "🔴 ONNX Runtime init error: ${e.message}", e)
        }
    }

    private fun loadModelBytes(): ByteArray? {
        // Flutter APK bundles assets under flutter_assets/
        val assetPaths = arrayOf(
            "flutter_assets/assets/models/silero_vad.onnx",
            "assets/models/silero_vad.onnx",
            "flutter_assets/silero_vad.onnx",
            "silero_vad.onnx"
        )
        for (path in assetPaths) {
            try {
                context.assets.open(path).use { stream ->
                    val bytes = stream.readBytes()
                    if (bytes.isNotEmpty()) {
                        Log.i(TAG, "🟢 Loaded from Assets '$path' (${bytes.size} bytes)")
                        return bytes
                    }
                }
            } catch (_: Exception) { /* try next */ }
        }
        return null
    }

    // ── State reset ────────────────────────────────────────────────────────────

    fun resetStates() {
        context64   = FloatArray(CONTEXT_SIZE)
        lstmState   = Array(STATE_DIM0) { Array(STATE_DIM1) { FloatArray(STATE_DIM2) } }
        Log.i(TAG, "Reset Silero VAD state (official model, 128-dim)")
    }

    // ── Inference ──────────────────────────────────────────────────────────────

    /**
     * Run one 512-sample PCM frame through the official Silero VAD model.
     *
     * Following official OnnxWrapper.__call__:
     *   x_with_ctx = cat([context64, frame512])  → shape [1, 576]
     *   output, stateN = session.run(['input', 'state', 'sr'])
     *   context64 = x_with_ctx[-64:]
     *
     * @param pcm512 Normalized Float32 samples in [-1.0, 1.0] (exactly 512 samples).
     * @return Speech probability in [0.0, 1.0].
     */
    @Synchronized
    fun processFrame(pcm512: FloatArray): Float {
        if (!isInitialized || ortSession == null || ortEnv == null) {
            return rmsEnergyFallback(pcm512)
        }

        val env     = ortEnv     ?: return rmsEnergyFallback(pcm512)
        val session = ortSession ?: return rmsEnergyFallback(pcm512)

        // 1. Build [1, 576]: context64 ++ frame512
        val inputVec = FloatArray(INPUT_SIZE)
        System.arraycopy(context64, 0, inputVec, 0, CONTEXT_SIZE)
        val frameSamples = minOf(pcm512.size, FRAME_SIZE)
        System.arraycopy(pcm512, 0, inputVec, CONTEXT_SIZE, frameSamples)
        // Wrap in [1, 576] 2-D array
        val inputArr = Array(1) { inputVec }

        // 2. SR scalar
        val srArr = longArrayOf(SAMPLE_RATE)

        var inputTensor:  OnnxTensor? = null
        var stateTensor:  OnnxTensor? = null
        var srTensor:     OnnxTensor? = null
        var result: OrtSession.Result? = null

        return try {
            inputTensor = OnnxTensor.createTensor(env, inputArr)
            stateTensor = OnnxTensor.createTensor(env, lstmState)
            srTensor    = OnnxTensor.createTensor(env, LongBuffer.wrap(srArr), longArrayOf(1))

            val inputs = mapOf(
                "input" to inputTensor,
                "state" to stateTensor,
                "sr"    to srTensor
            )
            result = session.run(inputs)

            // 3. Extract speech probability from output [1,1]
            val prob = extractProb(result)

            // 4. Update LSTM state from "stateN"
            updateState(result, "stateN")

            // 5. Roll context: last 64 samples of the input become next context
            System.arraycopy(inputVec, INPUT_SIZE - CONTEXT_SIZE, context64, 0, CONTEXT_SIZE)

            prob.coerceIn(0.0f, 1.0f)

        } catch (e: Exception) {
            Log.e(TAG, "Silero ONNX inference error: ${e.message}", e)
            rmsEnergyFallback(pcm512)
        } finally {
            inputTensor?.close()
            stateTensor?.close()
            srTensor?.close()
            result?.close()
        }
    }

    // ── Helpers ────────────────────────────────────────────────────────────────

    private fun extractProb(result: OrtSession.Result): Float {
        val outputObj = try {
            if (result.get("output").isPresent) result.get("output").get().value
            else result.get(0).value
        } catch (_: Exception) { return 0.0f }

        return when (outputObj) {
            is FloatArray     -> outputObj[0]
            is Array<*>       -> {
                val r0 = outputObj[0]
                when (r0) {
                    is FloatArray -> r0[0]
                    is Number     -> r0.toFloat()
                    else          -> 0.0f
                }
            }
            is FloatBuffer    -> outputObj.get(0)
            is Number         -> outputObj.toFloat()
            else              -> 0.0f
        }
    }

    private fun updateState(result: OrtSession.Result, name: String) {
        try {
            val obj = if (result.get(name).isPresent) result.get(name).get().value else return
            if (obj is Array<*>) {
                for (i in 0 until minOf(STATE_DIM0, obj.size)) {
                    val layer = obj[i]
                    if (layer is Array<*>) {
                        val cell = layer.getOrNull(0)
                        if (cell is FloatArray && cell.size == STATE_DIM2) {
                            System.arraycopy(cell, 0, lstmState[i][0], 0, STATE_DIM2)
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed updating state '$name': ${e.message}")
        }
    }

    /** RMS energy fallback — used only when ONNX is unavailable. */
    private fun rmsEnergyFallback(pcm: FloatArray): Float {
        var sumSq = 0.0
        for (s in pcm) sumSq += s * s.toDouble()
        val rms = Math.sqrt(sumSq / maxOf(1, pcm.size))
        return if (rms > 0.012) 0.88f else 0.0f
    }

    // ── Cleanup ────────────────────────────────────────────────────────────────

    fun close() {
        try {
            ortSession?.close()
            ortSession = null
            isInitialized = false
            Log.i(TAG, "Closed Silero VAD ONNX Session.")
        } catch (e: Exception) {
            Log.e(TAG, "Error closing ONNX session: ${e.message}")
        }
    }
}
