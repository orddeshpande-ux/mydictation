import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class VoiceCloneService {
  static const String _defaultUrl = 'http://127.0.0.1:5050';
  static String _baseUrl = _defaultUrl;
  final http.Client _client;

  VoiceCloneService({http.Client? client}) : _client = client ?? http.Client();

  /// Retrieve the current configured URL.
  static String get baseUrl => _baseUrl;

  /// Load the voice server URL from storage.
  static Future<void> loadBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _baseUrl = prefs.getString('voice_server_url') ?? _defaultUrl;
    } catch (_) {
      _baseUrl = _defaultUrl;
    }

    // On mobile platforms (Android/iOS), if the loaded URL is not running, trigger auto-discovery
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final service = VoiceCloneService();
      final isRunning = await service.isServerRunning();
      if (!isRunning) {
        print('VoiceCloneService: Current server URL is offline. Running auto-discovery on local network...');
        final discoveredUrl = await discoverLocalServer();
        if (discoveredUrl != null) {
          print('VoiceCloneService: Auto-detected server at $discoveredUrl');
          await saveBaseUrl(discoveredUrl);
        }
      }
    }
  }

  /// Automatically discover the local voice server running on port 5050 in the same network.
  static Future<String?> discoverLocalServer() async {
    try {
      final List<String> subnets = [];
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            final ipParts = addr.address.split('.');
            if (ipParts.length == 4) {
              final subnet = '${ipParts[0]}.${ipParts[1]}.${ipParts[2]}';
              if (!subnets.contains(subnet)) {
                subnets.add(subnet);
              }
            }
          }
        }
      }

      if (subnets.isEmpty) return null;

      final client = http.Client();
      final List<String> scanUrls = [];
      for (var subnet in subnets) {
        for (int i = 1; i <= 254; i++) {
          scanUrls.add('http://$subnet.$i:5050');
        }
      }

      // Scan in batches of 32 to prevent OS socket limits/exhaustion
      const batchSize = 32;
      for (int i = 0; i < scanUrls.length; i += batchSize) {
        final end = i + batchSize > scanUrls.length ? scanUrls.length : i + batchSize;
        final batch = scanUrls.sublist(i, end);
        final results = await Future.wait(batch.map((url) => _checkServerUrl(client, url)));
        for (var res in results) {
          if (res != null) {
            client.close();
            return res;
          }
        }
      }
      client.close();
    } catch (e) {
      print('VoiceCloneService: Local network discovery error: $e');
    }
    return null;
  }

  static Future<String?> _checkServerUrl(http.Client client, String url) async {
    try {
      final response = await client.get(Uri.parse('$url/health'))
          .timeout(const Duration(milliseconds: 300));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok') {
          return url;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Update and save the voice server URL.
  static Future<void> saveBaseUrl(String url) async {
    _baseUrl = url;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('voice_server_url', url);
    } catch (_) {}
  }

  /// Automatically launch the voice server on Windows if not running.
  /// On mobile platforms, this is a no-op (user must configure server IP via Settings).
  static Future<void> autoStartServer() async {
    if (kIsWeb) return;

    // First load the configured URL
    await loadBaseUrl();

    // On mobile (non-desktop), skip server launch — just load the URL
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      return;
    }

    // Check if the server is already running
    bool isRunning = false;
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 2));
      isRunning = response.statusCode == 200;
    } catch (_) {
      isRunning = false;
    }

    if (isRunning) {
      print('VoiceCloneService: Voice server is already running at $_baseUrl.');
      return;
    }

    // Only launch local server if we are on Windows and referencing localhost or 127.0.0.1
    if (Platform.isWindows && (_baseUrl.contains('localhost') || _baseUrl.contains('127.0.0.1'))) {
      print('VoiceCloneService: Attempting to launch local voice server in the background...');
      try {
        final dir = Directory('voice_server');
        if (await dir.exists()) {
          await Process.start(
            'cmd.exe',
            ['/c', 'run_server.bat'],
            workingDirectory: 'voice_server',
            runInShell: true,
          );
          print('VoiceCloneService: Background process started.');
        } else {
          print('VoiceCloneService: voice_server folder not found.');
        }
      } catch (e) {
        print('VoiceCloneService: Failed to start background server: $e');
      }
    }
  }

  /// List all voice profiles from the server.
  Future<List<Map<String, dynamic>>> listVoices() async {
    try {
      final response = await _client.get(Uri.parse('$_baseUrl/voices'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('VoiceCloneService: Failed to list voices: $e');
    }
    return [];
  }

  /// Create a new voice profile with audio files and transcripts.
  Future<Map<String, dynamic>?> createVoice({
    required String name,
    required List<Uint8List> audioFiles,
    required List<String> fileNames,
    required List<String> transcripts,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/voices'));
      request.fields['name'] = name;
      request.fields['transcripts'] = jsonEncode(transcripts);

      for (int i = 0; i < audioFiles.length; i++) {
        request.files.add(http.MultipartFile.fromBytes(
          'audio_files',
          audioFiles[i],
          filename: fileNames[i],
        ));
      }

      final streamedResponse = await _client.send(request).timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('VoiceCloneService: Failed to create voice: $e');
    }
    return null;
  }

  /// Start training a voice profile.
  Future<bool> trainVoice(String voiceId) async {
    try {
      final response = await _client.post(Uri.parse('$_baseUrl/voices/$voiceId/train'))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      print('VoiceCloneService: Failed to start training: $e');
      return false;
    }
  }

  /// Check training status of a voice profile.
  Future<Map<String, dynamic>?> getVoiceStatus(String voiceId) async {
    try {
      final response = await _client.get(Uri.parse('$_baseUrl/voices/$voiceId/status'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('VoiceCloneService: Failed to get status: $e');
    }
    return null;
  }

  /// Generate speech from text using a trained voice.
  /// Returns the download URL on success.
  Future<Map<String, dynamic>?> generateSpeech({
    required String voiceId,
    required String text,
    String format = 'mp3',
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'voice_id': voiceId,
          'text': text,
          'format': format,
        }),
      ).timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('VoiceCloneService: Failed to generate speech: $e');
    }
    return null;
  }

  /// Get the full download URL for a generated file.
  String getDownloadUrl(String filename) {
    return '$_baseUrl/download/$filename';
  }

  /// Check if the voice server is running.
  Future<bool> isServerRunning() async {
    try {
      final response = await _client.get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
