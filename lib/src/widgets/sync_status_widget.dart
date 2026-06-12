import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:omniscribe_ai/src/sync/sync_manager.dart';

/// A compact, non‑intrusive sync status indicator.
///
/// Shows a small animated bar at the top of the screen when the sync manager
/// is discovering peers or actively syncing.  Disappears when idle.
class SyncStatusWidget extends StatelessWidget {
  final SyncManager? syncManager;

  const SyncStatusWidget({super.key, this.syncManager});

  @override
  Widget build(BuildContext context) {
    final manager = syncManager;
    if (manager == null) {
      return const SizedBox.shrink();
    }
    return ListenableBuilder(
      listenable: manager,
      builder: (context, _) {
        final showBar =
            manager.isDiscovering || manager.isSyncing;

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
              ? _buildBar(context, manager)
              : const SizedBox.shrink(key: ValueKey('hidden')),
        );
      },
    );
  }

  Widget _buildBar(BuildContext context, SyncManager manager) {
    final isSyncing = manager.isSyncing;

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
            manager.statusText.isNotEmpty
                ? manager.statusText
                : (manager.isDiscovering
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
