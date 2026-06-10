import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BrainService {
  static const String _defaultUrl = 'http://localhost:5050';

  Future<String> _getBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('voice_server_url') ?? _defaultUrl;
    } catch (_) {
      return _defaultUrl;
    }
  }

  Future<String> analyzeTranscript(String transcript, String systemPrompt, {double temperature = 0.3}) async {
    if (transcript.trim().isEmpty) {
      return 'No text dictated yet.';
    }
    
    final baseUrl = await _getBaseUrl();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': transcript,
          'system_prompt': systemPrompt,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['analysis'] ?? '';
      } else {
        return 'Local LLM analysis error (Status ${response.statusCode})';
      }
    } catch (e) {
      return 'Offline Mode: Local AI model is starting up or disconnected. Please ensure the backend server is running.';
    }
  }

  Future<String> cleanTranscript(String transcript) async {
    if (transcript.trim().isEmpty) {
      return '';
    }
    
    final baseUrl = await _getBaseUrl();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/clean'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': transcript,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['cleaned_text'] ?? '';
      }
    } catch (e) {
      print('BrainService: Failed to clean transcript: $e');
    }
    return transcript;
  }
}
