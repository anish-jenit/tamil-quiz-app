import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'sample_questions.dart';
import 'play_solo.dart';

class LevelSelectionPage extends StatelessWidget {
  // mode can be 'solo', 'create_group', 'join_group' to adapt behavior
  final String mode;

  const LevelSelectionPage({super.key, this.mode = 'solo'});

  void _start(BuildContext context, List<Question> questions, String level) {
    // For now, group flows also start the same PlaySoloPage (no real sync implemented)
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlaySoloPage(questions: questions, level: level)));
  }

  Future<List<Question>> _loadFromAsset(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final List<dynamic> data = json.decode(raw);
    return data.map((e) => Question(id: e['id'] as String, text: e['text'] as String, options: List<String>.from(e['options']), correctIndex: e['correctIndex'] as int)).toList();
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
                final qs = await _loadFromAsset('assets/questions_beginner.json');
                if (!context.mounted) return;
                _start(context, qs, 'easy');
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BCD4), padding: const EdgeInsets.symmetric(vertical: 18)),
              child: const Center(child: Text('Beginner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final qs = await _loadFromAsset('assets/questions_intermediate.json');
                if (!context.mounted) return;
                _start(context, qs, 'intermediate');
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFC107), padding: const EdgeInsets.symmetric(vertical: 18), foregroundColor: Colors.black),
              child: const Center(child: Text('Intermediate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final qs = await _loadFromAsset('assets/questions_expert.json');
                if (!context.mounted) return;
                _start(context, qs, 'expert');
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
