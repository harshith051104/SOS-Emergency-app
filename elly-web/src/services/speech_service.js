/**
 * speech_service.js
 * 
 * Uses HTML5 MediaRecorder to capture microphone audio locally and sends recorded audio
 * blobs directly to Groq Whisper API (whisper-large-v3-turbo) for ultra-fast, 100% reliable
 * speech-to-text transcription. Completely bypasses browser Web Speech API network errors.
 */

export class SpeechService {
  constructor({ onAudioCaptured, onTranscript, onStateChange }) {
    this.onAudioCaptured = onAudioCaptured;
    this.onTranscript = onTranscript;
    this.onStateChange = onStateChange;

    this.mediaRecorder = null;
    this.audioChunks = [];
    this.stream = null;
    this.synthesis = window.speechSynthesis;

    this.isListening = false;
    this.isSpeaking = false;
    this.autoLoop = false;
    this.silenceTimer = null;

    this.initVoices();
  }

  initVoices() {
    if (this.synthesis) {
      this.synthesis.getVoices();
      if (this.synthesis.onvoiceschanged !== undefined) {
        this.synthesis.onvoiceschanged = () => this.synthesis.getVoices();
      }
    }
  }

  notifyState(state) {
    if (this.onStateChange) {
      this.onStateChange(state);
    }
  }

  startAutoLoop() {
    this.autoLoop = true;
  }

  stopAutoLoop() {
    this.autoLoop = false;
    this.stopListening();
    this.stopSpeaking();
    if (this.stream) {
      try {
        this.stream.getTracks().forEach(track => track.stop());
      } catch (e) {}
      this.stream = null;
    }
    this.notifyState('idle');
  }

  async startListening() {
    if (this.isListening) return;
    if (this.isSpeaking) {
      this.stopSpeaking(); // Barge-in interrupt
    }

    try {
      if (!this.stream) {
        this.stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      }

      this.audioChunks = [];
      const mimeType = MediaRecorder.isTypeSupported('audio/webm') ? 'audio/webm' : 'audio/mp4';
      this.mediaRecorder = new MediaRecorder(this.stream, { mimeType });

      this.mediaRecorder.ondataavailable = (event) => {
        if (event.data && event.data.size > 0) {
          this.audioChunks.push(event.data);
        }
      };

      this.mediaRecorder.onstop = async () => {
        this.isListening = false;
        clearTimeout(this.silenceTimer);

        if (this.audioChunks.length > 0) {
          const audioBlob = new Blob(this.audioChunks, { type: mimeType });
          this.audioChunks = [];

          if (this.onAudioCaptured) {
            await this.onAudioCaptured(audioBlob);
          }
        } else {
          this.checkAutoLoop();
        }
      };

      this.mediaRecorder.start();
      this.isListening = true;
      this.notifyState('listening');

      // 10-second capture window
      clearTimeout(this.silenceTimer);
      this.silenceTimer = setTimeout(() => {
        if (this.isListening) {
          console.log('[SpeechService] Listening window complete. Transcribing via Groq Whisper...');
          this.stopListening();
        }
      }, 10000);

    } catch (err) {
      console.warn('[SpeechService] Microphones permission or capture error:', err);
      this.isListening = false;
      this.notifyState('idle');
    }
  }

  stopListening() {
    if (this.mediaRecorder && this.mediaRecorder.state !== 'inactive') {
      try {
        this.mediaRecorder.stop();
      } catch (e) {
        console.warn('[SpeechService] Error stopping MediaRecorder:', e);
      }
    }
    this.isListening = false;
  }

  checkAutoLoop() {
    if (this.autoLoop && !this.isSpeaking && !this.isListening) {
      setTimeout(() => {
        if (this.autoLoop && !this.isSpeaking && !this.isListening) {
          this.startListening();
        }
      }, 800);
    } else if (!this.isSpeaking) {
      this.notifyState('idle');
    }
  }

  speakText(text, onComplete) {
    if (!this.synthesis) {
      if (onComplete) onComplete();
      this.checkAutoLoop();
      return;
    }

    this.stopSpeaking();
    this.notifyState('speaking');
    this.isSpeaking = true;

    const utterance = new SpeechSynthesisUtterance(text);
    utterance.rate = 0.95;
    utterance.pitch = 1.0;
    utterance.volume = 1.0;

    const voices = this.synthesis.getVoices();
    if (voices.length > 0) {
      const preferredVoice = voices.find(v => v.lang.startsWith('en') && (v.name.includes('Natural') || v.name.includes('Google') || v.name.includes('Samantha')));
      if (preferredVoice) {
        utterance.voice = preferredVoice;
      }
    }

    utterance.onend = () => {
      this.isSpeaking = false;
      if (onComplete) onComplete();
      this.checkAutoLoop();
    };

    utterance.onerror = (err) => {
      console.warn('[SpeechService] Speech synthesis error:', err);
      this.isSpeaking = false;
      if (onComplete) onComplete();
      this.checkAutoLoop();
    };

    this.synthesis.speak(utterance);
  }

  stopSpeaking() {
    if (this.synthesis) {
      try {
        this.synthesis.cancel();
      } catch (e) {}
      this.isSpeaking = false;
    }
  }
}
