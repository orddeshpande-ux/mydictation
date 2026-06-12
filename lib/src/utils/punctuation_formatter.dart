class PunctuationFormatter {
  static String format(String text) {
    if (text.isEmpty) return text;

    String result = text;

    // Define punctuation mappings using RegExp
    final Map<Pattern, String> mappings = {
      // --- English Punctuation ---
      RegExp(r'\b(?:question mark)\b', caseSensitive: false): '?',
      RegExp(r'\b(?:full stop|period)\b', caseSensitive: false): '.',
      RegExp(r'\b(?:comma)\b', caseSensitive: false): ',',
      RegExp(r'\b(?:exclamation mark|exclamation point)\b', caseSensitive: false): '!',
      RegExp(r'\b(?:colon)\b', caseSensitive: false): ':',
      RegExp(r'\b(?:semi colon|semicolon)\b', caseSensitive: false): ';',
      RegExp(r'\b(?:new line|newline)\b', caseSensitive: false): '\n',
      RegExp(r'\b(?:open quote|open quotes|start quote)\b', caseSensitive: false): '"',
      RegExp(r'\b(?:close quote|close quotes|end quote)\b', caseSensitive: false): '"',
      RegExp(r'\b(?:dash|hyphen)\b', caseSensitive: false): '-',

      // --- Marathi Punctuation (Devanagari) ---
      RegExp(r'क्वेश्चन\s*मार्क'): '?',
      RegExp(r'प्रश्न\s*चिन्ह'): '?',
      RegExp(r'प्रश्नचिन्ह'): '?',
      RegExp(r'पूर्ण\s*विराम'): '.',
      RegExp(r'पूर्णविराम'): '.',
      RegExp(r'स्वल्प\s*विराम'): ',',
      RegExp(r'स्वल्पविराम'): ',',
      RegExp(r'उद्गारवाचक\s*चिन्ह'): '!',
      RegExp(r'उद्गार\s*चिन्ह'): '!',
      RegExp(r'उद्गारचिन्ह'): '!',
      RegExp(r'कोलन'): ':',
      RegExp(r'सेमी\s*कोलन'): ';',
      RegExp(r'नवीन\s*ओळ'): '\n',

      // --- Hindi Punctuation (Devanagari) ---
      RegExp(r'अल्प\s*विराम'): ',',
      RegExp(r'अल्पविराम'): ',',
      RegExp(r'खड़ी\s*पाई'): '।',
      RegExp(r'खड़ी\s*पाई'): '।',
      RegExp(r'विस्मयादिबोधक\s*चिन्ह'): '!',
      RegExp(r'विस्मयादिबोधक'): '!',
      RegExp(r'प्रश्नवाचक\s*चिन्ह'): '?',
      RegExp(r'प्रश्नवाचक'): '?',
      RegExp(r'डैश'): '-',
    };

    // Apply replacements
    for (var entry in mappings.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }

    // Clean up spaces around punctuation (e.g. "what is your name ?" -> "what is your name?")
    result = _cleanPunctuationSpacing(result);

    return result;
  }

  static String _cleanPunctuationSpacing(String text) {
    String formatted = text;

    // Clean spaces before punctuation symbols: ?, ., ,, !, :, ;, ।
    formatted = formatted.replaceAllMapped(RegExp(r'\s+([?.,!:;।])'), (match) {
      return match.group(1)!;
    });

    // Clean multiple spaces
    formatted = formatted.replaceAll(RegExp(r' +'), ' ');

    return formatted;
  }
}
