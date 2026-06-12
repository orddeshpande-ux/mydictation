import 'package:flutter/material.dart';
import 'package:omniscribe_ai/main.dart' show syncManager;
import 'package:omniscribe_ai/src/screens/home_screen.dart';
import 'package:omniscribe_ai/src/screens/voice_manager_screen.dart';
import 'package:omniscribe_ai/src/screens/history_screen.dart';
import 'package:omniscribe_ai/src/screens/settings_screen.dart';
import 'package:omniscribe_ai/src/widgets/sync_status_widget.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // Use a callback for loading transcripts from History into Home
  String? _pendingTranscript;

  void _onLoadTranscript(String content) {
    setState(() {
      _pendingTranscript = content;
      _currentIndex = 0; // Switch to Dictate tab
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Sync status bar (auto-hides when not syncing)
          SyncStatusWidget(syncManager: syncManager),
          // Main content
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                HomeScreen(pendingTranscript: _pendingTranscript, onTranscriptConsumed: () {
                  setState(() => _pendingTranscript = null);
                }),
                const VoiceManagerScreen(),
                HistoryScreen(onLoadTranscript: _onLoadTranscript),
                const SettingsScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.mic_rounded),
                  activeIcon: Icon(Icons.mic_rounded),
                  label: 'Dictate',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.graphic_eq_rounded),
                  activeIcon: Icon(Icons.graphic_eq_rounded),
                  label: 'Voices',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history_rounded),
                  activeIcon: Icon(Icons.history_rounded),
                  label: 'History',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_rounded),
                  activeIcon: Icon(Icons.settings_rounded),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
