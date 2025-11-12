import 'dart:async';
import 'dart:convert';
import 'dart:math';
// imports kept minimal
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_flow/services/user_service.dart';
import 'login_flow/screens/profile/profile_creation_screen.dart';
import 'sample_questions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'leaderboard.dart';
import 'package:flutter/foundation.dart';

class PlaySoloPage extends StatefulWidget {
  final List<Question> questions;
  final int roundSize;
  final int timerSeconds;
  final String level; // 'easy', 'intermediate', 'expert'
  const PlaySoloPage({super.key, required this.questions, this.roundSize = 10, this.timerSeconds = 15, this.level = 'expert'});

  @override
  State<PlaySoloPage> createState() => _PlaySoloPageState();
}

class _PlaySoloPageState extends State<PlaySoloPage> {
  int _index = 0;
  int _score = 0;
  // track per-question time bonus
  int _timeBonus = 0;
  int? _selected;
  bool _showAnswer = false;
  List<Question> _roundQuestions = [];
  Timer? _tick;
  int _remaining = 0;
  // record per-question timings for scoring
  final List<int> _questionTimes = [];
  // record per-question selected indexes (-1 for timeout)
  final List<int> _selectedIndexes = [];
  // no-op

  void _select(int i) {
    if (_showAnswer) return;
    setState(() {
      _selected = i;
      _showAnswer = true;
      // record selected index and score
      _selectedIndexes.add(i);
      if (i == _roundQuestions[_index].correctIndex) {
        _score += 1; // base point
        _score += _remaining; // time bonus
        _timeBonus += _remaining;
      }
      _questionTimes.add(_remaining);
    });
    // advance after a short delay
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _index++;
        _selected = null;
        _showAnswer = false;
      });
      // restart timer for next question
      _startTimer();
    });
  }

  /// Prompts the user for a name and saves the result. Returns true if saved.
  Future<bool> _promptSaveResult() async {
    // If the user is signed in and has a profile, use their username automatically.
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final us = UserService();
      try {
        final profile = await us.getUserProfile(user.uid);
        if (profile != null && profile.username.trim() != '?') {
          await _saveResult(profile.username, _score);
          return true;
        }
        // else fall through to prompt for a name
      } catch (_) {
        // ignore and fall back to prompting
      }
    }

    final nameController = TextEditingController();
    if (!mounted) return false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save result'),
        content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Your name')),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Save')),
        ],
      ),
    );
    if (!mounted) return false;
    if (ok != true) return false;
    final name = nameController.text.trim();
    if (name.isEmpty) return false;
    await _saveResult(name, _score);
    return true;
  }

  Future<void> _saveResult(String name, int score) async {
    final prefs = await SharedPreferences.getInstance();
    // persistent player id per device
    var playerId = prefs.getString('player_id') ?? '';
    if (playerId.isEmpty) {
      playerId = '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000000)}';
      await prefs.setString('player_id', playerId);
    }

    final newEntry = {
      'playerId': playerId,
      'name': name,
      'score': score,
      'timestamp': DateTime.now().toIso8601String(),
      'questionTimes': _questionTimes,
      'selectedIndexes': _selectedIndexes,
    };

  final key = 'leaderboard_${widget.level}';
  final raw = prefs.getStringList(key) ?? <String>[];
    final parsed = <Map<String, dynamic>>[];
    for (final s in raw) {
      try {
        final m = jsonDecode(s);
        if (m is Map<String, dynamic>) parsed.add(m);
      } catch (_) {
        // ignore non-json legacy entries
      }
    }
    parsed.add(newEntry);
    parsed.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    final trimmed = parsed.take(50).map((m) => jsonEncode(m)).toList();
    await prefs.setStringList(key, trimmed);
  }

  void _restart() {
    // Don't call async work inside setState. Prepare a fresh round.
    _prepareRound();
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed out')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign out failed: $e')));
    }
  }

  Future<void> _openProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in to edit your profile')));
      return;
    }
    final us = UserService();
    try {
      final profile = await us.getUserProfile(user.uid);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileCreationScreen(userId: user.uid, email: user.email ?? '', userService: us, initialProfile: profile)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to open profile: $e')));
    }
  }

  void _startTimer() {
    _tick?.cancel();
    _remaining = widget.timerSeconds;
    _tick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _remaining--;
      });
      if (_remaining <= 0) {
        _tick?.cancel();
        if (!mounted) return;
        setState(() {
          _showAnswer = true;
        });
        Future.delayed(const Duration(milliseconds: 900), () {
          if (!mounted) {
            return;
          }
          setState(() {
            // time ran out -> record 0 seconds and -1 selection, then move on
            _questionTimes.add(0);
            _selectedIndexes.add(-1);
            _index++;
            _selected = null;
            _showAnswer = false;
          });
          _startTimer();
        });
      }
    });
  }

  void _prepareRound() async {
    final pool = List<Question>.from(widget.questions);
    pool.shuffle();

  final prefs = await SharedPreferences.getInstance();
  final usedKey = 'used_question_ids_${widget.level}';
  final used = prefs.getStringList(usedKey) ?? <String>[];
  final usedSet = used.toSet();

    // Filter out used questions
  List<Question> available = pool.where((q) => !usedSet.contains(q.id)).toList();
  // Shuffle available again after filtering to avoid ordering artifacts
  available.shuffle();

    // If not enough available questions, reset used set and use full pool
    if (available.length < widget.roundSize) {
      await prefs.setStringList(usedKey, <String>[]);
      available = List<Question>.from(pool);
    }

    final take = widget.roundSize <= available.length ? widget.roundSize : available.length;
    _roundQuestions = available.take(take).toList();

  // reset per-round tracking arrays
  _questionTimes.clear();
  _selectedIndexes.clear();

    // Append chosen ids to used list and persist
    final newUsed = {...usedSet, ..._roundQuestions.map((q) => q.id)}.toList();
    await prefs.setStringList(usedKey, newUsed);

    // Debug: log prepared round ids
    try {
      debugPrint('Prepared round for level ${widget.level}: ${_roundQuestions.map((q) => q.id).toList()}');
    } catch (_) {}

    setState(() {
      _index = 0;
      _score = 0;
      _selected = null;
      _showAnswer = false;
    });

    _startTimer();
  }

  @override
  void initState() {
    super.initState();
    _prepareRound();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
  if (_index >= _roundQuestions.length) {
      // results
      return Scaffold(
        appBar: AppBar(
          title: const Text('Results'),
          backgroundColor: cs.primary,
          actions: [
            if (FirebaseAuth.instance.currentUser != null) ...[
              IconButton(onPressed: _openProfile, icon: const Icon(Icons.person)),
              IconButton(onPressed: _signOut, icon: const Icon(Icons.logout_rounded)),
            ],
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Score', style: TextStyle(fontSize: 18, color: cs.onSurface)),
                const SizedBox(height: 12),
                Text('$_score points', style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Base points: ${_roundQuestions.length} + Time bonus: $_timeBonus', style: TextStyle(color: cs.onSurface.withAlpha((0.9 * 255).round()))),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _restart,
                  child: const Text('Play Again'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final did = await _promptSaveResult();
                    if (!mounted) return;
                    if (did) {
                      messenger.showSnackBar(const SnackBar(content: Text('Result saved')));
                    }
                  },
                  child: const Text('Save Result'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LeaderboardPage(level: widget.level))),
                  child: const Text('View Leaderboard'),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text('Per-question breakdown', style: TextStyle(fontSize: 16, color: cs.onSurface)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 240,
                  child: ListView.builder(
                    itemCount: _roundQuestions.length,
                    itemBuilder: (context, i) {
                      final q = _roundQuestions[i];
                      final selected = i < _selectedIndexes.length ? _selectedIndexes[i] : -1;
                      final time = i < _questionTimes.length ? _questionTimes[i] : 0;
                      final correct = selected == q.correctIndex;
                      return ListTile(
                        title: Text(q.text, maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: Text('Answer: ${selected >= 0 && selected < q.options.length ? q.options[selected] : 'No answer'} • Time: ${time}s'),
                        trailing: Icon(correct ? Icons.check_circle : Icons.cancel, color: correct ? Colors.green : Colors.red),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

  final q = _roundQuestions[_index];
    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_index + 1} / ${_roundQuestions.length}'),
        backgroundColor: cs.primary,
        elevation: 0,
        actions: [
          if (FirebaseAuth.instance.currentUser != null) ...[
            IconButton(onPressed: _openProfile, icon: const Icon(Icons.person)),
            IconButton(onPressed: _signOut, icon: const Icon(Icons.logout_rounded)),
          ],
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: cs.surface,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(q.text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(color: cs.surfaceContainerHighest.withAlpha((0.3 * 255).round()), borderRadius: BorderRadius.circular(12)),
                  child: Text('$_remaining s', style: TextStyle(color: cs.onSurface.withAlpha((0.9 * 255).round()))),
                ),
              ),

              ...List.generate(q.options.length, (i) {
                final correct = i == q.correctIndex;
                final selected = i == _selected;
                Color bg;
                if (_showAnswer) {
                  if (correct) {
                    bg = Colors.green.shade400;
                  } else if (selected) {
                    bg = Colors.red.shade400;
                  } else {
                    bg = cs.surfaceContainerHighest.withAlpha((0.6 * 255).round());
                  }
                } else {
                  bg = cs.surfaceContainerHighest.withAlpha((0.4 * 255).round());
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    onTap: () => _select(i),
                    borderRadius: BorderRadius.circular(12),
                    child: Ink(
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        child: Text(q.options[i], style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Exit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _showAnswer ? null : () => _select(q.correctIndex),
                    child: const Text('Show Answer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      // Debug-only helper to insert sample leaderboard entries for testing
      floatingActionButton: kDebugMode
          ? FloatingActionButton.extended(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final prefs = await SharedPreferences.getInstance();
                final now = DateTime.now().toIso8601String();
                final sample = {
                  'playerId': 'debug_1',
                  'name': 'DebugUser',
                  'score': 42,
                  'timestamp': now,
                };
                for (final lvl in ['easy', 'intermediate', 'expert']) {
                  final key = 'leaderboard_$lvl';
                  final raw = prefs.getStringList(key) ?? <String>[];
                  final parsed = <Map<String, dynamic>>[];
                  for (final s in raw) {
                    try {
                      final m = jsonDecode(s);
                      if (m is Map<String, dynamic>) parsed.add(m);
                    } catch (_) {}
                  }
                  parsed.add(sample);
                  await prefs.setStringList(key, parsed.map((m) => jsonEncode(m)).toList());
                }
                if (!mounted) return;
                messenger.showSnackBar(const SnackBar(content: Text('Inserted debug leaderboard entries')));
              },
              label: const Text('Insert Debug Scores'),
            )
          : null,
    );
  }
}
