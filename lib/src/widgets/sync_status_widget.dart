import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:omniscribe_ai/src/sync/sync_manager.dart';

/// A compact, non‑intrusive sync status indicator.
///
/// Shows a small animated bar at the top of the screen when the sync manager
/// is discovering peers or actively syncing.  Disappears when idle.
class SyncStatusWidget extends StatelessWidget {
  final SyncManager syncManager;

  const SyncStatusWidget({super.key, required this.syncManager});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: syncManager,
      builder: (context, _) {
        final showBar =
            syncManager.isDiscovering || syncManager.isSyncing;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
          child: showBar
              ? _buildBar(context)
              : const SizedBox.shrink(key: ValueKey('hidden')),
        );
      },
    );
  }

  Widget _buildBar(BuildContext context) {
    final isSyncing = syncManager.isSyncing;

    return Container(
      key: const ValueKey('visible'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSyncing
              ? [
                  const Color(0xFF0F766E).withOpacity(0.10),
                  const Color(0xFF0D9488).withOpacity(0.15),
                ]
              : [
                  const Color(0xFFF1F5F9),
                  const Color(0xFFE2E8F0),
                ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isSyncing
                  ? const Color(0xFF0F766E)
                  : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            syncManager.statusText.isNotEmpty
                ? syncManager.statusText
                : (syncManager.isDiscovering
                    ? 'Looking for devices on Wi‑Fi…'
                    : 'Syncing…'),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSyncing
                  ? const Color(0xFF0F766E)
                  : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
