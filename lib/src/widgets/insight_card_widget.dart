import 'package:flutter/material.dart';

enum InsightCardType { warning, suggestion, info }

class InsightCardWidget extends StatelessWidget {
  final String title;
  final String message;
  final InsightCardType type;

  const InsightCardWidget({
    super.key,
    required this.title,
    required this.message,
    required this.type,
  });

  Color _getAccentColor(BuildContext context) {
    switch (type) {
      case InsightCardType.warning:
        return const Color(0xFFEF4444);
      case InsightCardType.suggestion:
        return const Color(0xFF10B981);
      case InsightCardType.info:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Color _getBgColor(BuildContext context) {
    switch (type) {
      case InsightCardType.warning:
        return const Color(0xFFFEF2F2);
      case InsightCardType.suggestion:
        return const Color(0xFFECFDF5);
      case InsightCardType.info:
        return Theme.of(context).colorScheme.primary.withOpacity(0.08);
    }
  }

  IconData get _icon {
    switch (type) {
      case InsightCardType.warning:
        return Icons.warning_amber_rounded;
      case InsightCardType.suggestion:
        return Icons.lightbulb_rounded;
      case InsightCardType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _getAccentColor(context);
    final bgColor = _getBgColor(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
