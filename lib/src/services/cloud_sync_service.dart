import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class CloudSyncService {
  SupabaseClient? _supabase;

  CloudSyncService() {
    try {
      _supabase = Supabase.instance.client;
    } catch (e) {
      _supabase = null;
    }
  }

  Future<String?> uploadVoiceProfile(File audioFile, String userId) async {
    if (_supabase == null) {
      print('CloudSync Error: Supabase not initialized.');
      return null;
    }
    try {
      final fileName = 'voice_profile_$userId.wav';
      final storageResponse = await _supabase!
          .storage
          .from('voice_profiles')
          .upload(fileName, audioFile, fileOptions: const FileOptions(upsert: true));

      return storageResponse;
    } catch (e) {
      print('CloudSync Error uploading voice profile: $e');
      return null;
    }
  }

  Future<bool> saveDocument(String title, String content, String userId) async {
    if (_supabase == null) return false;
    try {
      await _supabase!.from('documents').insert({
        'user_id': userId,
        'title': title,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('CloudSync Error saving document: $e');
      return false;
    }
  }
}
