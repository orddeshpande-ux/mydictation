import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omniscribe_ai/src/blocs/dictation_bloc.dart';
import 'package:omniscribe_ai/src/models/domain_mode.dart';
import 'package:omniscribe_ai/src/widgets/insight_card_widget.dart';
import 'package:omniscribe_ai/src/screens/voice_profile_screen.dart';
import 'package:omniscribe_ai/src/screens/voice_manager_screen.dart';
import 'package:omniscribe_ai/src/screens/history_screen.dart';
import 'package:omniscribe_ai/src/services/tts_service.dart';

// Conditional imports for web vs native file saving
import 'package:omniscribe_ai/src/utils/save_stub.dart'
    if (dart.library.html) 'package:omniscribe_ai/src/utils/save_web.dart'
    if (dart.library.io) 'package:omniscribe_ai/src/utils/save_native.dart'
    as file_saver;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const desktopBreakpoint = 900;

  late final TextEditingController _controller;
  final TtsService _ttsService = TtsService();
  DomainMode _selectedMode = DomainMode.legal;
  String _selectedLocale = 'en_IN';
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _ttsService.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _ttsService.stop();
    super.dispose();
  }

  void _loadTranscript(String content) {
    _controller.text = content;
    context.read<DictationBloc>().add(UpdateTranscript(content));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OmniScribe AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Transcript History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryScreen(onLoadTranscript: _loadTranscript),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.graphic_eq),
            tooltip: 'Voice Manager',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VoiceManagerScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.record_voice_over),
            tooltip: 'Voice Profile Setup',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const VoiceProfileScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocListener<DictationBloc, DictationState>(
        listener: (context, state) {
          if (_controller.text != state.transcript) {
            _controller.text = state.transcript;
            _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
          }
        },
        child: BlocBuilder<DictationBloc, DictationState>(
          builder: (context, state) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= desktopBreakpoint;
                return isDesktop
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(flex: 5, child: _buildDictationCanvas(context, state)),
                            const VerticalDivider(width: 1, thickness: 1),
                            SizedBox(width: 360, child: _buildInsightPanel(context, state)),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(child: _buildDictationCanvas(context, state)),
                          const Divider(height: 1),
                          SizedBox(height: 320, child: _buildInsightPanel(context, state)),
                        ],
                      );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDictationCanvas(BuildContext context, DictationState state) {
    final isListening = state.isDictating;
    final isProcessing = state.status == DictationStatus.processing;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Dictation Workspace', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black87)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: DomainMode.values.map((mode) {
                      return ChoiceChip(
                        label: Text(mode.displayName),
                        selected: _selectedMode == mode,
                        onSelected: (_) => setState(() => _selectedMode = mode),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedLocale,
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                  items: const [
                    DropdownMenuItem(value: 'en_IN', child: Text('English (India)')),
                    DropdownMenuItem(value: 'hi_IN', child: Text('Hindi')),
                    DropdownMenuItem(value: 'mr_IN', child: Text('Marathi')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedLocale = value);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.all(18),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                  decoration: const InputDecoration.collapsed(hintText: 'Start dictating or type here...', hintStyle: TextStyle(color: Colors.black38)),
                  onChanged: (value) => context.read<DictationBloc>().add(UpdateTranscript(value)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Status indicator
            if (isListening || isProcessing)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isListening ? Colors.redAccent : Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isListening ? 'Listening...' : 'Processing with AI...',
                      style: TextStyle(
                        fontSize: 13,
                        color: isListening ? Colors.redAccent : Colors.blueAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            // Button bar
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                // Start/Stop Dictation
                ElevatedButton.icon(
                  onPressed: () {
                    if (isListening) {
                      context.read<DictationBloc>().add(StopDictation());
                      context.read<DictationBloc>().add(CleanTranscription());
                      context.read<DictationBloc>().add(GenerateInsights(_selectedMode));
                    } else {
                      context.read<DictationBloc>().add(StartDictation(localeId: _selectedLocale));
                    }
                  },
                  icon: Icon(isListening ? Icons.stop : Icons.mic, size: 18),
                  label: Text(isListening ? 'Stop' : 'Dictate'),
                ),
                // Analyze (manual insight trigger for typed/edited text)
                OutlinedButton.icon(
                  onPressed: isProcessing
                      ? null
                      : () {
                          if (_controller.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Nothing to analyze')),
                            );
                            return;
                          }
                          // Make sure state has latest typed text
                          context.read<DictationBloc>().add(UpdateTranscript(_controller.text));
                          context.read<DictationBloc>().add(CleanTranscription());
                          context.read<DictationBloc>().add(GenerateInsights(_selectedMode));
                        },
                  icon: const Icon(Icons.auto_fix_high, size: 18),
                  label: const Text('Analyze'),
                ),
                // Read Aloud / Stop Speaking
                OutlinedButton.icon(
                  onPressed: () async {
                    if (_isSpeaking) {
                      await _ttsService.stop();
                      setState(() => _isSpeaking = false);
                    } else {
                      if (_controller.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Nothing to read')),
                        );
                        return;
                      }
                      setState(() => _isSpeaking = true);
                      final ttsLocale = _ttsService.convertLocale(_selectedLocale);
                      await _ttsService.speak(_controller.text, locale: ttsLocale);
                    }
                  },
                  icon: Icon(_isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up, size: 18),
                  label: Text(_isSpeaking ? 'Stop Reading' : 'Read Aloud'),
                ),
                // Copy
                OutlinedButton.icon(
                  onPressed: () {
                    if (_controller.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nothing to copy')),
                      );
                      return;
                    }
                    Clipboard.setData(ClipboardData(text: _controller.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy'),
                ),
                // Save
                OutlinedButton.icon(
                  onPressed: () async {
                    if (_controller.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nothing to save')),
                      );
                      return;
                    }
                    try {
                      final fileName = 'OmniScribe_${DateTime.now().millisecondsSinceEpoch}.txt';
                      await file_saver.saveFile(fileName, _controller.text);
                      // Also save to history
                      await HistoryScreen.saveTranscript(fileName, _controller.text);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Saved: $fileName')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Save failed: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightPanel(BuildContext context, DictationState state) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('AI Co-Counsel', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.black87)),
                if (state.status == DictationStatus.processing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Current mode: ${_selectedMode.displayName}', style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: state.insights.isEmpty
                    ? [const Padding(padding: EdgeInsets.all(8.0), child: Text('Dictate or type text, then press Analyze to receive AI insights.', style: TextStyle(color: Colors.black38)))]
                    : state.insights.map((insight) {
                        InsightCardType cardType = InsightCardType.info;
                        if (insight.type.toLowerCase() == 'warning') {
                          cardType = InsightCardType.warning;
                        } else if (insight.type.toLowerCase() == 'suggestion') {
                          cardType = InsightCardType.suggestion;
                        }
                        return InsightCardWidget(
                          title: insight.title,
                          message: insight.message,
                          type: cardType,
                        );
                      }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
