# 🏗️ OmniScribe AI Architecture Diagram

This document illustrates the architecture and data flow of the OmniScribe AI application.

```mermaid
graph TD
    %% Define styles
    classDef ui fill:#E0F2FE,stroke:#0369A1,stroke-width:2px,color:#0369A1;
    classDef bloc fill:#F5F3FF,stroke:#6D28D9,stroke-width:2px,color:#6D28D9;
    classDef service fill:#ECFDF5,stroke:#047857,stroke-width:2px,color:#047857;
    classDef external fill:#FFFBEB,stroke:#B45309,stroke-width:2px,color:#B45309;

    %% Components
    subgraph UI_Layer [User Interface]
        Home[HomeScreen - Dictation Workspace]
        Profile[VoiceProfileScreen - Custom Voice Setup]
        Manager[VoiceManagerScreen - Select Voice Target]
        Settings[SettingsScreen - Connection & Config]
    end

    subgraph Logic_Layer [State Management]
        Bloc[DictationBloc]
        Event[DictationEvent]
        State[DictationState]
    end

    subgraph Service_Layer [System & AI Services]
        STT[SpeechToTextService]
        Brain[BrainService - LLM Prompts & Formatting]
        TTS[TtsService - Text to Speech]
        Clone[VoiceCloneService - Local Generation]
        Sync[CloudSyncService - Remote Backups]
    end

    subgraph External_Layer [Backend & Local Servers]
        LocalServer[Local Voice/LLM Server - Port 5050]
        SupabaseDB[Supabase Cloud Database]
    end

    %% Apply styles
    class Home,Profile,Manager,Settings ui;
    class Bloc,Event,State bloc;
    class STT,Brain,TTS,Clone,Sync service;
    class LocalServer,SupabaseDB external;

    %% Data Flow Connections
    
    %% UI to Bloc
    Home -->|Triggers| Event
    Event -->|Updates| Bloc
    Bloc -->|Emits State| State
    State -->|Rebuilds| Home

    %% UI to direct services
    Profile -->|Microphone Audio| Sync
    Settings -->|Test Host Config| Clone
    Home -->|Play Text| TTS

    %% Bloc to Services
    Bloc -->|Control Speech| STT
    STT -->|Real-time Text| Bloc
    Bloc -->|Send Transcript| Brain

    %% Services to Backends
    Brain -->|REST API - Clean/Analyze| LocalServer
    Clone -->|REST API - Clone Voice| LocalServer
    Sync -->|Supabase Flutter SDK| SupabaseDB

```

---

## 🔁 Key Data Flows

### 1. Multilingual Speech-to-Text (STT)
1. User taps the **Microphone Button** on `HomeScreen`.
2. `HomeScreen` runs a system permission check (checks microphone/speech permissions).
3. If permissions are granted, `StartDictation` event is sent to `DictationBloc`.
4. `DictationBloc` calls `SpeechToTextService` to initialize the device microphone.
5. Voice input is processed real-time, sending words back to `DictationBloc` which updates `DictationState.transcript`.
6. UI listens to `DictationState` and displays the text live.

### 2. Domain-Aware AI Cleanups
1. When recording stops, `DictationBloc` fires `CleanTranscription` and `GenerateInsights`.
2. `DictationBloc` calls `BrainService.cleanTranscript(text)` and `BrainService.analyzeTranscript(text, domainPrompt)`.
3. `BrainService` executes HTTP requests to the **Local AI Server** (running llama.cpp / custom server on Port 5050).
4. The server returns formatted output (e.g. Legal, Academic, or Spiritual structure) and dynamic suggestions.
5. The UI updates text editor content and displays suggestions inside the **AI Insights Sheet**.

### 3. Voice Profile Creation & Cloud Sync
1. User opens `VoiceProfileScreen` and records standard validation text.
2. The audio is saved locally as a `.wav` file using `path_provider`.
3. If **Supabase** is configured, `CloudSyncService` uploads the audio file to the remote bucket `voice_profiles` and creates a document entry in the database.
4. If **Supabase** is not configured (offline mode), the app displays a warning card, and files are stored only on the local disk.
