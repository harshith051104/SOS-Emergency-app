# 🚨 ELLY — Next-Gen SOS Emergency Companion & AI First-Responder Suite

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Vite](https://img.shields.io/badge/Vite-5.x-646CFF?style=for-the-badge&logo=vite&logoColor=white)](https://vitejs.dev)
[![Groq LLaMA 3.1](https://img.shields.io/badge/Groq_LLaMA-3.1_8B-F05032?style=for-the-badge&logo=groq&logoColor=white)](https://groq.com)
[![Whisper API](https://img.shields.io/badge/Groq_Whisper-Large_v3_Turbo-00A67E?style=for-the-badge&logo=openai&logoColor=white)](https://groq.com)
[![Vercel Deployed](https://img.shields.io/badge/Vercel-Deployed-000000?style=for-the-badge&logo=vercel&logoColor=white)](https://vercel.com)

**ELLY** is an intelligent, multi-platform emergency safety ecosystem designed to act as a calm, empathetic, and situation-aware human companion during critical safety emergencies. It provides real-time hands-free AI voice guidance, live location & health telemetry generation, country-aware helpline dispatch, and real-time responder tracking.

---

## 🌟 Architecture & Key Features

### 1. 🎙️ Continuous Hands-Free AI Voice Assistant (Elly)
- **Powered by Groq LLaMA 3.1 8B Instant & Groq Whisper STT:** Real-time conversational AI trained to function as an empathetic first-responder friend without relying on generic robotic scripts.
- **Continuous Dialogue Loop:** Operates hands-free during active emergencies. Automatically cycles from **Listening** ➔ **Thinking** ➔ **Speaking** with built-in barge-in voice interruption.
- **Whisper & Native TTS Failsafe:** Web & Mobile pipelines use local audio recording (`MediaRecorder` / native mic) sent directly to **Groq Whisper API** (`whisper-large-v3-turbo`) for ~200ms latency, with Android native `TextToSpeech` (`flutter_tts`) fallback for loud-speaker output.
- **12-Second Extended Voice Window:** Extended listening duration allowing users to finish complex requests without being cut off mid-sentence.

### 2. ⏳ Dynamic 10-Second Countdown & Confirmation Page
- **Pulsating SOS Button:** Ambient ring pulse animation on tap.
- **10-Second Countdown Loader:** Ticks down dynamically (`10, 9, 8... 0`).
- **Emergency Category Cards Inside Loader:** Users can tap any category during countdown:
  - 🚑 **Medical:** Ambulance (`102` / `108`)
  - 👮 **Police:** Police Helpline (`100`)
  - 🚒 **Fire:** Fire Rescue (`101`)
  - 🚦 **Traffic Police:** Traffic Helpline (`103`)
  - 🌪️ **Disaster:** Disaster Control (`1096`)
  - 🚨 **Universal:** National Emergency (`112`)
- **Automatic Universal Fallback:** If time expires without selection, the system automatically dials the location's universal emergency helpline (`112` in India, `911` in US, `999` in UK, `000` in AU) and transitions to live AI voice support.

### 3. 📍 Live Location Telemetry & National Emergency Resolver
- **GPS & Reverse Geocoding:** Resolves exact coordinates, physical address, and ISO country code using Geolocator & Nominatim Geocoding API.
- **Country-Aware Dialer:** Automatically maps emergency category titles to national helpline numbers based on live GPS location (`EmergencyNumberResolver`).
- **Telemetry Packet Generation:** Compiles device battery status, GPS accuracy, and medical profile summaries into a lightweight encrypted payload for responder dispatch.

### 4. 🛰️ Live Responder Dispatch Pipeline
- **3-Stage Dispatch Timeline:** `Alert Triggered` ➔ `Responders Notified` ➔ `Responders Acknowledged`.
- **Live Status Cards:** Displays real-time status badges (`ACCEPTED (ETA 4m)`, `NOTIFIED`, `DELIVERED`).

---

## 📂 Repository Structure

```
SOS/
├── elly/                      # Flutter Mobile Application (iOS & Android)
│   ├── android/               # Android native manifests & Kotlin setup
│   ├── lib/
│   │   ├── core/              # Theme, AppColors, EmergencyNumberResolver
│   │   └── features/
│   │       ├── assistant/     # Groq LLM, SpeechSynthesis, VoiceScheduler
│   │       ├── packet/        # LocationService, Emergency Packet Builder
│   │       ├── responders/    # Responder Repository & Dispatch Engine
│   │       └── sos/           # Riverpod Controllers, Pages & Widgets
│   └── pubspec.yaml           # Flutter dependencies (audioplayers, flutter_tts, riverpod)
│
├── elly-web/                  # Standalone Vite Web Application
│   ├── index.html             # Glassmorphism UI layout & HTML5 structure
│   ├── package.json           # Vite dependencies & scripts
│   └── src/
│       ├── main.js            # Main web controller & event coordinator
│       ├── style.css          # Dark mode glassmorphism CSS design system
│       └── services/
│           ├── groq_service.js # Groq LLaMA 3.1 & Whisper API client
│           ├── speech_service.js # MediaRecorder STT & Web Speech Synthesis
│           ├── location_service.js # HTML5 Geolocation & Nominatim Geocoding
│           └── emergency_number_resolver.js # Helpline matcher & tel: dialer
│
├── .env                       # Root environment configuration (VITE_GROQ_API_KEY)
└── README.md                  # Project Documentation
```

---

## 🛠️ Quick Start & Setup

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>=3.x`)
- [Node.js](https://nodejs.org) (`>=18.x`) & `npm`
- Groq API Key (`GROQ_API_KEY`)

---

### 📱 Running the Mobile Application (Flutter)

1. Navigate to the mobile app directory:
   ```bash
   cd elly
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run on physical device or emulator with `.env` defined:
   ```bash
   flutter run --dart-define-from-file=../.env
   ```

---

### 🌐 Running the Web Application (Vite)

1. Navigate to the web app directory:
   ```bash
   cd elly-web
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Start local development server:
   ```bash
   npm run dev
   ```
   Open `http://localhost:5173` in your browser.

4. Build for production:
   ```bash
   npm run build
   ```

---

## 🚀 Web Deployment (Vercel)

The web application is configured for 1-click deployment on **Vercel**:

1. Import repository `harshith051104/SOS-Emergency-app` on [Vercel](https://vercel.com).
2. Set **Root Directory** to `elly-web`.
3. Set **Framework Preset** to `Vite`.
4. Add Environment Variable:
   - `VITE_GROQ_API_KEY`: Your Groq API key
5. Deploy!

---

## 📄 License & Attribution

Developed with ❤️ as an open safety companion suite. Powered by Flutter, Vite, Groq LLaMA 3.1, and OpenAI Whisper.
