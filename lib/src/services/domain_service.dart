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

  Future<String> cleanTranscript(String transcript) async {
    return await _brainService.cleanTranscript(transcript);
  }

  String _getSystemPrompt(DomainMode mode) {
    const jsonInstruction = 'You must respond ONLY with a valid JSON array of objects. Each object must have "title" (string), "message" (string), and "type" (string: either "warning" or "suggestion"). Do not include markdown formatting or extra text.';
    switch (mode) {
      case DomainMode.legal:
        return 'You are an expert Indian Legal Co-Counsel. Review the following legal dictation/petition transcript. Identify critical feedback:\n'
            '1. Check for missing jurisdiction clauses (e.g., specific police station, FIR numbers).\n'
            '2. Validate citations or suggest relevant citations (e.g., Arnesh Kumar v. State of Bihar for arrest apprehension grounds).\n'
            '3. Validate sections under the BNS, BNSS, and BSA.\n$jsonInstruction';
      case DomainMode.academic:
        return 'You are an expert Academic Advisor. Review the following draft/thesis dictation. Identify structural and style feedback:\n'
            '1. Enforce rigorous thesis structure and logical flow.\n'
            '2. Flag claims that need proper formatting or missing citations/references.\n'
            '3. Suggest vocabulary improvements or logical links.\n$jsonInstruction';
      case DomainMode.spiritual:
        return 'You are a Spiritual Discourse Editor. Review the following dictation. Provide feedback to:\n'
            '1. Ensure scriptural accuracy and philosophical consistency.\n'
            '2. Flag phonetic discrepancies or filler words that distract from clarity.\n'
            '3. Suggest vocabulary that protects phonetic and spiritual integrity.\n$jsonInstruction';
    }
  }
}
