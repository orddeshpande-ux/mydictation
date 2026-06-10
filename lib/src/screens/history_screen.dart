import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryScreen extends StatefulWidget {
  final Function(String)? onLoadTranscript;
  
  const HistoryScreen({super.key, this.onLoadTranscript});

  static Future<void> saveTranscript(String title, String content) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('transcript_history') ?? [];
    historyJson.add(jsonEncode({
      'title': title,
      'content': content,
      'date': DateTime.now().toIso8601String(),
    }));
    await prefs.setStringList('transcript_history', historyJson);
  }

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, String>> _transcripts = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('transcript_history') ?? [];
    setState(() {
      _transcripts = historyJson
          .map((e) => Map<String, String>.from(jsonDecode(e)))
          .toList()
          .reversed
          .toList();
    });
  }

  Future<void> _deleteItem(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList('transcript_history') ?? [];
    // Reverse index since we display reversed
    final actualIndex = historyJson.length - 1 - index;
    if (actualIndex >= 0 && actualIndex < historyJson.length) {
      historyJson.removeAt(actualIndex);
      await prefs.setStringList('transcript_history', historyJson);
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transcript History'),
      ),
      body: _transcripts.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.black26),
                  SizedBox(height: 16),
                  Text('No saved transcripts yet.',
                      style: TextStyle(fontSize: 18, color: Colors.black45)),
                  SizedBox(height: 8),
                  Text('Use the Save button on the main screen to save your work.',
                      style: TextStyle(fontSize: 14, color: Colors.black38)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _transcripts.length,
              itemBuilder: (context, index) {
                final item = _transcripts[index];
                final title = item['title'] ?? 'Untitled';
                final content = item['content'] ?? '';
                final dateStr = item['date'] ?? '';
                String formattedDate = '';
                try {
                  final date = DateTime.parse(dateStr);
                  formattedDate =
                      '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
                } catch (_) {
                  formattedDate = dateStr;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, color: Colors.black87)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          content.length > 120
                              ? '${content.substring(0, 120)}...'
                              : content,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black54),
                        ),
                        const SizedBox(height: 6),
                        Text(formattedDate,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black38)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.open_in_new,
                              color: Colors.blueAccent),
                          tooltip: 'Load into workspace',
                          onPressed: () {
                            if (widget.onLoadTranscript != null) {
                              widget.onLoadTranscript!(content);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Transcript loaded into workspace')),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.delete_outline, color: Colors.red),
                          tooltip: 'Delete',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Transcript'),
                                content: const Text(
                                    'Are you sure you want to delete this transcript?'),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel')),
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      child: const Text('Delete',
                                          style:
                                              TextStyle(color: Colors.red))),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              _deleteItem(index);
                            }
                          },
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
