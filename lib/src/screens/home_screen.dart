import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:omniscribe_ai/src/blocs/dictation_bloc.dart';
import 'package:omniscribe_ai/src/models/domain_mode.dart';
import 'package:omniscribe_ai/src/widgets/insight_card_widget.dart';
import 'package:omniscribe_ai/src/widgets/animated_mic_button.dart';
import 'package:omniscribe_ai/src/widgets/glass_card.dart';
import 'package:omniscribe_ai/src/services/tts_service.dart';

// Conditional imports for web vs native file saving
import 'package:omniscribe_ai/src/utils/save_stub.dart'
    if (dart.library.html) 'package:omniscribe_ai/src/utils/save_web.dart'
    if (dart.library.io) 'package:omniscribe_ai/src/utils/save_native.dart'
    as file_saver;

import 'package:omniscribe_ai/src/screens/history_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? pendingTranscript;
  final VoidCallback? onTranscriptConsumed;

  const HomeScreen({
    super.key,
    this.pendingTranscript,
    this.onTranscriptConsumed,
  });

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
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _ttsService.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pendingTranscript != null &&
        widget.pendingTranscript != oldWidget.pendingTranscript) {
      _controller.text = widget.pendingTranscript!;
      context
          .read<DictationBloc>()
          .add(UpdateTranscript(widget.pendingTranscript!));
      widget.onTranscriptConsumed?.call();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _ttsService.stop();
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('OmniScribe AI'),
          ],
        ),
      ),
      body: BlocListener<DictationBloc, DictationState>(
        listener: (context, state) {
          if (_controller.text != state.transcript) {
            _controller.text = state.transcript;
            _controller.selection =
                TextSelection.collapsed(offset: _controller.text.length);
          }
        },
        child: BlocBuilder<DictationBloc, DictationState>(
          builder: (context, state) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= desktopBreakpoint;
                if (isDesktop) {
                  return _buildDesktopLayout(context, state);
                }
                return _buildMobileLayout(context, state);
              },
            );
          },
        ),
      ),
    );
  }

  // ─── MOBILE LAYOUT ───────────────────────────────────────────

  Widget _buildMobileLayout(BuildContext context, DictationState state) {
    final isListening = state.isDictating;
    final isProcessing = state.status == DictationStatus.processing;

    return Stack(
      children: [
        // Main content
        Column(
          children: [
            // Status bar
            if (isListening || isProcessing)
              _buildStatusBar(isListening, isProcessing),

            // Domain chips + language
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _buildModeSelector(),
            ),

            // Text editor
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _buildTextEditor(context, state),
              ),
            ),

            // Action buttons + mic
            _buildMobileActionBar(context, state),

            // Extra space for bottom nav
            const SizedBox(height: 8),
          ],
        ),

        // Insights sheet (draggable from bottom)
        if (state.insights.isNotEmpty)
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.06,
            minChildSize: 0.06,
            maxChildSize: 0.55,
            snap: true,
            snapSizes: const [0.06, 0.35, 0.55],
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.auto_fix_high_rounded,
                            color: Color(0xFF6C63FF), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'AI Insights',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${state.insights.length} items',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...state.insights.map((insight) {
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
                    }),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildStatusBar(bool isListening, bool isProcessing) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isListening
              ? [
                  const Color(0xFFEF4444).withOpacity(0.1),
                  const Color(0xFFFECACA).withOpacity(0.3)
                ]
              : [
                  const Color(0xFF6C63FF).withOpacity(0.1),
                  const Color(0xFFC4B5FD).withOpacity(0.3)
                ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isListening
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isListening ? 'Listening...' : 'Processing with AI...',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isListening
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF6C63FF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: DomainMode.values.map((mode) {
                final isSelected = _selectedMode == mode;
                String emoji;
                switch (mode) {
                  case DomainMode.legal:
                    emoji = '⚖️';
                    break;
                  case DomainMode.academic:
                    emoji = '🎓';
                    break;
                  case DomainMode.spiritual:
                    emoji = '🕉️';
                    break;
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Text(emoji, style: const TextStyle(fontSize: 14)),
                    label: Text(mode.displayName),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedMode = mode),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButton<String>(
            value: _selectedLocale,
            underline: const SizedBox(),
            isDense: true,
            style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500),
            icon: const Icon(Icons.expand_more_rounded,
                size: 18, color: Color(0xFF94A3B8)),
            items: const [
              DropdownMenuItem(
                  value: 'en_IN', child: Text('EN')),
              DropdownMenuItem(value: 'hi_IN', child: Text('HI')),
              DropdownMenuItem(value: 'mr_IN', child: Text('MR')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedLocale = value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextEditor(BuildContext context, DictationState state) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _controller,
        maxLines: null,
        expands: true,
        style: GoogleFonts.inter(
          color: const Color(0xFF1E293B),
          fontSize: 15,
          height: 1.6,
        ),
        decoration: InputDecoration.collapsed(
          hintText: 'Start dictating or type here...',
          hintStyle: GoogleFonts.inter(
            color: const Color(0xFFCBD5E1),
            fontSize: 15,
          ),
        ),
        onChanged: (value) =>
            context.read<DictationBloc>().add(UpdateTranscript(value)),
      ),
    );
  }

  Widget _buildMobileActionBar(BuildContext context, DictationState state) {
    final isListening = state.isDictating;
    final isProcessing = state.status == DictationStatus.processing;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left actions
          Row(
            children: [
              _buildActionIcon(
                icon: Icons.auto_fix_high_rounded,
                label: 'Analyze',
                onTap: isProcessing
                    ? null
                    : () {
                        if (_controller.text.trim().isEmpty) {
                          _showSnack('Nothing to analyze');
                          return;
                        }
                        context
                            .read<DictationBloc>()
                            .add(UpdateTranscript(_controller.text));
                        context.read<DictationBloc>().add(CleanTranscription());
                        context
                            .read<DictationBloc>()
                            .add(GenerateInsights(_selectedMode));
                      },
              ),
              const SizedBox(width: 4),
              _buildActionIcon(
                icon: _isSpeaking
                    ? Icons.stop_circle_rounded
                    : Icons.volume_up_rounded,
                label: _isSpeaking ? 'Stop' : 'Read',
                onTap: () async {
                  if (_isSpeaking) {
                    await _ttsService.stop();
                    setState(() => _isSpeaking = false);
                  } else {
                    if (_controller.text.trim().isEmpty) {
                      _showSnack('Nothing to read');
                      return;
                    }
                    setState(() => _isSpeaking = true);
                    final ttsLocale =
                        _ttsService.convertLocale(_selectedLocale);
                    await _ttsService.speak(_controller.text, locale: ttsLocale);
                  }
                },
              ),
            ],
          ),

          // Center mic button
          AnimatedMicButton(
            isListening: isListening,
            isProcessing: isProcessing,
            size: 60,
            onTap: () {
              if (isListening) {
                context.read<DictationBloc>().add(StopDictation());
                context.read<DictationBloc>().add(CleanTranscription());
                context
                    .read<DictationBloc>()
                    .add(GenerateInsights(_selectedMode));
              } else {
                context
                    .read<DictationBloc>()
                    .add(StartDictation(localeId: _selectedLocale));
              }
            },
          ),

          // Right actions
          Row(
            children: [
              _buildActionIcon(
                icon: Icons.copy_rounded,
                label: 'Copy',
                onTap: () {
                  if (_controller.text.trim().isEmpty) {
                    _showSnack('Nothing to copy');
                    return;
                  }
                  Clipboard.setData(ClipboardData(text: _controller.text));
                  _showSnack('Copied to clipboard');
                },
              ),
              const SizedBox(width: 4),
              _buildActionIcon(
                icon: Icons.save_alt_rounded,
                label: 'Save',
                onTap: () async {
                  if (_controller.text.isEmpty) {
                    _showSnack('Nothing to save');
                    return;
                  }
                  try {
                    final fileName =
                        'OmniScribe_${DateTime.now().millisecondsSinceEpoch}.txt';
                    await file_saver.saveFile(fileName, _controller.text);
                    await HistoryScreen.saveTranscript(
                        fileName, _controller.text);
                    if (context.mounted) {
                      _showSnack('Saved: $fileName');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      _showSnack('Save failed: $e');
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: onTap == null
                  ? const Color(0xFFF1F5F9)
                  : const Color(0xFFF8F9FC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: onTap == null
                  ? const Color(0xFFCBD5E1)
                  : const Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ─── DESKTOP LAYOUT (preserved) ──────────────────────────────

  Widget _buildDesktopLayout(BuildContext context, DictationState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(flex: 5, child: _buildDesktopDictationCanvas(context, state)),
          const VerticalDivider(width: 1, thickness: 1),
          SizedBox(width: 360, child: _buildDesktopInsightPanel(context, state)),
        ],
      ),
    );
  }

  Widget _buildDesktopDictationCanvas(
      BuildContext context, DictationState state) {
    final isListening = state.isDictating;
    final isProcessing = state.status == DictationStatus.processing;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Dictation Workspace',
                style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B))),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildModeSelector()),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.all(18),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  style: GoogleFonts.inter(
                      color: const Color(0xFF1E293B), fontSize: 16),
                  decoration: InputDecoration.collapsed(
                    hintText: 'Start dictating or type here...',
                    hintStyle: GoogleFonts.inter(color: const Color(0xFFCBD5E1)),
                  ),
                  onChanged: (value) =>
                      context.read<DictationBloc>().add(UpdateTranscript(value)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (isListening || isProcessing)
              _buildStatusBar(isListening, isProcessing),
            if (isListening || isProcessing) const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    if (isListening) {
                      context.read<DictationBloc>().add(StopDictation());
                      context.read<DictationBloc>().add(CleanTranscription());
                      context
                          .read<DictationBloc>()
                          .add(GenerateInsights(_selectedMode));
                    } else {
                      context.read<DictationBloc>().add(
                          StartDictation(localeId: _selectedLocale));
                    }
                  },
                  icon: Icon(isListening ? Icons.stop : Icons.mic, size: 18),
                  label: Text(isListening ? 'Stop' : 'Dictate'),
                ),
                OutlinedButton.icon(
                  onPressed: isProcessing
                      ? null
                      : () {
                          if (_controller.text.trim().isEmpty) {
                            _showSnack('Nothing to analyze');
                            return;
                          }
                          context
                              .read<DictationBloc>()
                              .add(UpdateTranscript(_controller.text));
                          context
                              .read<DictationBloc>()
                              .add(CleanTranscription());
                          context
                              .read<DictationBloc>()
                              .add(GenerateInsights(_selectedMode));
                        },
                  icon: const Icon(Icons.auto_fix_high, size: 18),
                  label: const Text('Analyze'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    if (_isSpeaking) {
                      await _ttsService.stop();
                      setState(() => _isSpeaking = false);
                    } else {
                      if (_controller.text.trim().isEmpty) {
                        _showSnack('Nothing to read');
                        return;
                      }
                      setState(() => _isSpeaking = true);
                      final ttsLocale =
                          _ttsService.convertLocale(_selectedLocale);
                      await _ttsService.speak(_controller.text,
                          locale: ttsLocale);
                    }
                  },
                  icon: Icon(
                      _isSpeaking
                          ? Icons.stop_circle_outlined
                          : Icons.volume_up,
                      size: 18),
                  label: Text(_isSpeaking ? 'Stop Reading' : 'Read Aloud'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    if (_controller.text.trim().isEmpty) {
                      _showSnack('Nothing to copy');
                      return;
                    }
                    Clipboard.setData(ClipboardData(text: _controller.text));
                    _showSnack('Copied to clipboard');
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    if (_controller.text.isEmpty) {
                      _showSnack('Nothing to save');
                      return;
                    }
                    try {
                      final fileName =
                          'OmniScribe_${DateTime.now().millisecondsSinceEpoch}.txt';
                      await file_saver.saveFile(fileName, _controller.text);
                      await HistoryScreen.saveTranscript(
                          fileName, _controller.text);
                      if (context.mounted) _showSnack('Saved: $fileName');
                    } catch (e) {
                      if (context.mounted) _showSnack('Save failed: $e');
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

  Widget _buildDesktopInsightPanel(
      BuildContext context, DictationState state) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('AI Co-Counsel',
                    style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B))),
                if (state.status == DictationStatus.processing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF6C63FF)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Mode: ${_selectedMode.displayName}',
                style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF94A3B8))),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: state.insights.isEmpty
                    ? [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Dictate or type text, then press Analyze to receive AI insights.',
                            style: GoogleFonts.inter(
                                color: const Color(0xFFCBD5E1)),
                          ),
                        ),
                      ]
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
