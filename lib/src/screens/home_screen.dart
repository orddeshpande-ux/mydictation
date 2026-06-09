import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omniscribe_ai/src/blocs/dictation_bloc.dart';
import 'package:omniscribe_ai/src/models/domain_mode.dart';
import 'package:omniscribe_ai/src/widgets/insight_card_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const desktopBreakpoint = 900;

  late final TextEditingController _controller;
  DomainMode _selectedMode = DomainMode.legal;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OmniScribe AI'),
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
                            SizedBox(width: 360, child: _buildInsightPanel(context)),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(child: _buildDictationCanvas(context, state)),
                          const Divider(height: 1),
                          SizedBox(height: 320, child: _buildInsightPanel(context)),
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

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Dictation Workspace', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
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
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade950,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(18),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: const InputDecoration.collapsed(hintText: 'Start dictating...'),
                  onChanged: (value) => context.read<DictationBloc>().add(UpdateTranscript(value)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                if (isListening) {
                  context.read<DictationBloc>().add(StopDictation());
                } else {
                  context.read<DictationBloc>().add(StartDictation());
                }
              },
              icon: Icon(isListening ? Icons.stop : Icons.mic),
              label: Text(isListening ? 'Stop Dictation' : 'Start Dictation'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightPanel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('AI Co-Counsel', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text('Current mode: ${_selectedMode.displayName}', style: const TextStyle(fontSize: 14, color: Colors.white70)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: const [
                  InsightCardWidget(
                    title: 'Missing Jurisdiction Clause',
                    message: 'For a High Court petition, specify the exact police station or FIR number.',
                    type: InsightCardType.warning,
                  ),
                  InsightCardWidget(
                    title: 'Citation Suggestion',
                    message: 'Consider citing Arnesh Kumar v. State of Bihar for arrest apprehension grounds.',
                    type: InsightCardType.suggestion,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
