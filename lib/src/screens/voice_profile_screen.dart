import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:omniscribe_ai/src/services/cloud_sync_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';

class VoiceProfileScreen extends StatefulWidget {
  const VoiceProfileScreen({super.key});

  @override
  State<VoiceProfileScreen> createState() => _VoiceProfileScreenState();
}

class _VoiceProfileScreenState extends State<VoiceProfileScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final CloudSyncService _cloudSync = CloudSyncService();
  
  bool _isRecording = false;
  bool _isUploading = false;
  String? _recordingPath;

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        String path = '';
        if (!kIsWeb) {
          final dir = await getApplicationDocumentsDirectory();
          path = '${dir.path}/voice_sample_${DateTime.now().millisecondsSinceEpoch}.wav';
        }

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.wav),
          path: path,
        );

        setState(() {
          _isRecording = true;
          _recordingPath = null;
        });
      } else {
        _showPermissionDeniedDialog();
      }
    } catch (e) {
      _showErrorDialog('Failed to start recording: $e');
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Microphone Permission Required',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'OmniScribe AI needs access to your microphone to record your voice profile. Please grant microphone access in the app settings.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
            ),
            child: Text('Open Settings', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Error',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Text(message, style: GoogleFonts.inter()),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordingPath = path;
      });
      if (path != null) {
        _uploadRecording(path);
      }
    } catch (e) {
      print('Stop recording error: $e');
    }
  }

  Future<void> _uploadRecording(String path) async {
    setState(() => _isUploading = true);
    
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    
    if (kIsWeb) {
      // Upload via blob on web requires different handling. Bypassing purely for now to avoid crash.
      await Future.delayed(const Duration(seconds: 1)); // simulate upload
      setState(() => _isUploading = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Web upload bypassed. (Local Supabase needed)')),
        );
      }
      return;
    }
    
    final file = File(path);
    
    final result = await _cloudSync.uploadVoiceProfile(file, userId);
    
    setState(() => _isUploading = false);
    
    if (context.mounted) {
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice profile successfully uploaded!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload voice profile. Ensure Supabase is configured.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Profile Setup'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_cloudSync.isConfigured) ...[
              Container(
                margin: const EdgeInsets.bottom(20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cloud Sync Offline',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'The cloud database (Supabase) is not configured in your environment (.env file). Voice profile recording will only be saved locally and won\'t be backed up to the cloud.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF92400E),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Text(
              'Create Your Custom Voice Profile',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'To train a personalized text-to-speech model or analyze your dictation acoustics, we need a baseline recording of your voice. '
              'Please read the paragraph below clearly in your natural speaking voice.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
              ),
              child: const Text(
                '"The quick brown fox jumps over the lazy dog. My voice is my passport, verify me. '
                'In the context of the Indian legal system, precision is paramount. Whether discussing the Bharatiya Nyaya Sanhita or academic theories, clear pronunciation matters."',
                style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic, height: 1.6, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isRecording ? _stopRecording : _startRecording,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: _isRecording ? Colors.redAccent : Colors.blueAccent,
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isRecording ? 'Recording... Tap to stop' : 'Tap to start recording',
                    style: TextStyle(
                      fontSize: 16,
                      color: _isRecording ? Colors.redAccent : Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_isUploading) ...[
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    const Text('Uploading to secure storage...'),
                  ],
                  if (_recordingPath != null && !_isUploading) ...[
                    const SizedBox(height: 24),
                    const Icon(Icons.check_circle, color: Colors.green, size: 32),
                    const SizedBox(height: 8),
                    const Text('Recording saved and processed.', style: TextStyle(color: Colors.green)),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
