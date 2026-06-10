import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();
  
  static const String _keySupabaseUrl = 'supabase_url';
  static const String _keySupabaseKey = 'supabase_anon_key';

  /// Save Supabase credentials to secure storage.
  Future<void> saveSupabaseCredentials(String url, String key) async {
    await _storage.write(key: _keySupabaseUrl, value: url);
    await _storage.write(key: _keySupabaseKey, value: key);
  }

  /// Retrieve Supabase credentials from secure storage.
  Future<Map<String, String>> getSupabaseCredentials() async {
    final url = await _storage.read(key: _keySupabaseUrl) ?? '';
    final key = await _storage.read(key: _keySupabaseKey) ?? '';
    return {
      'url': url,
      'key': key,
    };
  }

  /// Clear Supabase credentials from secure storage.
  Future<void> clearSupabaseCredentials() async {
    await _storage.delete(key: _keySupabaseUrl);
    await _storage.delete(key: _keySupabaseKey);
  }
}
