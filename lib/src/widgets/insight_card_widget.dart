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

  Color get _color {
    switch (type) {
      case InsightCardType.warning:
        return Colors.redAccent;
      case InsightCardType.suggestion:
        return Colors.greenAccent;
      default:
        return Colors.blueAccent;
    }
  }

  IconData get _icon {
    switch (type) {
      case InsightCardType.warning:
        return Icons.warning_amber_rounded;
      case InsightCardType.suggestion:
        return Icons.lightbulb;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_icon, color: _color, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(message, style: const TextStyle(fontSize: 14, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
