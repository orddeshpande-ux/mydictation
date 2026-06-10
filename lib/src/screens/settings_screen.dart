import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:omniscribe_ai/src/services/voice_clone_service.dart';
import 'package:omniscribe_ai/src/services/secure_storage_service.dart';
import 'package:omniscribe_ai/src/widgets/glass_card.dart';
import 'package:omniscribe_ai/src/widgets/omni_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _supabaseUrlController = TextEditingController();
  final TextEditingController _supabaseKeyController = TextEditingController();
  final SecureStorageService _secureStorage = SecureStorageService();
  
  bool _isChecking = false;
  bool? _isConnected;
  bool _isSavingDb = false;

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _supabaseUrlController.dispose();
    _supabaseKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadUrl() async {
    await VoiceCloneService.loadBaseUrl();
    _urlController.text = VoiceCloneService.baseUrl;
    _testConnection();

    try {
      final creds = await _secureStorage.getSupabaseCredentials();
      _supabaseUrlController.text = creds['url'] ?? '';
      _supabaseKeyController.text = creds['key'] ?? '';
    } catch (_) {}
  }

  Future<void> _testConnection() async {
    setState(() => _isChecking = true);
    final service = VoiceCloneService();
    final connected = await service.isServerRunning();
    if (mounted) {
      setState(() {
        _isChecking = false;
        _isConnected = connected;
      });
    }
  }

  Future<void> _saveAndTest() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    await VoiceCloneService.saveBaseUrl(url);
    await _testConnection();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isConnected == true
              ? 'Connected to AI server!'
              : 'Could not connect to $url'),
        ),
      );
    }
  }

  Future<void> _saveDbSettings() async {
    setState(() => _isSavingDb = true);
    final url = _supabaseUrlController.text.trim();
    final key = _supabaseKeyController.text.trim();
    
    await _secureStorage.saveSupabaseCredentials(url, key);
    setState(() => _isSavingDb = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Database settings saved! Restart the app to apply changes.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Server Connection
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.dns_rounded,
                            color: Theme.of(context).colorScheme.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Server Connection',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Connect your phone to the AI engine on your computer',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Connection status
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _isChecking
                          ? const Color(0xFFF8FAFC)
                          : _isConnected == true
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        if (_isChecking)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isConnected == true
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                            ),
                          ),
                        const SizedBox(width: 10),
                        Text(
                          _isChecking
                              ? 'Checking connection...'
                              : _isConnected == true
                                  ? 'Connected'
                                  : 'Not connected',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _isChecking
                                ? const Color(0xFF64748B)
                                : _isConnected == true
                                    ? const Color(0xFF065F46)
                                    : const Color(0xFF991B1B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // URL input
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'e.g., http://192.168.1.5:5050',
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // How to find IP help text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFFDE68A).withOpacity(0.5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.wifi_rounded,
                            color: Colors.amber.shade700, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Make sure both your laptop and phone are connected to the same Wi-Fi network. Tap "Auto-Detect" below to automatically scan and find the server.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF92400E),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: OmniButton(
                          label: 'Auto-Detect',
                          onPressed: () async {
                            setState(() => _isChecking = true);
                            final discoveredUrl = await VoiceCloneService.discoverLocalServer();
                            if (discoveredUrl != null) {
                              await VoiceCloneService.saveBaseUrl(discoveredUrl);
                              _urlController.text = discoveredUrl;
                              await _testConnection();
                            } else {
                              setState(() => _isChecking = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Could not find AI server. Please check your Wi-Fi network and try again.'),
                                  ),
                                );
                              }
                            }
                          },
                          icon: Icons.search_rounded,
                          isLoading: _isChecking,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _saveAndTest,
                          icon: const Icon(Icons.wifi_find_rounded, size: 18),
                          label: const Text('Save & Test'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Database Connection
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.cloud_queue_rounded,
                            color: Theme.of(context).colorScheme.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cloud Database Connection',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Configure Supabase to back up voice profiles and documents',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _supabaseUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Supabase URL',
                      hintText: 'https://xxxxxx.supabase.co',
                      prefixIcon: Icon(Icons.cloud_circle_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _supabaseKeyController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Supabase Anon Key',
                      hintText: 'Enter anon public key...',
                      prefixIcon: Icon(Icons.vpn_key_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: OmniButton(
                      label: 'Save Database Settings',
                      onPressed: _saveDbSettings,
                      icon: Icons.save_rounded,
                      isLoading: _isSavingDb,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // About section
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'OmniScribe AI',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              'Version 0.1.0',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cross-platform domain-aware dictation and voice assistant. '
                    'All AI processing runs locally on your computer for maximum privacy.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFeatureChip('⚖️ Legal'),
                      _buildFeatureChip('🎓 Academic'),
                      _buildFeatureChip('🕉️ Spiritual'),
                      _buildFeatureChip('🎤 Voice Clone'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),),);
  }

  Widget _buildFeatureChip(String label) {
    return Chip(
      label: Text(label),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
