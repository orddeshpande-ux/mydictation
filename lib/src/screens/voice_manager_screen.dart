import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:omniscribe_ai/src/services/voice_clone_service.dart';
import 'package:omniscribe_ai/src/screens/training_guide_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class VoiceManagerScreen extends StatefulWidget {
  const VoiceManagerScreen({super.key});

  @override
  State<VoiceManagerScreen> createState() => _VoiceManagerScreenState();
}

class _VoiceManagerScreenState extends State<VoiceManagerScreen> {
  final VoiceCloneService _voiceService = VoiceCloneService();
  List<Map<String, dynamic>> _voices = [];
  bool _isLoading = true;
  bool _serverOnline = false;
  bool _isStartingServer = false;
  final TextEditingController _ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ipController.text = VoiceCloneService.baseUrl;
    _checkServerAndLoad();
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _checkServerAndLoad() async {
    setState(() => _isLoading = true);
    await VoiceCloneService.loadBaseUrl();
    _ipController.text = VoiceCloneService.baseUrl;
    _serverOnline = await _voiceService.isServerRunning();
    if (_serverOnline) {
      _voices = await _voiceService.listVoices();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _updateServerUrl() async {
    final newUrl = _ipController.text.trim();
    if (newUrl.isEmpty) return;
    
    setState(() => _isLoading = true);
    await VoiceCloneService.saveBaseUrl(newUrl);
    _serverOnline = await _voiceService.isServerRunning();
    if (_serverOnline) {
      _voices = await _voiceService.listVoices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully connected to AI server at $newUrl')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not connect. Please check the IP/URL and try again.')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _startLocalServer() async {
    setState(() {
      _isStartingServer = true;
      _isLoading = true;
    });

    await VoiceCloneService.autoStartServer();

    // Loop check for connection (takes up to 25 seconds)
    for (int i = 0; i < 8; i++) {
      await Future.delayed(const Duration(seconds: 3));
      _serverOnline = await _voiceService.isServerRunning();
      if (_serverOnline) break;
    }

    if (_serverOnline) {
      _voices = await _voiceService.listVoices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline AI Engine started successfully!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offline AI Engine is starting in the background. If launching for the first time, it might take a few minutes to configure components.'),
            duration: Duration(seconds: 6),
          ),
        );
      }
    }

    setState(() {
      _isStartingServer = false;
      _isLoading = false;
    });
  }

  Future<void> _showCreateVoiceDialog() async {
    final nameController = TextEditingController();
    List<PlatformFile> pickedFiles = [];
    List<TextEditingController> transcriptControllers = [];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add a New Person\'s Voice'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create a profile to clone a new voice (e.g., your brother\'s, father\'s, or your own). You will need to upload recordings and provide what they said.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Person\'s Name',
                      hintText: 'e.g., "Father\'s Voice"',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Upload Recording Samples:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'For best results, upload clear recordings with no background noise. 5 to 10 short samples are recommended.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        allowMultiple: true,
                        type: FileType.custom,
                        allowedExtensions: ['mp3', 'wav', 'mp4', 'm4a', 'ogg'],
                        withData: true,
                      );
                      if (result != null) {
                        setDialogState(() {
                          pickedFiles.addAll(result.files);
                          for (var _ in result.files) {
                            transcriptControllers.add(TextEditingController());
                          }
                        });
                      }
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Select Audio Recordings'),
                  ),
                  const SizedBox(height: 16),
                  if (pickedFiles.isNotEmpty)
                    ...List.generate(pickedFiles.length, (i) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.audiotrack, size: 18, color: Colors.blueAccent),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      pickedFiles[i].name,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                    onPressed: () {
                                      setDialogState(() {
                                        pickedFiles.removeAt(i);
                                        transcriptControllers.removeAt(i);
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: transcriptControllers[i],
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'What is spoken in this recording?',
                                  hintText: 'Type word-for-word what the person said in this audio file...',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: pickedFiles.isEmpty || nameController.text.trim().isEmpty
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      await _createVoice(
                        nameController.text.trim(),
                        pickedFiles,
                        transcriptControllers.map((c) => c.text).toList(),
                      );
                    },
              child: const Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createVoice(String name, List<PlatformFile> files, List<String> transcripts) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saving profile and uploading recordings...')),
    );

    List<Uint8List> audioBytes = [];
    List<String> fileNames = [];
    for (var file in files) {
      if (file.bytes != null) {
        audioBytes.add(file.bytes!);
        fileNames.add(file.name);
      }
    }

    final result = await _voiceService.createVoice(
      name: name,
      audioFiles: audioBytes,
      fileNames: fileNames,
      transcripts: transcripts,
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voice profile "${result['name']}" created successfully with ${result['sample_count']} samples.')),
      );
      _checkServerAndLoad();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create voice profile. Ensure the AI server is active.')),
      );
    }
  }

  Future<void> _trainVoice(String voiceId, String name) async {
    final success = await _voiceService.trainVoice(voiceId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voice learning started for "$name". The AI will process the recordings in the background.')),
      );
      await Future.delayed(const Duration(seconds: 4));
      _checkServerAndLoad();
    }
  }

  Future<void> _showGenerateDialog(String voiceId, String voiceName) async {
    final textController = TextEditingController();
    String selectedFormat = 'mp3';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Speak Text using $voiceName'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Type any text below. The AI will convert this text into speech, cloned to sound exactly like the profile voice.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: textController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Text to speak',
                    hintText: 'Enter the text you want read aloud...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Output Format:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('MP3 (Standard)'),
                      selected: selectedFormat == 'mp3',
                      onSelected: (_) => setDialogState(() => selectedFormat = 'mp3'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('WAV (High Quality)'),
                      selected: selectedFormat == 'wav',
                      onSelected: (_) => setDialogState(() => selectedFormat = 'wav'),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('MP4 (Video Ready)'),
                      selected: selectedFormat == 'mp4',
                      onSelected: (_) => setDialogState(() => selectedFormat = 'mp4'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: textController.text.trim().isEmpty
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      await _generateSpeech(voiceId, textController.text, selectedFormat);
                    },
              icon: const Icon(Icons.record_voice_over),
              label: const Text('Speak & Create File'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateSpeech(String voiceId, String text, String format) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating speech file... This may take a moment.')),
    );

    final result = await _voiceService.generateSpeech(
      voiceId: voiceId,
      text: text,
      format: format,
    );

    if (result != null && mounted) {
      final downloadUrl = _voiceService.getDownloadUrl(result['filename']);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Speech generated successfully: ${result['filename']}'),
          action: SnackBarAction(
            label: 'Download File',
            onPressed: () async {
              final uri = Uri.parse(downloadUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          ),
          duration: const Duration(seconds: 15),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate speech. Verify that the AI server is running.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Cloning & Speech Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'How to use',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TrainingGuideScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Status',
            onPressed: _checkServerAndLoad,
          ),
        ],
      ),
      floatingActionButton: _serverOnline
          ? FloatingActionButton.extended(
              onPressed: _showCreateVoiceDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Voice Profile'),
            )
          : null,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(_isStartingServer 
                    ? 'Starting local offline AI engine...\nThis may take a few minutes on the first launch.'
                    : 'Loading...', 
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            )
          : !_serverOnline
              ? Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.offline_bolt_outlined, size: 64, color: Colors.blueAccent),
                          const SizedBox(height: 16),
                          const Text(
                            'Offline AI Engine Disconnected',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'To protect your privacy, this application runs all artificial intelligence models locally on your computer. The background AI engine is not running right now.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, color: Colors.black54),
                          ),
                          const SizedBox(height: 24),
                          if (kIsWeb)
                            const Text(
                              'Please run the desktop app on Windows to start and manage the offline AI engine.',
                              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: _startLocalServer,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Launch Local AI Engine', style: TextStyle(fontSize: 16)),
                            ),
                          const SizedBox(height: 32),
                          const Divider(),
                          const SizedBox(height: 16),
                          Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              title: const Center(
                                child: Text(
                                  'Advanced Network Settings (for Mobile)',
                                  style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w500),
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'If you are running this app on your phone, enter the IP address of your computer where the AI engine is running:',
                                        style: TextStyle(fontSize: 13, color: Colors.black54),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _ipController,
                                              decoration: const InputDecoration(
                                                labelText: 'AI Server URL',
                                                hintText: 'e.g., http://192.168.1.5:5050',
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          ElevatedButton(
                                            onPressed: _updateServerUrl,
                                            child: const Text('Connect'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : _voices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.person_add, size: 64, color: Colors.black26),
                          const SizedBox(height: 16),
                          const Text('No voice profiles created yet.', style: TextStyle(fontSize: 18, color: Colors.black45)),
                          const SizedBox(height: 8),
                          const Text('Tap the button below to add a person\'s voice.', style: TextStyle(color: Colors.black38)),
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const TrainingGuideScreen()));
                            },
                            icon: const Icon(Icons.menu_book),
                            label: const Text('Read the Training Guide'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _voices.length,
                      itemBuilder: (context, index) {
                        final voice = _voices[index];
                        final status = voice['status'] ?? 'unknown';
                        final isReady = status == 'ready';
                        final isTraining = status == 'training';

                        Color statusColor = Colors.grey;
                        String friendlyStatus = 'Not Trained';
                        if (isReady) {
                          statusColor = Colors.green;
                          friendlyStatus = 'Ready to Speak';
                        }
                        if (isTraining) {
                          statusColor = Colors.orange;
                          friendlyStatus = 'Learning Voice...';
                        }
                        if (status.startsWith('error')) {
                          statusColor = Colors.red;
                          friendlyStatus = 'Error Processing';
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      backgroundColor: Colors.blueAccent,
                                      child: Icon(Icons.person, color: Colors.white),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(voice['name'] ?? 'Unknown',
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                width: 8, height: 8,
                                                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(friendlyStatus, style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w500)),
                                              const SizedBox(width: 12),
                                              Text('${voice['sample_count'] ?? 0} voice recordings',
                                                  style: const TextStyle(color: Colors.black54, fontSize: 13)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    if (!isReady && !isTraining)
                                      ElevatedButton.icon(
                                        onPressed: () => _trainVoice(voice['id'], voice['name']),
                                        icon: const Icon(Icons.model_training, size: 18),
                                        label: const Text('Start Voice Learning'),
                                      ),
                                    if (isTraining)
                                      const Chip(
                                        avatar: SizedBox(
                                          width: 16, height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                        label: Text('Learning features in background...'),
                                      ),
                                    if (isReady)
                                      ElevatedButton.icon(
                                        onPressed: () => _showGenerateDialog(voice['id'], voice['name']),
                                        icon: const Icon(Icons.record_voice_over, size: 18),
                                        label: const Text('Convert Text to Speech'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
