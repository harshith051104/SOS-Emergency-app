/**
 * main.js
 * 
 * Main application controller orchestrating UI views, emergency countdown,
 * location telemetry, Groq LLaMA chat engine, Groq Whisper STT, and continuous hands-free voice dialogue.
 */

import { LocationService } from './services/location_service.js';
import { EmergencyNumberResolver } from './services/emergency_number_resolver.js';
import { GroqService } from './services/groq_service.js';
import { SpeechService } from './services/speech_service.js';

// Application State
let appState = 'home'; // 'home' | 'countdown' | 'active'
let selectedCategory = null;
let countdownTimer = null;
let countdownVal = 10;
let locationData = { address: 'Resolving Location...', isoCountryCode: 'IN' };
let batteryLevel = '85%';

// Service Instances
const groqService = new GroqService();

// UI Elements
const homeView = document.getElementById('homeView');
const sessionView = document.getElementById('sessionView');
const countdownOverlay = document.getElementById('countdownOverlay');
const countdownValueEl = document.getElementById('countdownValue');
const sosBtn = document.getElementById('sosBtn');
const safeBtn = document.getElementById('safeBtn');
const endEmergencyBtn = document.getElementById('endEmergencyBtn');
const locationBadge = document.getElementById('locationBadge');
const speechBubble = document.getElementById('speechBubble');
const statusPill = document.getElementById('statusPill');
const statusText = document.getElementById('statusText');
const visualizer = document.getElementById('visualizer');
const telemetryDetails = document.getElementById('telemetryDetails');
const categoryCards = document.querySelectorAll('.category-card');
const chatInput = document.getElementById('chatInput');
const sendChatBtn = document.getElementById('sendChatBtn');

// Handle incoming user text or spoken input
async function handleUserInput(text) {
  if (!text || !text.trim()) return;
  const cleanInput = text.trim();

  speechBubble.innerHTML = `<span style="opacity: 0.7;">You:</span> "${cleanInput}"`;
  updateStatus('thinking');

  const responseText = await groqService.sendMessage({
    userMessage: cleanInput,
    category: selectedCategory,
    address: locationData.address,
    batteryLevel
  });

  speechBubble.innerText = responseText;
  speechService.speakText(responseText);
}

// Initialize Speech Service with Groq Whisper audio capture
const speechService = new SpeechService({
  onAudioCaptured: async (audioBlob) => {
    updateStatus('thinking');
    speechBubble.innerText = 'Transcribing voice via Groq Whisper...';

    const transcript = await groqService.transcribeAudio(audioBlob);
    if (transcript && transcript.trim()) {
      await handleUserInput(transcript);
    } else {
      console.log('[Main] No speech detected or transcript empty.');
      speechBubble.innerText = "I'm right here with you. Help is on the way. Tell me what is happening.";
      speechService.checkAutoLoop();
    }
  },
  onStateChange: (state) => {
    updateStatus(state);
  }
});

// Initialize Location Telemetry
async function initTelemetry() {
  locationData = await LocationService.getCurrentLocation();
  batteryLevel = await LocationService.getBatteryLevel();

  locationBadge.innerText = `📍 ${locationData.address.split(',')[0] || 'GPS Active'}`;
  telemetryDetails.innerHTML = `
    📍 GPS Address: ${locationData.address}<br>
    🔋 Device Battery: ${batteryLevel}
  `;
}

// Update Assistant Status Pill UI
function updateStatus(state) {
  statusPill.className = 'status-pill';
  visualizer.classList.remove('active');

  if (state === 'listening') {
    statusPill.classList.add('listening');
    statusText.innerText = 'ELLY IS LISTENING...';
    visualizer.classList.add('active');
  } else if (state === 'thinking') {
    statusText.innerText = 'ELLY IS THINKING...';
  } else if (state === 'speaking') {
    statusPill.classList.add('speaking');
    statusText.innerText = 'ELLY IS SPEAKING...';
    visualizer.classList.add('active');
  } else {
    statusText.innerText = 'HANDS-FREE ACTIVE';
  }
}

// Start 10-Second Confirmation Countdown
function startCountdown() {
  appState = 'countdown';
  countdownVal = 10;
  countdownValueEl.innerText = '10';
  countdownOverlay.classList.add('active');

  clearInterval(countdownTimer);
  countdownTimer = setInterval(() => {
    countdownVal--;
    if (countdownVal <= 0) {
      clearInterval(countdownTimer);
      countdownOverlay.classList.remove('active');
      
      // Time expired without selection -> Auto-call national universal number (112 in IN, 911 in US)
      const universalNumber = EmergencyNumberResolver.resolveNumber({
        countryCode: locationData.isoCountryCode,
        address: locationData.address
      });
      
      console.log(`[Main] 10s countdown expired -> auto calling ${universalNumber}`);
      EmergencyNumberResolver.makeEmergencyCall(universalNumber);
      activateEmergencySession('General Emergency');
    } else {
      countdownValueEl.innerText = countdownVal;
    }
  }, 1000);
}

// Cancel Countdown
function cancelCountdown() {
  clearInterval(countdownTimer);
  countdownOverlay.classList.remove('active');
  appState = 'home';
  selectedCategory = null;
}

// Activate Live Emergency Session
async function activateEmergencySession(categoryTitle) {
  clearInterval(countdownTimer);
  countdownOverlay.classList.remove('active');
  appState = 'active';
  selectedCategory = categoryTitle || 'General Emergency';

  homeView.style.display = 'none';
  sessionView.style.display = 'flex';

  groqService.clearHistory();

  speechBubble.innerText = 'Connecting to Elly AI...';
  updateStatus('thinking');

  const initialGreeting = await groqService.sendMessage({
    userMessage: '',
    category: selectedCategory,
    address: locationData.address,
    batteryLevel
  });

  speechBubble.innerText = initialGreeting;
  speechService.startAutoLoop();
  speechService.speakText(initialGreeting);
}

// End Active Emergency Session
function endEmergencySession() {
  const confirmed = confirm('Are you sure you want to end the emergency session?');
  if (!confirmed) return;

  console.log('[Main] Ending emergency session...');
  speechService.stopAutoLoop();
  appState = 'home';
  selectedCategory = null;

  sessionView.style.display = 'none';
  homeView.style.display = 'block';

  window.scrollTo({ top: 0, behavior: 'smooth' });
}

// Event Listeners
sosBtn.addEventListener('click', () => {
  startCountdown();
});

safeBtn.addEventListener('click', () => {
  cancelCountdown();
});

endEmergencyBtn.addEventListener('click', () => {
  endEmergencySession();
});

// Category card clicks (both on Home View & inside 10s Countdown Page)
categoryCards.forEach(card => {
  card.addEventListener('click', () => {
    const category = card.dataset.category;
    const serviceNumber = EmergencyNumberResolver.resolveServiceNumber({
      category,
      countryCode: locationData.isoCountryCode,
      address: locationData.address
    });

    console.log(`[Main] Category selected: ${category} -> Calling ${serviceNumber}`);
    EmergencyNumberResolver.makeEmergencyCall(serviceNumber);

    activateEmergencySession(category);
  });
});

// Text Chat Input Event Listeners
sendChatBtn.addEventListener('click', () => {
  if (chatInput.value.trim()) {
    handleUserInput(chatInput.value.trim());
    chatInput.value = '';
  }
});

chatInput.addEventListener('keydown', (e) => {
  if (e.key === 'Enter' && chatInput.value.trim()) {
    handleUserInput(chatInput.value.trim());
    chatInput.value = '';
  }
});

// Initialize on page load
window.addEventListener('DOMContentLoaded', () => {
  initTelemetry();
});
