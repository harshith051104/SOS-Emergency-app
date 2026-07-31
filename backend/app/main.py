"""
main.py

FastAPI application entrypoint for Elly SOS Backend.
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.core.logging import logger
from app.database.session import engine, Base
from app.api.v1.emergency import router as emergency_router
from app.api.v1.auth import router as auth_router
from app.api.v1.health_passport import router as health_passport_router
from app.api.v1.sos_circle import router as sos_circle_router
from app.api.v1.responders import router as responders_router
from app.api.v1.telemetry import router as telemetry_router
from app.api.v1.assistant import router as assistant_router
from app.api.v1.stt import router as stt_router
from app.api.v1.websocket import router as ws_router
from app.services.sherpa_stt_service import sherpa_stt_service


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Initializing Elly SOS Backend (Python 3.12 + FastAPI)...")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    logger.info("Database tables initialized successfully.")

    # Initialize Sherpa-ONNX SenseVoice CTC (pre-loads model into memory)
    # Pattern from: offline-sense-voice-ctc-decode-files.py
    #   recognizer = sherpa_onnx.OfflineRecognizer.from_sense_voice(
    #       model=model, tokens=tokens, use_itn=True
    #   )
    import asyncio
    loop = asyncio.get_event_loop()
    ok = await loop.run_in_executor(None, sherpa_stt_service.initialize)
    if ok:
        logger.info("✅ Sherpa-ONNX SenseVoice CTC: Ready (on-device STT active)")
    else:
        logger.warning("⚠️  Sherpa-ONNX SenseVoice: Not available. Groq Whisper fallback active.")

    yield
    logger.info("Shutting down Elly SOS Backend...")


app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    docs_url=f"{settings.API_V1_STR}/docs",
    redoc_url=f"{settings.API_V1_STR}/redoc",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router, prefix=settings.API_V1_STR)
app.include_router(emergency_router, prefix=settings.API_V1_STR)
app.include_router(health_passport_router, prefix=settings.API_V1_STR)
app.include_router(sos_circle_router, prefix=settings.API_V1_STR)
app.include_router(responders_router, prefix=settings.API_V1_STR)
app.include_router(telemetry_router, prefix=settings.API_V1_STR)
app.include_router(assistant_router, prefix=settings.API_V1_STR)
app.include_router(stt_router, prefix=settings.API_V1_STR)
app.include_router(ws_router)


@app.get("/health", tags=["System Health"])
async def health_check():
    return {
        "status": "HEALTHY",
        "service": settings.PROJECT_NAME,
        "version": settings.VERSION
    }
