/// phrase_dictionary.dart
///
/// Externalized phrase resource dictionary for multi-language emergency intent keywords.

library;

class PhraseDictionary {
  static const Map<String, List<String>> emergencyPhrases = {
    'en': [
      'help',
      'help me',
      'emergency',
      'need emergency',
      'assistance',
      'ambulance',
      'accident',
      'attacked',
      'unconscious',
      'bleeding',
      'heart attack',
      'cannot breathe',
      'i cant breathe',
      'i can\'t breathe',
      'oh my god',
      'oh my god oh my god',
      'dont touch me',
      'don\'t touch me',
      'please leave me alone',
      'leave me alone',
      'i cant survive',
      'i can\'t survive',
      'save me',
      'police',
      'fire',
      'sos',
      'danger',
    ],
    'hi': [
      'मदद',
      'आपातकाल',
      'एम्बुलेंस',
      'दुर्घटना',
      'हमला',
      'बेहोश',
      'खून',
      'सांस नहीं',
      'बचाओ',
      'पुलिस',
    ],
    'te': [
      'సాహాయం',
      'అత్యవసర',
      'అంబులెన్స్',
      'ప్రమాదం',
      'రక్తం',
      'కాపాడు',
      'పోలీస్',
    ],
    'ta': [
      'உதவி',
      'அவசரம்',
      'ஆம்புலன்ஸ்',
      'விபத்து',
      'இரத்தம்',
      'காப்பாற்று',
      'போலீஸ்',
    ],
    'kn': [
      'ಸಹಾಯ',
      'ತುರ್ತು',
      'ಆಂಬ್ಯುಲೆನ್ಸ್',
      'ಅಪಘಾತ',
      'ರಕ್ತ',
      'ಕಾಪಾಡಿ',
      'ಪೊಲೀಸ್',
    ],
    'ml': [
      'സഹായം',
      'അടിയന്തരം',
      'ആംബുലൻസ്',
      'അപകടം',
      'രക്തം',
      'രക്ഷിക്കൂ',
      'പോലീസ്',
    ],
  };

  static const Map<String, List<String>> possibleEmergencyPhrases = {
    'en': ['pain', 'dizzy', 'scared', 'fell', 'hurt', 'chest', 'sick', 'danger'],
    'hi': ['दर्द', 'चक्कर', 'डर', 'चोट', 'सीना', 'बीमार', 'खतरा'],
    'te': ['నొప్పి', 'కళ్ళు తిరగడం', 'భయం', 'గాయం', 'ఛాతీ', 'ప్రమాదం'],
    'ta': ['வலி', 'மயக்கம்', 'பயம்', 'காயம்', 'நெஞ்சு', 'ஆபத்து'],
    'kn': ['ನೋವು', 'ತಲೆಸುತ್ತು', 'ಭಯ', 'ಗಾಯ', 'ಎದೆ', 'ಅಪಾಯ'],
    'ml': ['വേദന', 'തലചുറ്റൽ', 'ഭയം', 'പരുക്ക്', 'നെഞ്ച്', 'അപകടം'],
  };
}
