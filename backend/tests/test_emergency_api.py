"""
test_emergency_api.py

Pytest suite for verifying FastAPI Emergency Packet Ingestion & WebSockets.
Uses dynamic IDs for idempotent test execution across multiple runs.
"""

from datetime import datetime, timezone
import uuid
import pytest
from httpx import AsyncClient, ASGITransport

from app.main import app


@pytest.mark.asyncio
async def test_health_check():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://testserver") as client:
        response = await client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "HEALTHY"
        assert "Elly SOS" in data["service"]


@pytest.mark.asyncio
async def test_dispatch_emergency_packet():
    transport = ASGITransport(app=app)
    unique_id = uuid.uuid4().hex[:8]
    pkt_id = f"pkt_pytest_{unique_id}"
    sess_id = f"sess_pytest_{unique_id}"

    async with AsyncClient(transport=transport, base_url="http://testserver") as client:
        payload = {
            "packet_id": pkt_id,
            "session_id": sess_id,
            "user_id": "usr_alex_vance",
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "packet_version": "2.0",
            "sequence_number": 1,
            "status": "QUEUED",
            "priority": "CRITICAL",
            "packet_hash": f"hash_{unique_id}",
            "packet_checksum": "98765432",
            "ai_models": {
                "vad": {"name": "Silero VAD", "version": "5.0", "checksum": "f8a7", "verified": True},
                "stt": {"name": "Sherpa-ONNX SenseVoice", "version": "2025.1", "checksum": "e2c9", "verified": True}
            },
            "transcript": {
                "text": "Help me I can't breathe",
                "confidence": 0.97,
                "language": "en",
                "is_partial": False,
                "speech_probability": 0.99,
                "parsed_intent": "CRITICAL_MEDICAL_ASSISTANCE",
                "matched_keywords": ["help", "breathe"]
            },
            "speaker_verification": {
                "verified": True,
                "confidence": 0.94,
                "profile_id": "spk_alex_01"
            },
            "biomarker_summary": {
                "stress_level": "HIGH",
                "breathing_state": "DISTRESSED",
                "confidence": 0.93
            },
            "location": {
                "latitude": 12.971598,
                "longitude": 77.594562,
                "accuracy": 4.5,
                "address": "MG Road, Bengaluru, India"
            },
            "medical": {
                "blood_group": "O+",
                "allergies": ["Penicillin"],
                "chronic_conditions": ["Asthma"]
            },
            "device": {
                "battery_level": 82,
                "is_charging": False,
                "cpu_usage_percent": 14.2,
                "ram_free_mb": 1850,
                "network_type": "4G"
            }
        }

        response = await client.post("/v1/emergency/dispatch", json=payload)
        assert response.status_code == 201
        data = response.json()
        assert data["packet_id"] == pkt_id
        assert data["session_id"] == sess_id
        assert data["status"] == "UPLOADED"
        assert data["confirmation_code"].startswith("ACK-")


@pytest.mark.asyncio
async def test_auth_register_and_login():
    transport = ASGITransport(app=app)
    unique_email = f"user_{uuid.uuid4().hex[:8]}@example.com"
    password = "SecurePassword123!"

    async with AsyncClient(transport=transport, base_url="http://testserver") as client:
        # 1. Register
        reg_payload = {
            "email": unique_email,
            "password": password,
            "full_name": "Alex Vance",
            "phone_number": "+15550199"
        }
        reg_resp = await client.post("/v1/auth/register", json=reg_payload)
        assert reg_resp.status_code == 201
        user_data = reg_resp.json()
        assert user_data["email"] == unique_email
        assert user_data["user_id"].startswith("usr_")

        # 2. Login
        login_payload = {
            "email": unique_email,
            "password": password
        }
        login_resp = await client.post("/v1/auth/login", json=login_payload)
        assert login_resp.status_code == 200
        token_data = login_resp.json()
        assert "access_token" in token_data
        assert token_data["token_type"] == "bearer"
        assert token_data["user_id"] == user_data["user_id"]


@pytest.mark.asyncio
async def test_health_passport_crud():
    transport = ASGITransport(app=app)
    user_id = f"usr_health_{uuid.uuid4().hex[:8]}"

    async with AsyncClient(transport=transport, base_url="http://testserver") as client:
        payload = {
            "blood_group": "O+",
            "age": 28,
            "allergies": ["Penicillin", "Peanuts"],
            "medications": ["Inhaler"],
            "chronic_conditions": ["Asthma"],
            "physician_name": "Dr. Smith",
            "physician_phone": "+15550199",
            "emergency_notes": "Carries epi-pen in backpack."
        }

        # Update
        put_resp = await client.put(f"/v1/health-passport/{user_id}", json=payload)
        assert put_resp.status_code == 200
        data = put_resp.json()
        assert data["user_id"] == user_id
        assert data["blood_group"] == "O+"
        assert "Penicillin" in data["allergies"]

        # Get
        get_resp = await client.get(f"/v1/health-passport/{user_id}")
        assert get_resp.status_code == 200
        get_data = get_resp.json()
        assert get_data["physician_name"] == "Dr. Smith"


@pytest.mark.asyncio
async def test_sos_circle_contacts():
    transport = ASGITransport(app=app)
    user_id = f"usr_circle_{uuid.uuid4().hex[:8]}"

    async with AsyncClient(transport=transport, base_url="http://testserver") as client:
        contact_payload = {
            "name": "Sarah Vance",
            "phone_number": "+15550188",
            "relationship": "Sister",
            "is_primary": True,
            "notify_sms": True
        }

        # Add Contact
        add_resp = await client.post(f"/v1/sos-circle/{user_id}/contacts", json=contact_payload)
        assert add_resp.status_code == 201
        contact_data = add_resp.json()
        assert contact_data["name"] == "Sarah Vance"
        assert contact_data["contact_id"].startswith("cnt_")

        # List Contacts
        list_resp = await client.get(f"/v1/sos-circle/{user_id}/contacts")
        assert list_resp.status_code == 200
        list_data = list_resp.json()
        assert len(list_data) >= 1
        assert list_data[0]["relationship"] == "Sister"


@pytest.mark.asyncio
async def test_telemetry_and_assistant():
    transport = ASGITransport(app=app)
    user_id = f"usr_telem_{uuid.uuid4().hex[:8]}"

    async with AsyncClient(transport=transport, base_url="http://testserver") as client:
        # 1. Telemetry Log
        telem_payload = {
            "user_id": user_id,
            "device_id": "dev_samsung_g781b",
            "points": [
                {"metric_name": "vad_latency_ms", "value": 12.4, "timestamp": datetime.now(timezone.utc).isoformat()},
                {"metric_name": "stt_latency_ms", "value": 45.0, "timestamp": datetime.now(timezone.utc).isoformat()}
            ]
        }
        telem_resp = await client.post("/v1/telemetry/log", json=telem_payload)
        assert telem_resp.status_code == 202
        assert telem_resp.json()["processed_points"] == 2

        # 2. Assistant Chat
        chat_payload = {
            "messages": [{"role": "user", "content": "How do I update my emergency contacts?"}],
            "user_id": user_id
        }
        chat_resp = await client.post("/v1/assistant/chat", json=chat_payload)
        assert chat_resp.status_code == 200
        assert "ELLY" in chat_resp.json()["reply"]

        # 3. Responders Nearby
        resp_list = await client.get("/v1/responders/nearby?lat=12.9715&lng=77.5945")
        assert resp_list.status_code == 200
        assert isinstance(resp_list.json(), list)
