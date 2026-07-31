"""
config.py

App configuration management powered by Pydantic Settings v2.
"""

from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "Elly SOS Backend"
    VERSION: str = "2.0.0"
    API_V1_STR: str = "/v1"

    # Security & Auth
    SECRET_KEY: str = "elly_sos_super_secret_jwt_key_32_bytes_min_prod"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    ALGORITHM: str = "HS256"

    # CORS & Networks
    ALLOWED_ORIGINS: List[str] = ["*"]

    # Database & Redis
    DATABASE_URL: str = "sqlite+aiosqlite:///./elly_sos.db"
    REDIS_URL: str = "redis://localhost:6379/0"

    # Emergency Configurations
    DEFAULT_EMERGENCY_NUMBER: str = "112"
    DEFAULT_COUNTRY_CODE: str = "IN"

    # Cloud AI & STT Integrations
    GROQ_API_KEY: str = ""

    # ── Sherpa-ONNX SenseVoice CTC (On-Device STT) ───────────────────────────
    # Adapted from offline-sense-voice-ctc-decode-files.py
    # Download: https://github.com/k2-fsa/sherpa-onnx/releases/tag/asr-models
    #   sherpa-onnx-sense-voice-zh-en-ja-ko-yue-int8-2024-07-17.tar.bz2
    SHERPA_SENSE_VOICE_MODEL: str = ""   # e.g. ./models/sense-voice/model.int8.onnx
    SHERPA_SENSE_VOICE_TOKENS: str = ""  # e.g. ./models/sense-voice/tokens.txt

    # Silero VAD (Voice Activity Detection) — used with SenseVoice for segmentation
    # Download: https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/silero_vad.onnx
    SHERPA_SILERO_VAD_MODEL: str = ""    # e.g. ./models/silero_vad.onnx

    # Number of threads for Sherpa-ONNX inference (default: 2)
    SHERPA_NUM_THREADS: int = 2

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore"
    )


settings = Settings()
