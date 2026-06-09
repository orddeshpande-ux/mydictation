# AI Guide

This repo is configured for AI-assisted development focused on building OmniScribe AI as a domain-aware dictation assistant.

## Purpose
- Scaffold the Flutter UI and app architecture for a cross-platform dictation product
- Separate domain logic from UI and integration services
- Support legal, academic, and spiritual workflows with an AI Brain layer

## User requirements summary
- Multilingual dictation for Indian English, Hindi, and Marathi
- Voice cloning and TTS generation with export support
- Domain-aware feedback for legal, academic, and spiritual contexts
- Quiet AI insight generation during dictation pauses
- Clean, minimal UI with a dual-pane desktop and split-screen mobile layout

## Current developer status
- Core app scaffold is in place
- Responsive UI and Bloc structure are implemented
- Placeholder STT and AI review services exist
- No platform-specific targets or real API integration yet
- Flutter SDK installation is in progress and dependency fetching is pending final setup

## Key files and responsibilities
- `.github/copilot-instructions.md` — AI assistant behavior and workspace guidance
- `.vscode/tasks.json` — tasks for `flutter pub get`, `flutter analyze`, and `flutter run`
- `lib/src/screens/home_screen.dart` — main screen and insight panel layout
- `lib/src/blocs/dictation_bloc.dart` — dictation event and state logic
- `lib/src/services/stt_service.dart` — STT integration placeholder
- `lib/src/services/brain_service.dart` — AI Brain placeholder
- `lib/src/services/domain_service.dart` — domain review placeholder
- `lib/src/models/domain_mode.dart` — legal/academic/spiritual mode definitions

## Development guidance
- Make small incremental changes
- Keep integration points isolated in `lib/src/services`
- Validate UI and logic with `flutter analyze` once the SDK is available
- Avoid adding broad new dependencies until core API integration is complete

## Notes
This guide is intended to help developers understand both the user-facing requirements and our current implementation progress.
