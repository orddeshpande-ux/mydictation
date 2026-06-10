import 'package:flutter/material.dart';

class ConnectionStatusWidget extends StatelessWidget {
  final bool isConnected;
  final bool isChecking;
  final String? serverUrl;
  final VoidCallback? onTapConnect;

  const ConnectionStatusWidget({
    super.key,
    required this.isConnected,
    this.isChecking = false,
    this.serverUrl,
    this.onTapConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isConnected
            ? const Color(0xFFECFDF5)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected
              ? const Color(0xFF10B981).withOpacity(0.3)
              : const Color(0xFFEF4444).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          if (isChecking)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey.shade500,
              ),
            )
          else
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isConnected
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                boxShadow: [
                  BoxShadow(
                    color: (isConnected
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444))
                        .withOpacity(0.4),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isChecking
                      ? 'Connecting...'
                      : isConnected
                          ? 'AI Engine Connected'
                          : 'AI Engine Offline',
                  style: TextStyle(
                    color: isConnected
                        ? const Color(0xFF065F46)
                        : const Color(0xFF991B1B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (serverUrl != null && !isChecking)
                  Text(
                    serverUrl!,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          if (!isConnected && !isChecking && onTapConnect != null)
            GestureDetector(
              onTap: onTapConnect,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  'Setup',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
