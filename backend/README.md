# Elly SOS Backend (Python 3.12 + FastAPI)

Enterprise emergency synchronization backend for **Elly SOS**. Handles authentication, emergency packet storage, user health passports, emergency contact sync, responder dispatch routing, and live WebSockets.

---

## 🚀 Quick Start

1. Install dependencies:
   ```bash
   pip install -e .
   ```

2. Run development server:
   ```bash
   uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
   ```

3. Run test suite:
   ```bash
   pytest tests/ -v
   ```
