import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:omniscribe_ai/src/blocs/dictation_bloc.dart';
import 'package:omniscribe_ai/src/widgets/insight_card_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _controller;

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
                final isDesktop = constraints.maxWidth >= 900;
                return isDesktop
                    ? Row(
                        children: [
                          Expanded(flex: 3, child: _buildDictationCanvas(context, state)),
                          const VerticalDivider(width: 1),
                          Expanded(flex: 2, child: _buildInsightPanel(context)),
                        ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Dictation Workspace', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
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
    );
  }

  Widget _buildInsightPanel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('AI Co-Counsel', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
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
    );
  }
}
