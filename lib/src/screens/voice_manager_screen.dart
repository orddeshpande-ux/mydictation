import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:omniscribe_ai/src/services/voice_clone_service.dart';
import 'package:omniscribe_ai/src/screens/training_guide_screen.dart';
import 'package:omniscribe_ai/src/widgets/glass_card.dart';
import 'package:omniscribe_ai/src/widgets/connection_status_widget.dart';
import 'package:omniscribe_ai/src/widgets/omni_button.dart';
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

  @override
  void initState() {
    super.initState();
    _checkServerAndLoad();
  }

  Future<void> _checkServerAndLoad() async {
    setState(() => _isLoading = true);
    await VoiceCloneService.loadBaseUrl();
    _serverOnline = await _voiceService.isServerRunning();
    if (_serverOnline) {
      _voices = await _voiceService.listVoices();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _startLocalServer() async {
    setState(() {
      _isStartingServer = true;
      _isLoading = true;
    });

    await VoiceCloneService.autoStartServer();

    for (int i = 0; i < 8; i++) {
      await Future.delayed(const Duration(seconds: 3));
      _serverOnline = await _voiceService.isServerRunning();
      if (_serverOnline) break;
    }

    if (_serverOnline) {
      _voices = await _voiceService.listVoices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('AI Engine started successfully!')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'AI Engine is starting in the background. Please wait...'),
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

  Future<void> _showCreateVoiceSheet() async {
    final nameController = TextEditingController();
    List<PlatformFile> pickedFiles = [];
    List<TextEditingController> transcriptControllers = [];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'New Voice Profile',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create a profile to clone a voice. Upload recordings and provide transcripts.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Person\'s Name',
                          hintText: 'e.g., "Father\'s Voice"',
                          prefixIcon: Icon(Icons.person_rounded),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Recording Samples',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '5-10 short, clear recordings recommended',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final result =
                                await FilePicker.platform.pickFiles(
                              allowMultiple: true,
                              type: FileType.custom,
                              allowedExtensions: [
                                'mp3',
                                'wav',
                                'mp4',
                                'm4a',
                                'ogg'
                              ],
                              withData: true,
                            );
                            if (result != null) {
                              setSheetState(() {
                                pickedFiles.addAll(result.files);
                                for (var _ in result.files) {
                                  transcriptControllers
                                      .add(TextEditingController());
                                }
                              });
                            }
                          },
                          icon:
                              const Icon(Icons.upload_file_rounded, size: 18),
                          label: const Text('Select Audio Files'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (pickedFiles.isNotEmpty)
                        ...List.generate(pickedFiles.length, (i) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FC),
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.audiotrack_rounded,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        pickedFiles[i].name,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setSheetState(() {
                                          pickedFiles.removeAt(i);
                                          transcriptControllers
                                              .removeAt(i);
                                        });
                                      },
                                      child: const Icon(Icons.close_rounded,
                                          size: 18,
                                          color: Color(0xFFEF4444)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: transcriptControllers[i],
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    labelText: 'What is spoken?',
                                    hintText: 'Type word-for-word...',
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              // Save button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: pickedFiles.isEmpty ||
                            nameController.text.trim().isEmpty
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            await _createVoice(
                              nameController.text.trim(),
                              pickedFiles,
                              transcriptControllers
                                  .map((c) => c.text)
                                  .toList(),
                            );
                          },
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text('Create Profile'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createVoice(
      String name, List<PlatformFile> files, List<String> transcripts) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Creating voice profile...')),
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
        SnackBar(
            content: Text(
                'Profile "${result['name']}" created with ${result['sample_count']} samples.')),
      );
      _checkServerAndLoad();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create profile.')),
      );
    }
  }

  Future<void> _trainVoice(String voiceId, String name) async {
    final success = await _voiceService.trainVoice(voiceId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voice learning started for "$name".')),
      );
      await Future.delayed(const Duration(seconds: 4));
      _checkServerAndLoad();
    }
  }

  Future<void> _showGenerateSheet(String voiceId, String voiceName) async {
    final textController = TextEditingController();
    String selectedFormat = 'mp3';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.65,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Generate as $voiceName',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: textController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Text to speak',
                          hintText: 'Enter what you want read aloud...',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Output Format',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('MP3'),
                            selected: selectedFormat == 'mp3',
                            onSelected: (_) =>
                                setSheetState(() => selectedFormat = 'mp3'),
                          ),
                          ChoiceChip(
                            label: const Text('WAV'),
                            selected: selectedFormat == 'wav',
                            onSelected: (_) =>
                                setSheetState(() => selectedFormat = 'wav'),
                          ),
                          ChoiceChip(
                            label: const Text('MP4'),
                            selected: selectedFormat == 'mp4',
                            onSelected: (_) =>
                                setSheetState(() => selectedFormat = 'mp4'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: textController.text.trim().isEmpty
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            await _generateSpeech(
                                voiceId, textController.text, selectedFormat);
                          },
                    icon:
                        const Icon(Icons.record_voice_over_rounded, size: 18),
                    label: const Text('Generate Speech'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateSpeech(
      String voiceId, String text, String format) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating speech...')),
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
          content: Text('Generated: ${result['filename']}'),
          action: SnackBarAction(
            label: 'Download',
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
        const SnackBar(content: Text('Failed to generate speech.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Studio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Training Guide',
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TrainingGuideScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _checkServerAndLoad,
          ),
        ],
      ),
      floatingActionButton: _serverOnline
          ? FloatingActionButton.extended(
              onPressed: _showCreateVoiceSheet,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Voice'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 20),
                      Text(
                        _isStartingServer
                            ? 'Starting AI engine...'
                            : 'Loading...',
                        style: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                )
              : !_serverOnline
                  ? _buildOfflineView()
                  : _voices.isEmpty
                      ? _buildEmptyView()
                      : _buildVoiceList(),
        ),
      ),
    );
  }

  Widget _buildOfflineView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.offline_bolt_rounded,
                size: 40, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'AI Engine Disconnected',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'All voice cloning runs locally on your computer for maximum privacy.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF94A3B8),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ConnectionStatusWidget(
            isConnected: false,
            serverUrl: VoiceCloneService.baseUrl,
          ),
          const SizedBox(height: 24),
          if (!kIsWeb)
            SizedBox(
              width: double.infinity,
              child: OmniButton(
                onPressed: _startLocalServer,
                icon: Icons.play_arrow_rounded,
                label: 'Launch AI Engine',
                isLoading: _isStartingServer,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Running on a phone? Go to Settings to enter your computer\'s IP address.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFFCBD5E1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.person_add_rounded,
                size: 40, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'No voice profiles yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Voice" to create your first profile',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TrainingGuideScreen()));
            },
            icon: const Icon(Icons.menu_book_rounded, size: 18),
            label: const Text('Read Training Guide'),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceList() {
    return Column(
      children: [
        // Connection status banner
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: ConnectionStatusWidget(
            isConnected: true,
            serverUrl: VoiceCloneService.baseUrl,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _voices.length,
            itemBuilder: (context, index) {
              final voice = _voices[index];
              final status = voice['status'] ?? 'unknown';
              final isReady = status == 'ready';
              final isTraining = status == 'training';
              final name = voice['name'] ?? 'Unknown';

              Color statusColor = const Color(0xFF94A3B8);
              String friendlyStatus = 'Not Trained';
              if (isReady) {
                statusColor = const Color(0xFF10B981);
                friendlyStatus = 'Ready';
              }
              if (isTraining) {
                statusColor = const Color(0xFFF59E0B);
                friendlyStatus = 'Learning...';
              }
              if (status.startsWith('error')) {
                statusColor = const Color(0xFFEF4444);
                friendlyStatus = 'Error';
              }

              return GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    friendlyStatus,
                                    style: GoogleFonts.inter(
                                      color: statusColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${voice['sample_count'] ?? 0} samples',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF94A3B8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (!isReady && !isTraining)
                          ElevatedButton.icon(
                            onPressed: () =>
                                _trainVoice(voice['id'], name),
                            icon: const Icon(Icons.model_training_rounded,
                                size: 16),
                            label: const Text('Train'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                            ),
                          ),
                        if (isTraining)
                          Chip(
                            avatar: const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFF59E0B)),
                            ),
                            label: Text('Learning...',
                                style: GoogleFonts.inter(fontSize: 12)),
                          ),
                        if (isReady)
                          ElevatedButton.icon(
                            onPressed: () =>
                                _showGenerateSheet(voice['id'], name),
                            icon: const Icon(
                                Icons.record_voice_over_rounded,
                                size: 16),
                            label: const Text('Generate Speech'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
