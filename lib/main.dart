import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:omniscribe_ai/app.dart';
import 'package:omniscribe_ai/src/blocs/dictation_bloc.dart';
import 'package:omniscribe_ai/src/services/voice_clone_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Launch the local server in the background (no-op if already running or not on Windows)
  await VoiceCloneService.autoStartServer();

  bool seenOnboarding = false;
  try {
    final prefs = await SharedPreferences.getInstance();
    seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
  } catch (e) {
    print('Error loading SharedPreferences: $e');
  }
  
  try {
    await dotenv.load(fileName: ".env");
    
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    
    if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
      );
    }
  } catch (e) {
    print('Error initializing environment or Supabase: $e');
  }

  runApp(
    BlocProvider(
      create: (_) => DictationBloc(),
      child: OmniScribeApp(seenOnboarding: seenOnboarding),
    ),
  );
}
