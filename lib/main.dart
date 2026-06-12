import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:omniscribe_ai/app.dart';
import 'package:omniscribe_ai/src/blocs/dictation_bloc.dart';
import 'package:omniscribe_ai/src/services/voice_clone_service.dart';
import 'package:omniscribe_ai/src/services/secure_storage_service.dart';
import 'package:omniscribe_ai/src/sync/sync_manager.dart';

/// Global sync manager – initialised once in main() and shared app‑wide.
SyncManager? syncManager;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Launch the local server in the background (no-op if already running or not on Windows)
  await VoiceCloneService.autoStartServer();

  // Initialise automatic Wi‑Fi sync (zero user configuration)
  syncManager = SyncManager();
  await syncManager!.initialize();

  bool seenOnboarding = false;
  try {
    final prefs = await SharedPreferences.getInstance();
    seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
  } catch (e) {
    print('Error loading SharedPreferences: $e');
  }
  
  final secureStorage = SecureStorageService();
  String supabaseUrl = '';
  String supabaseKey = '';

  try {
    final creds = await secureStorage.getSupabaseCredentials();
    supabaseUrl = creds['url'] ?? '';
    supabaseKey = creds['key'] ?? '';
  } catch (e) {
    print('SecureStorage: Error loading credentials: $e');
  }

  // Fallback to .env if secure storage is empty
  if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
    try {
      await dotenv.load(fileName: ".env");
      supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      
      // If we found valid keys in .env, cache them in secure storage
      if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
        await secureStorage.saveSupabaseCredentials(supabaseUrl, supabaseKey);
        print('SecureStorage: Cached .env credentials in secure storage.');
      }
    } catch (e) {
      print('dotenv: Failed to load .env file: $e');
    }
  }

  if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
      );
      print('Supabase: Initialized successfully.');
    } catch (e) {
      print('Supabase: Initialization failed: $e');
    }
  } else {
    print('WARNING: Supabase URL or Anon Key is missing. Cloud sync features will be disabled. Connect a database via Settings or specify variables in .env.');
  }

  runApp(
    BlocProvider(
      create: (_) => DictationBloc(),
      child: OmniScribeApp(seenOnboarding: seenOnboarding),
    ),
  );
}
