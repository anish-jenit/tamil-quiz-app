import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('leaderboard stores entries per level separately', () async {
    // Use mock SharedPreferences for tests
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    const keyEasy = 'leaderboard_easy';
    const keyExpert = 'leaderboard_expert';

    final entryEasy = {
      'playerId': 'p_easy',
      'name': 'Alice',
      'score': 10,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final entryExpert = {
      'playerId': 'p_expert',
      'name': 'Bob',
      'score': 15,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await prefs.setStringList(keyEasy, [jsonEncode(entryEasy)]);
    await prefs.setStringList(keyExpert, [jsonEncode(entryExpert)]);

    final rawEasy = prefs.getStringList(keyEasy) ?? <String>[];
    final rawExpert = prefs.getStringList(keyExpert) ?? <String>[];

    expect(rawEasy.length, 1);
    expect(rawExpert.length, 1);

    final me = jsonDecode(rawEasy.first) as Map<String, dynamic>;
    final mx = jsonDecode(rawExpert.first) as Map<String, dynamic>;

    expect(me['name'], 'Alice');
    expect(mx['name'], 'Bob');
    expect(me['score'], 10);
    expect(mx['score'], 15);
  });
}
