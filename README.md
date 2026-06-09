# OmniScribe AI

OmniScribe AI is a cross-platform Flutter application scaffolded for intelligent multilingual dictation and domain-aware drafting. The goal is to build a hybrid voice assistant for legal, academic, and spiritual workflows that combines real-time STT with an LLM Brain.

## User requirements

### Core functionality
- Real-time dictation in Indian English, Hindi, and Marathi
- Code-switching support within a single spoken sentence
- Automatic punctuation and grammar cleanup
- Voice cloning and text-to-speech generation
- Domain-aware feedback for Indian legal, academic, and spiritual content
- Export audio as `.mp3` or `.wav`
- Cloud sync-ready architecture for documents and voice profiles

### Domain modes
- **Legal:** draft petitions, detect missing jurisdiction clauses, suggest case citations, validate BNSS/BNS/BSA content
- **Academic:** enforce thesis structure, format citations, flag missing analysis or references
- **Spiritual:** preserve scriptural accuracy, remove filler speech, protect phonetic clarity

## Current implementation status

### Completed scaffold & environment
- Flutter app structure created in `D:\mydictation`
- `lib/main.dart`, `lib/app.dart`, and responsive `HomeScreen`
- Bloc pattern scaffolded in `lib/src/blocs`
- Domain mode model and placeholder services created
- Insight card UI and dual-pane layout established
- VS Code task definitions and extension recommendations added
- `.env.example` created for API configuration
- Flutter SDK (3.13.8) installed and configured on PATH
- All package dependencies fetched successfully via `flutter pub get`
- Platform-specific folders initialized (`windows`, `android`, `ios`, `macos`, `linux`, `web`)

### Pending work
- Actual STT integration is still a placeholder in `lib/src/services/stt_service.dart`
- AI Brain / domain logic is still placeholder code
- Voice profile storage, consent screens, and export flows are not yet implemented

## Developer instructions

### Where to start
- `lib/src/screens/home_screen.dart` — main UI canvas and AI Co-Counsel panel
- `lib/src/blocs/dictation_bloc.dart` — dictation workflow state management
- `lib/src/services/stt_service.dart` — placeholder STT integration
- `lib/src/services/brain_service.dart` — placeholder AI Brain integration
- `lib/src/services/domain_service.dart` — domain-aware review logic

### Tasks for next development phase
1. Finalize Flutter SDK installation and run `flutter pub get`
2. Initialize missing platform targets or use `flutter create .`
3. Replace placeholder services with actual STT and LLM API calls
4. Add secure voice sample recording/upload workflows
5. Implement domain-aware insight card generation and prompting rules
6. Add cloud sync storage for documents and voice models

## Notes
This repo is currently a scaffold with strong architectural direction, but it still requires API integration and platform initialization before it can run end-to-end.
