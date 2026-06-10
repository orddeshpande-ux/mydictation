import 'dart:async';
import 'dart:convert';
import 'dart:io';
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

  /// Differentiate connection errors to provide clear, actionable feedback to users.
  String _handleError(dynamic error, String url) {
    if (error is TimeoutException) {
      return 'Connection Timeout: The AI server at $url took too long to respond. The model may be loading or busy processing another request.';
    } else if (error is SocketException) {
      return 'Server Offline: Cannot reach the AI server at $url. Ensure the backend server is running and your mobile device is on the same local network/Wi-Fi.';
    } else {
      return 'Connection Error: Failed to communicate with local AI server. Details: $error';
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
      ).timeout(const Duration(seconds: 60)); // Increased to 60s for local LLM inference over Wi-Fi

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['analysis'] ?? '';
      } else {
        return 'Server Error (Status ${response.statusCode}): The AI engine returned an error during analysis.';
      }
    } catch (e) {
      return _handleError(e, baseUrl);
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
      ).timeout(const Duration(seconds: 60)); // Increased to 60s for local inference

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['cleaned_text'] ?? '';
      }
    } catch (e) {
      print('BrainService: Failed to clean transcript: ${_handleError(e, baseUrl)}');
    }
    return transcript;
  }

  /// Test connection to a specific URL.
  Future<bool> testConnection(String url) async {
    try {
      final response = await http.get(Uri.parse('$url/voices'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
