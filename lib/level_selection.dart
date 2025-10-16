import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'sample_questions.dart';
import 'play_solo.dart';

List<dynamic> _parseJson(String raw) {
  return json.decode(raw) as List<dynamic>;
}

class LevelSelectionPage extends StatelessWidget {
  // mode can be 'solo', 'create_group', 'join_group' to adapt behavior
  final String mode;

  const LevelSelectionPage({super.key, this.mode = 'solo'});

  void _start(BuildContext context, List<Question> questions, String level) {
    // For now, group flows also start the same PlaySoloPage (no real sync implemented)
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlaySoloPage(questions: questions, level: level)));
  }

  Future<List<Question>> _loadFromAsset(String assetPath) async {
    // Load raw JSON string from assets, then decode in a background isolate
    final raw = await rootBundle.loadString(assetPath);
    final List<dynamic> data = await compute(_parseJson, raw);
    return data.map((e) => Question(id: e['id'] as String, text: e['text'] as String, options: List<String>.from(e['options'] as List<dynamic>), correctIndex: e['correctIndex'] as int)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Select Level'), backgroundColor: cs.primary),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                // show modal loading indicator while parsing large asset on background isolate
                showDialog<void>(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                try {
                  final qs = await _loadFromAsset('assets/questions_beginner.json');
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  _start(context, qs, 'easy');
                } catch (e, st) {
                  // close loader if still open
                  if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                  debugPrint('Failed to load beginner questions: $e\n$st');
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load questions: $e')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BCD4), padding: const EdgeInsets.symmetric(vertical: 18)),
              child: const Center(child: Text('Beginner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                showDialog<void>(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                try {
                  final qs = await _loadFromAsset('assets/questions_intermediate.json');
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  _start(context, qs, 'intermediate');
                } catch (e, st) {
                  if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                  debugPrint('Failed to load intermediate questions: $e\n$st');
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load questions: $e')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107), padding: const EdgeInsets.symmetric(vertical: 18), foregroundColor: Colors.black),
              child: const Center(child: Text('Intermediate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                showDialog<void>(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                try {
                  final qs = await _loadFromAsset('assets/questions_expert.json');
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  _start(context, qs, 'expert');
                } catch (e, st) {
                  if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                  debugPrint('Failed to load expert questions: $e\n$st');
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load questions: $e')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF44336), padding: const EdgeInsets.symmetric(vertical: 18)),
              child: const Center(child: Text('Expert', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ),
          ],
        ),
      ),
    );
  }
}
