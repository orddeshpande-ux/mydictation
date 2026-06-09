import 'package:omniscribe_ai/src/models/domain_mode.dart';
import 'package:omniscribe_ai/src/services/brain_service.dart';

class DomainService {
  final BrainService _brainService;

  DomainService({BrainService? brainService})
      : _brainService = brainService ?? BrainService();

  Future<String> reviewTranscript(String transcript, DomainMode mode) async {
    final systemPrompt = _getSystemPrompt(mode);
    return await _brainService.analyzeTranscript(transcript, systemPrompt);
  }

  String _getSystemPrompt(DomainMode mode) {
    switch (mode) {
      case DomainMode.legal:
        return 'You are an expert Indian Legal Co-Counsel. Review the following legal dictation/petition transcript. Identify critical feedback:\n'
            '1. Check for missing jurisdiction clauses (e.g., specific police station, FIR numbers).\n'
            '2. Validate citations or suggest relevant citations (e.g., Arnesh Kumar v. State of Bihar for arrest apprehension grounds).\n'
            '3. Validate sections under the Bharatiya Nyaya Sanhita (BNS), Bharatiya Nagarik Suraksha Sanhita (BNSS), and Bharatiya Sakshya Adhiniyam (BSA).\n'
            'Provide your response as a bulleted list of actionable insights under titles: "Warning" or "Suggestion".';
      case DomainMode.academic:
        return 'You are an expert Academic Advisor. Review the following draft/thesis dictation. Identify structural and style feedback:\n'
            '1. Enforce rigorous thesis structure and logical flow.\n'
            '2. Flag claims that need proper formatting or missing citations/references.\n'
            '3. Suggest vocabulary improvements or logical links.\n'
            'Provide your response as a list of actionable insights under titles: "Warning" or "Suggestion".';
      case DomainMode.spiritual:
        return 'You are a Spiritual Discourse Editor. Review the following dictation. Provide feedback to:\n'
            '1. Ensure scriptural accuracy and philosophical consistency.\n'
            '2. Flag phonetic discrepancies or filler words (e.g., "uh", "um", "like") that distract from clarity.\n'
            '3. Suggest vocabulary that protects phonetic and spiritual integrity.\n'
            'Provide your response as a list of actionable insights under titles: "Warning" or "Suggestion".';
    }
  }
}
