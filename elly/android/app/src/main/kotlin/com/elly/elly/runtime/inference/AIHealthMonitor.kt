package com.elly.elly.runtime.inference

import android.os.SystemClock

data class AiPerformanceMetrics(
    val vadLatencyMs: Long = 0,
    val sttLatencyMs: Long = 0,
    val totalProcessedFrames: Long = 0,
    val droppedFrames: Long = 0,
    val partialTranscriptsCount: Int = 0,
    val finalTranscriptsCount: Int = 0,
    val memoryPressureHigh: Boolean = false
)

class AIHealthMonitor {
    private var vadLatencySum: Long = 0
    private var vadCount: Long = 0
    private var sttLatencySum: Long = 0
    private var sttCount: Long = 0
    private var totalFrames: Long = 0
    private var droppedFrames: Long = 0
    private var partialCount: Int = 0
    private var finalCount: Int = 0

    fun recordVadLatency(durationMs: Long) {
        vadLatencySum += durationMs
        vadCount++
        totalFrames++
    }

    fun recordSttLatency(durationMs: Long, isPartial: Boolean) {
        sttLatencySum += durationMs
        sttCount++
        if (isPartial) partialCount++ else finalCount++
    }

    fun recordDroppedFrame() {
        droppedFrames++
    }

    fun getMetrics(): AiPerformanceMetrics {
        val avgVad = if (vadCount > 0) vadLatencySum / vadCount else 0
        val avgStt = if (sttCount > 0) sttLatencySum / sttCount else 0
        return AiPerformanceMetrics(
            vadLatencyMs = avgVad,
            sttLatencyMs = avgStt,
            totalProcessedFrames = totalFrames,
            droppedFrames = droppedFrames,
            partialTranscriptsCount = partialCount,
            finalTranscriptsCount = finalCount,
            memoryPressureHigh = (Runtime.getRuntime().freeMemory() < 16 * 1024 * 1024)
        )
    }

    fun reset() {
        vadLatencySum = 0
        vadCount = 0
        sttLatencySum = 0
        sttCount = 0
        totalFrames = 0
        droppedFrames = 0
        partialCount = 0
        finalCount = 0
    }
}
