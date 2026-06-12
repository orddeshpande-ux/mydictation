import 'package:flutter_test/flutter_test.dart';
import 'package:omniscribe_ai/src/utils/punctuation_formatter.dart';

void main() {
  group('PunctuationFormatter Tests', () {
    test('English spoken punctuation replacement', () {
      const input = 'Hello world full stop How are you question mark This is great exclamation mark';
      final output = PunctuationFormatter.format(input);
      expect(output, 'Hello world. How are you? This is great!');
    });

    test('Marathi spoken punctuation replacement', () {
      const input = 'नमस्कार माझे नाव विक्रांत आहे पूर्णविराम तुमचे नाव काय आहे क्वेश्चन मार्क';
      final output = PunctuationFormatter.format(input);
      expect(output, 'नमस्कार माझे नाव विक्रांत आहे. तुमचे नाव काय आहे?');
    });

    test('Hindi spoken punctuation replacement', () {
      const input = 'क्या आप कल आ रहे हैं प्रश्नवाचक चिन्ह हाँ मैं आऊँगा खड़ी पाई';
      final output = PunctuationFormatter.format(input);
      expect(output, 'क्या आप कल आ रहे हैं? हाँ मैं आऊँगा।');
    });

    test('Case insensitivity and spacing cleanup', () {
      const input = 'This is a test  comma  and it has extra spaces   period';
      final output = PunctuationFormatter.format(input);
      expect(output, 'This is a test, and it has extra spaces.');
    });

    test('Empty input handles gracefully', () {
      expect(PunctuationFormatter.format(''), '');
    });
  });
}
