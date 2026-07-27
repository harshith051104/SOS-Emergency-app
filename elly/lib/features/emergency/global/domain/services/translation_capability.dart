/// translation_capability.dart
///
/// Translation layer providing localized presentation of Health Passport medical fields
/// for foreign emergency first responders.

library;

class TranslationCapability {
  static const Map<String, Map<String, String>> _translations = {
    'hi': {
      'bloodGroup': 'रक्त समूह',
      'allergies': 'एलर्जी',
      'medications': 'दवाएं',
      'medicalConditions': 'चिकित्सा स्थिति',
      'emergencyNotes': 'आपातकालीन नोट',
    },
    'ja': {
      'bloodGroup': '血液型',
      'allergies': 'アレルギー',
      'medications': '服用薬',
      'medicalConditions': '持病',
      'emergencyNotes': '緊急メモ',
    },
    'es': {
      'bloodGroup': 'Grupo Sanguíneo',
      'allergies': 'Alergias',
      'medications': 'Medicamentos',
      'medicalConditions': 'Condiciones Médicas',
      'emergencyNotes': 'Notas de Emergencia',
    },
    'pt': {
      'bloodGroup': 'Grupo Sanguíneo',
      'allergies': 'Alergias',
      'medications': 'Medicamentos',
      'medicalConditions': 'Condições Médicas',
      'emergencyNotes': 'Notas de Emergência',
    },
  };

  /// Returns translated label for medical field based on target language code.
  static String translateField(String fieldKey, String targetLanguageCode) {
    final lang = targetLanguageCode.split('_').first.toLowerCase();
    if (_translations.containsKey(lang) && _translations[lang]!.containsKey(fieldKey)) {
      return _translations[lang]![fieldKey]!;
    }
    // Fallback to English key
    switch (fieldKey) {
      case 'bloodGroup':
        return 'Blood Group';
      case 'allergies':
        return 'Allergies';
      case 'medications':
        return 'Medications';
      case 'medicalConditions':
        return 'Medical Conditions';
      case 'emergencyNotes':
        return 'Emergency Notes';
      default:
        return fieldKey;
    }
  }
}
