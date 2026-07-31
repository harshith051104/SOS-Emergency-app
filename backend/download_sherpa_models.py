#!/usr/bin/env python3
"""
download_sherpa_models.py

Downloads Sherpa-ONNX SenseVoice CTC model + Silero VAD model
into backend/models/ for local on-device STT.

Adapted from the instructions in:
  sherpa-onnx/python-api-examples/offline-sense-voice-ctc-decode-files.py
  sherpa-onnx/python-api-examples/offline-sense-voice-ctc-decode-files-with-hr.py

Usage:
  cd backend
  python download_sherpa_models.py

After running, update your backend/.env:
  SHERPA_SENSE_VOICE_MODEL=./models/sense-voice/model.int8.onnx
  SHERPA_SENSE_VOICE_TOKENS=./models/sense-voice/tokens.txt
  SHERPA_SILERO_VAD_MODEL=./models/silero_vad.onnx
"""

import os
import sys
import tarfile
import urllib.request
from pathlib import Path

MODELS_DIR = Path("./models")
SENSE_VOICE_DIR = MODELS_DIR / "sense-voice"
SENSE_VOICE_DIR.mkdir(parents=True, exist_ok=True)

# ── SenseVoice int8 model (zh/en/ja/ko/yue multilingual) ─────────────────────
SENSE_VOICE_ARCHIVE = "sherpa-onnx-sense-voice-zh-en-ja-ko-yue-int8-2024-07-17.tar.bz2"
SENSE_VOICE_URL = (
    "https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/"
    + SENSE_VOICE_ARCHIVE
)

# ── Silero VAD ────────────────────────────────────────────────────────────────
SILERO_VAD_URL = (
    "https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/silero_vad.onnx"
)
SILERO_VAD_PATH = MODELS_DIR / "silero_vad.onnx"

SENSE_VOICE_MODEL_PATH = SENSE_VOICE_DIR / "model.int8.onnx"
SENSE_VOICE_TOKENS_PATH = SENSE_VOICE_DIR / "tokens.txt"


def download(url: str, dest: Path, label: str) -> bool:
    if dest.is_file():
        print(f"  ✅ Already exists: {dest}")
        return True
    print(f"  ⬇  Downloading {label}...")
    print(f"     {url}")
    try:
        def progress(block_num, block_size, total_size):
            downloaded = block_num * block_size
            if total_size > 0:
                pct = min(100, downloaded * 100 // total_size)
                mb = downloaded / (1024 * 1024)
                total_mb = total_size / (1024 * 1024)
                print(f"\r     {pct:3d}%  {mb:.1f}/{total_mb:.1f} MB", end="", flush=True)

        urllib.request.urlretrieve(url, dest, reporthook=progress)
        print()
        print(f"  ✅ Saved to: {dest}")
        return True
    except Exception as e:
        print(f"\n  ❌ Download failed: {e}")
        return False


def extract_sense_voice():
    archive_path = MODELS_DIR / SENSE_VOICE_ARCHIVE

    if SENSE_VOICE_MODEL_PATH.is_file() and SENSE_VOICE_TOKENS_PATH.is_file():
        print(f"  ✅ SenseVoice model already extracted: {SENSE_VOICE_DIR}")
        return True

    # Download archive
    if not download(SENSE_VOICE_URL, archive_path, "SenseVoice int8 ONNX model"):
        return False

    # Extract
    print(f"  📦 Extracting {archive_path.name}...")
    try:
        with tarfile.open(archive_path, "r:bz2") as tar:
            members = tar.getmembers()
            extracted_root = None
            for m in members:
                tar.extract(m, path=MODELS_DIR)
                if extracted_root is None:
                    extracted_root = Path(m.name).parts[0]

        # Move files from extracted subfolder to sense-voice/
        if extracted_root:
            extracted_dir = MODELS_DIR / extracted_root
            for f in extracted_dir.iterdir():
                dest = SENSE_VOICE_DIR / f.name
                f.rename(dest)
            try:
                extracted_dir.rmdir()
            except Exception:
                pass

        # Cleanup archive
        archive_path.unlink(missing_ok=True)
        print(f"  ✅ SenseVoice model extracted to: {SENSE_VOICE_DIR}")
        return True

    except Exception as e:
        print(f"  ❌ Extraction failed: {e}")
        return False


def main():
    print("=" * 60)
    print("Sherpa-ONNX Model Downloader for Elly SOS Backend")
    print("=" * 60)
    print()
    print(f"Models directory: {MODELS_DIR.resolve()}")
    print()

    # ── 1. SenseVoice CTC model ───────────────────────────────────────────────
    print("1. SenseVoice CTC Model (multilingual: zh/en/ja/ko/yue, int8):")
    sv_ok = extract_sense_voice()

    # ── 2. Silero VAD model ───────────────────────────────────────────────────
    print()
    print("2. Silero VAD Model:")
    vad_ok = download(SILERO_VAD_URL, SILERO_VAD_PATH, "Silero VAD")

    # ── Summary ───────────────────────────────────────────────────────────────
    print()
    print("=" * 60)
    print("Summary:")
    print(f"  SenseVoice model : {'✅ OK' if sv_ok else '❌ FAILED'}")
    print(f"  Silero VAD       : {'✅ OK' if vad_ok else '❌ FAILED'}")
    print()

    if sv_ok and vad_ok:
        print("✅ All models ready! Update your backend/.env:")
        print()
        print(f'  SHERPA_SENSE_VOICE_MODEL="{SENSE_VOICE_MODEL_PATH}"')
        print(f'  SHERPA_SENSE_VOICE_TOKENS="{SENSE_VOICE_TOKENS_PATH}"')
        print(f'  SHERPA_SILERO_VAD_MODEL="{SILERO_VAD_PATH}"')
    else:
        print("❌ Some models failed to download. Check your internet connection.")
        sys.exit(1)


if __name__ == "__main__":
    main()
