package com.elly.elly.runtime.inference

data class ModelSpec(
    val name: String,
    val version: String,
    val apiVersion: Int,
    val assetPath: String,
    val checksum: String,
    val ramRequiredMb: Int,
    val verified: Boolean = true
)

object ModelRegistry {
    val SILERO_VAD_V5 = ModelSpec(
        name = "Silero VAD",
        version = "5.0",
        apiVersion = 2,
        assetPath = "silero_vad.onnx",
        checksum = "f8a7c2e1b4d9",
        ramRequiredMb = 12
    )

    val SHERPA_SENSEVOICE_ASR = ModelSpec(
        name = "Sherpa-ONNX SenseVoice",
        version = "2025.1",
        apiVersion = 2,
        assetPath = "sensevoice_encoder.onnx",
        checksum = "e2c9a4f7b1d3",
        ramRequiredMb = 45
    )

    val ECAPA_TDNN_SPEAKER = ModelSpec(
        name = "ECAPA-TDNN",
        version = "1.2",
        apiVersion = 1,
        assetPath = "ecapa_tdnn.onnx",
        checksum = "b3d1c9e8f5a2",
        ramRequiredMb = 28
    )

    fun getAllModels(): List<ModelSpec> {
        return listOf(SILERO_VAD_V5, SHERPA_SENSEVOICE_ASR, ECAPA_TDNN_SPEAKER)
    }
}
