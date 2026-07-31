package com.elly.elly.runtime.pipeline

data class EvidenceScores(
    val intentScore: Double = 0.0,
    val transcriptConfidence: Double = 0.0,
    val speakerVerifiedScore: Double = 0.0,
    val biomarkerStressScore: Double = 0.0,
    val sensorImpactScore: Double = 0.0,
    val vadSpeechProb: Double = 0.0
)

data class FusionResult(
    val compositeEmergencyScore: Double, // 0.0 to 1.0 (0% to 100%)
    val isEmergencyConfirmed: Boolean,
    val primaryTriggerSource: String,
    val confidenceGrade: String
)

class ConfidenceFusionEngine(
    private val emergencyThreshold: Double = 0.70
) {
    fun fuseEvidence(evidence: EvidenceScores): FusionResult {
        // Weighted composite calculation:
        // Intent: 35%, VAD/Transcript: 25%, Biomarkers: 20%, Speaker: 10%, Impact: 10%
        val weightedScore = (evidence.intentScore * 0.35) +
                (evidence.transcriptConfidence * 0.25) +
                (evidence.biomarkerStressScore * 0.20) +
                (evidence.speakerVerifiedScore * 0.10) +
                (evidence.sensorImpactScore * 0.10)

        // Instant emergency bypass override if Intent is high-confidence critical (>= 0.90)
        val finalScore = if (evidence.intentScore >= 0.90) {
            Math.max(weightedScore, evidence.intentScore)
        } else {
            weightedScore
        }

        val isConfirmed = finalScore >= emergencyThreshold

        val grade = when {
            finalScore >= 0.90 -> "CRITICAL"
            finalScore >= 0.70 -> "HIGH"
            finalScore >= 0.50 -> "MODERATE"
            else -> "LOW"
        }

        val triggerSource = when {
            evidence.intentScore >= 0.85 -> "VOICE_INTENT"
            evidence.sensorImpactScore >= 0.85 -> "FALL_IMPACT"
            evidence.biomarkerStressScore >= 0.85 -> "VOCAL_STRESS"
            else -> "MULTI_FACTOR_FUSION"
        }

        return FusionResult(
            compositeEmergencyScore = finalScore,
            isEmergencyConfirmed = isConfirmed,
            primaryTriggerSource = triggerSource,
            confidenceGrade = grade
        )
    }
}
