# OmniScribe AI

OmniScribe AI is a cross-platform Flutter workspace scaffolded for a domain-aware dictation and voice assistant app.

## Current setup
- Flutter-style Dart application structure
- Bloc state management scaffold
- Dual-pane home screen for desktop + mobile
- Placeholder services for STT and AI Brain integration

## Next steps
1. Install Flutter SDK locally and run `flutter pub get`
2. Create platform projects with `flutter create .` if needed, or add existing `android`, `ios`, `windows`, and `macos` folders
3. Use the `.vscode/tasks.json` commands to run `flutter pub get`, `flutter analyze`, and `flutter run -d windows`
4. Implement STT integration with OpenAI Whisper or Google Chirp and the AI Brain with a legal/academic/spiritual RAG pipeline

## Notes
The Flutter CLI is not installed in this environment, so the generated project is scaffolded at the code level only. Replace placeholder services in `lib/src/services` with real API integration once Flutter is available.
