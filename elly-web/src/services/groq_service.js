/**
 * groq_service.js
 * 
 * Interacts with Groq LLaMA 3.1 8B Instant API to generate warm, human, empathetic first responder guidance.
 */

const GROQ_API_KEY = import.meta.env?.VITE_GROQ_API_KEY || '';
const GROQ_MODEL = 'llama-3.1-8b-instant';

export class GroqService {
  constructor() {
    this.messages = [];
  }

  /**
   * Resets chat history
   */
  clearHistory() {
    this.messages = [];
  }

  /**
   * Builds the category-aware system prompt
   */
  buildSystemPrompt({ category, address, batteryLevel }) {
    const serviceName = (category || 'GENERAL EMERGENCY').toUpperCase();

    let categoryGuidance = '';
    if (serviceName.includes('MEDICAL')) {
      categoryGuidance = `
SERVICE FOCUS (MEDICAL EMERGENCY):
- The user activated a MEDICAL emergency.
- Focus immediately on physical well-being: check if they are injured, in pain, or having trouble breathing.
- Provide simple, clear medical first-aid guidance (apply pressure to bleeding, stay still, open a window).
- Reassure them that medical responders and emergency contacts are notified.
`;
    } else if (serviceName.includes('POLICE') || serviceName.includes('SAFETY') || serviceName.includes('SECURITY')) {
      categoryGuidance = `
SERVICE FOCUS (POLICE & PERSONAL SAFETY):
- The user activated a POLICE / PERSONAL SAFETY emergency.
- Focus immediately on personal physical safety: guide them to a locked or secure location if threatened.
- Speak in a calm, discreet tone.
- Reassure them that location coordinates and security responders have been dispatched.
`;
    } else if (serviceName.includes('FIRE')) {
      categoryGuidance = `
SERVICE FOCUS (FIRE EMERGENCY):
- The user activated a FIRE emergency.
- Focus on immediate evacuation: guide them to stay low under smoke and get to an open outside space.
- Keep instructions swift, direct, and focused on physical exit.
`;
    } else {
      categoryGuidance = `
SERVICE FOCUS (GENERAL EMERGENCY):
- The user activated a GENERAL SOS alert.
- Ask how you can support them right now and listen attentively to their situation.
- Reassure them that emergency contacts are being alerted.
`;
    }

    return `
You are ELLY, a warm, compassionate, highly-trained human emergency supporter staying on the line with the user during a live emergency.
You speak directly to the user over audio. Speak like an empathetic, calm, caring human friend—not a robotic AI or automated script.

HUMAN CONVERSATIONAL RULES:
1. Speak naturally, warmly, and empathetically. Use simple, conversational language.
2. Keep responses concise (1 to 2 warm, clear sentences max) so you do not overpower or interrupt the user.
3. DO NOT rely repeatedly on generic breathing cues ("inhale... exhale") unless the user explicitly mentions feeling severe panic or hyperventilating. Focus on the actual situation at hand.
4. Always acknowledge what the user just said before offering the next helpful suggestion.
5. Never blame the user. Give them space to express what they need.

${categoryGuidance}

CURRENT EMERGENCY TELEMETRY:
- Selected Emergency Service: ${serviceName}
- GPS Location: ${address}
- Device Battery: ${batteryLevel}

Be a comforting, human anchor of support. Focus on their immediate safety.
`;
  }

  /**
   * Sends user message to Groq LLaMA and returns response text
   */
  async sendMessage({ userMessage, category, address, batteryLevel }) {
    if (userMessage) {
      this.messages.push({ role: 'user', content: userMessage });
    }

    const systemPrompt = this.buildSystemPrompt({ category, address, batteryLevel });

    const payload = {
      model: GROQ_MODEL,
      messages: [
        { role: 'system', content: systemPrompt },
        ...this.messages
      ],
      temperature: 0.6,
      max_tokens: 150
    };

    try {
      const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${GROQ_API_KEY}`
        },
        body: JSON.stringify(payload)
      });

      if (!response.ok) {
        throw new Error(`Groq API returned HTTP ${response.status}`);
      }

      const data = await response.json();
      const reply = data.choices[0]?.message?.content || "I am right here with you. Help is on the way. Tell me what is happening.";

      this.messages.push({ role: 'assistant', content: reply });
      return reply;
    } catch (err) {
      console.error('[GroqService] Request error:', err);
      return "I am here with you. Emergency responders are being dispatched to your location.";
    }
  }

  /**
   * Transcribes raw audio blob using Groq Whisper API (whisper-large-v3-turbo).
   * Completely circumvents browser Web Speech API network errors.
   */
  async transcribeAudio(audioBlob) {
    if (!audioBlob || audioBlob.size === 0) return '';

    const formData = new FormData();
    formData.append('file', audioBlob, 'audio.wav');
    formData.append('model', 'whisper-large-v3-turbo');

    try {
      const response = await fetch('https://api.groq.com/openai/v1/audio/transcriptions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${GROQ_API_KEY}`
        },
        body: formData
      });

      if (!response.ok) {
        throw new Error(`Groq Whisper returned HTTP ${response.status}`);
      }

      const data = await response.json();
      return (data.text || '').trim();
    } catch (err) {
      console.error('[GroqService] Whisper transcription error:', err);
      return '';
    }
  }
}
