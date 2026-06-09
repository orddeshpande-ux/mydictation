import 'dart:convert';
import 'package:http/http.dart' as http;

class BrainService {
  final String _baseUrl;
  final String _modelName;

  BrainService({String? baseUrl, String? modelName})
      : _baseUrl = baseUrl ?? 'http://localhost:11434',
        _modelName = modelName ?? 'llama3';

  Future<String> analyzeTranscript(String transcript, String systemPrompt) async {
    if (transcript.trim().isEmpty) {
      return 'No text dictated yet.';
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/v1/chat/completions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': _modelName,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {
              'role': 'user',
              'content': 'Analyze the following dictation and output actionable domain feedback: "$transcript"'
            }
          ],
          'temperature': 0.3,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'] ?? '';
      } else {
        return 'Local LLM analysis error (Status ${response.statusCode})';
      }
    } catch (e) {
      return 'Offline Mode: Local LLM feedback is not active. To enable live insights, please run Ollama locally and download the $_modelName model (run: ollama run $_modelName).';
    }
  }
}
