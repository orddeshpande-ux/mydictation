import 'package:flutter/material.dart';

class TrainingGuideScreen extends StatelessWidget {
  const TrainingGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Training Guide'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How to Train Your Voice Model',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              'Follow these steps to create a high-quality voice clone from your recordings.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 32),

            _buildStep(
              number: '1',
              title: 'Prepare Your Audio Recordings',
              icon: Icons.audiotrack,
              color: Colors.blue,
              content: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gather recordings of the voice you want to clone. You can use:'),
                  SizedBox(height: 8),
                  _BulletPoint('Existing MP3/WAV/MP4 recordings'),
                  _BulletPoint('OmniScribe\'s "Voice Profile" recorder'),
                  _BulletPoint('Any voice memo or podcast recording'),
                  SizedBox(height: 12),
                  _TipBox(
                    title: 'Quality Tips',
                    tips: [
                      'Use clear audio with minimal background noise',
                      'At least 10-30 minutes total for best results',
                      'More variety in speech = better voice clone',
                      'Mono audio at 22050 Hz is ideal (but any format works)',
                    ],
                  ),
                ],
              ),
            ),

            _buildStep(
              number: '2',
              title: 'Create Matching Transcripts',
              icon: Icons.text_fields,
              color: Colors.green,
              content: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('For each audio file, create a transcript of exactly what was said.'),
                  SizedBox(height: 8),
                  _BulletPoint('Use OmniScribe\'s dictation to auto-transcribe'),
                  _BulletPoint('Or type/paste the transcript manually'),
                  _BulletPoint('The transcript must match the audio word-for-word'),
                  SizedBox(height: 12),
                  _TipBox(
                    title: 'Why Transcripts Matter',
                    tips: [
                      'The model learns which sounds correspond to which words',
                      'Accurate transcripts = accurate voice cloning',
                      'Code-switching (Hindi+English) works — just transcribe naturally',
                    ],
                  ),
                ],
              ),
            ),

            _buildStep(
              number: '3',
              title: 'Start the Voice Server',
              icon: Icons.dns,
              color: Colors.orange,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('The voice cloning runs on a local Python server. To start it:'),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Terminal Commands:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('cd voice_server', style: TextStyle(fontFamily: 'monospace', fontSize: 14)),
                        Text('run_server.bat', style: TextStyle(fontFamily: 'monospace', fontSize: 14)),
                        SizedBox(height: 12),
                        Text('Or manually:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('pip install -r requirements.txt', style: TextStyle(fontFamily: 'monospace', fontSize: 14)),
                        Text('python server.py', style: TextStyle(fontFamily: 'monospace', fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _TipBox(
                    title: 'Prerequisites',
                    tips: [
                      'Python 3.10 or newer',
                      'FFmpeg installed and on PATH',
                      'NVIDIA GPU with CUDA recommended (CPU works but is slow)',
                      '~4 GB free disk space for the XTTS model',
                    ],
                  ),
                ],
              ),
            ),

            _buildStep(
              number: '4',
              title: 'Upload & Train in Voice Manager',
              icon: Icons.upload_file,
              color: Colors.purple,
              content: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Go to the Voice Manager screen and:'),
                  SizedBox(height: 8),
                  _BulletPoint('Tap "+ Add Voice" to create a new profile'),
                  _BulletPoint('Give it a name (e.g., "Father\'s Voice")'),
                  _BulletPoint('Upload your audio files'),
                  _BulletPoint('Paste the matching transcript for each file'),
                  _BulletPoint('Tap "Create" then "Train"'),
                  SizedBox(height: 12),
                  Text(
                    'Training typically takes 5-30 minutes depending on your GPU and the amount of data.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),

            _buildStep(
              number: '5',
              title: 'Generate Speech & Export',
              icon: Icons.record_voice_over,
              color: Colors.red,
              content: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Once training is complete (status shows "ready"):'),
                  SizedBox(height: 8),
                  _BulletPoint('Tap "Generate Speech" on the voice card'),
                  _BulletPoint('Type or paste any text you want spoken'),
                  _BulletPoint('Choose output format: MP3, WAV, or MP4'),
                  _BulletPoint('Tap "Generate" and download the result'),
                  SizedBox(height: 12),
                  _TipBox(
                    title: 'Supported Languages',
                    tips: [
                      'English, Hindi, and many more',
                      'The model preserves accent and tone from your samples',
                      'Longer text generates longer audio — be patient',
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            _buildFaq('How much audio do I need?',
                'For basic cloning: just 6-10 seconds works (zero-shot). For high-quality voice matching: 10-30 minutes of varied speech is recommended.'),
            _buildFaq('Can I clone someone else\'s voice?',
                'Yes — upload recordings of your father, brother, or anyone else. Create a separate voice profile for each person.'),
            _buildFaq('Do I need a GPU?',
                'A GPU with CUDA support is strongly recommended for both training and generation. CPU-only mode works but is significantly slower.'),
            _buildFaq('What audio formats are supported?',
                'MP3, WAV, MP4, M4A, and OGG. The server handles all conversion automatically.'),
            _buildFaq('Can I improve the voice quality later?',
                'Yes! Add more audio samples to the same profile and retrain. More data = better voice quality.'),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required String number,
    required String title,
    required IconData icon,
    required Color color,
    required Widget content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color,
            child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 22),
                    const SizedBox(width: 8),
                    Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87)),
                  ],
                ),
                const SizedBox(height: 12),
                content,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaq(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(answer, style: const TextStyle(color: Colors.black54, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  const _BulletPoint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16, color: Colors.black54)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15, color: Colors.black87))),
        ],
      ),
    );
  }
}

class _TipBox extends StatelessWidget {
  final String title;
  final List<String> tips;
  const _TipBox({required this.title, required this.tips});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, size: 18, color: Colors.amber.shade700),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
            ],
          ),
          const SizedBox(height: 8),
          ...tips.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('• $t', style: const TextStyle(fontSize: 14, color: Colors.black87)),
              )),
        ],
      ),
    );
  }
}
