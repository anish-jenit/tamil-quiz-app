import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaderboardPage extends StatefulWidget {
  final String level;
  const LeaderboardPage({super.key, this.level = 'expert'});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<_Entry> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'leaderboard_${widget.level}';
    final raw = prefs.getStringList(key) ?? <String>[];
    try {
      debugPrint('Loading leaderboard key: $key, entries: ${raw.length}');
    } catch (_) {}
    final entries = <_Entry>[];
    for (final s in raw) {
      // first try JSON
      try {
        final m = jsonDecode(s);
        if (m is Map<String, dynamic>) {
          final name = (m['name'] as String?) ?? 'Unknown';
          final score = (m['score'] is int) ? m['score'] as int : int.tryParse('${m['score']}') ?? 0;
          final when = DateTime.tryParse((m['timestamp'] as String?) ?? '') ?? DateTime.now();
          final playerId = (m['playerId'] as String?) ?? '';
          entries.add(_Entry(name: name, score: score, when: when, playerId: playerId));
          continue;
        }
      } catch (_) {
        // not JSON, fallthrough to legacy parse
      }
      try {
        final playerIdMatch = RegExp("playerId: (\\'|\")?(.*?)\\1(?:,|\\})").firstMatch(s);
        final nameMatch = RegExp("name: (\\'|\")?(.*?)\\1(?:,|\\})").firstMatch(s);
        final scoreMatch = RegExp("score: (\\d+)").firstMatch(s);
        final tsMatch = RegExp("timestamp: (\\'|\")?(.*?)\\1(?:,|\\})").firstMatch(s);
        final playerId = playerIdMatch?.group(2) ?? '';
        final name = nameMatch?.group(2) ?? 'Unknown';
        final score = scoreMatch != null ? int.tryParse(scoreMatch.group(1)!) ?? 0 : 0;
        final when = tsMatch != null ? DateTime.tryParse(tsMatch.group(2)!) ?? DateTime.now() : DateTime.now();
        entries.add(_Entry(name: name, score: score, when: when, playerId: playerId));
      } catch (_) {
        // ignore malformed entries
      }
    }
    entries.sort((a, b) => b.score.compareTo(a.score));
    if (entries.length > 50) entries.removeRange(50, entries.length);
    setState(() => _entries = entries);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard'), backgroundColor: cs.primary),
      body: ListView.builder(
        itemCount: _entries.length,
        itemBuilder: (context, i) {
          final e = _entries[i];
          return ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text(e.name),
            trailing: Text('${e.score} pts'),
            subtitle: Text('${e.when.toLocal()}'),
          );
        },
      ),
    );
  }
}

class _Entry {
  final String name;
  final int score;
  final DateTime when;
  final String playerId;
  _Entry({required this.name, required this.score, required this.when, required this.playerId});
}
