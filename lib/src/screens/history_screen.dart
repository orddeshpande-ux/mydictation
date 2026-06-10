import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:omniscribe_ai/src/widgets/glass_card.dart';

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
  String _searchQuery = '';

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
    final actualIndex = historyJson.length - 1 - index;
    if (actualIndex >= 0 && actualIndex < historyJson.length) {
      historyJson.removeAt(actualIndex);
      await prefs.setStringList('transcript_history', historyJson);
      _loadHistory();
    }
  }

  List<Map<String, String>> get _filteredTranscripts {
    if (_searchQuery.isEmpty) return _transcripts;
    return _transcripts.where((item) {
      final title = (item['title'] ?? '').toLowerCase();
      final content = (item['content'] ?? '').toLowerCase();
      return title.contains(_searchQuery.toLowerCase()) ||
          content.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';

      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTranscripts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search transcripts...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFF94A3B8)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
            ),
          ),

          // Content
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.history_rounded,
                              size: 40, color: Color(0xFF6C63FF)),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No results found'
                              : 'No saved transcripts yet',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Try a different search term'
                              : 'Use the Save button to save your work',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final title = item['title'] ?? 'Untitled';
                      final content = item['content'] ?? '';
                      final dateStr = item['date'] ?? '';
                      final dateLabel = _formatDate(dateStr);
                      final timeLabel = _formatTime(dateStr);

                      // Group header
                      bool showHeader = false;
                      if (index == 0) {
                        showHeader = true;
                      } else {
                        final prevDate = filtered[index - 1]['date'] ?? '';
                        showHeader = _formatDate(prevDate) != dateLabel;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showHeader)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 16, bottom: 8),
                              child: Text(
                                dateLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF94A3B8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          Dismissible(
                            key: Key('$index-${item['date']}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              child: const Icon(Icons.delete_rounded,
                                  color: Colors.white),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Transcript'),
                                  content: const Text(
                                      'Are you sure you want to delete this?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      child: const Text('Delete',
                                          style:
                                              TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (_) => _deleteItem(index),
                            child: GlassCard(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(16),
                              child: InkWell(
                                onTap: () {
                                  if (widget.onLoadTranscript != null) {
                                    widget.onLoadTranscript!(content);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Transcript loaded into workspace')),
                                    );
                                  }
                                },
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: const Color(0xFF1E293B),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          timeLabel,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      content.length > 100
                                          ? '${content.substring(0, 100)}...'
                                          : content,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: const Color(0xFF64748B),
                                        height: 1.4,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
