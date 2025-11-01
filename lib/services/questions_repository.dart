import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import '../sample_questions.dart';

List<Map<String, dynamic>> _decodeJson(String raw) {
  final v = json.decode(raw);
  if (v is List) return List<Map<String, dynamic>>.from(v);
  return <Map<String, dynamic>>[];
}

/// Simple repository that parses question assets on a background isolate and
/// caches the results so subsequent loads are instant.
class QuestionsRepository {
  QuestionsRepository._();

  static final Map<String, Future<List<Question>>> _cache = {};

  static String _assetForLevel(String level) {
    switch (level) {
      case 'easy':
        return 'assets/questions_beginner.json';
      case 'intermediate':
        return 'assets/questions_intermediate.json';
      case 'expert':
      default:
        return 'assets/questions_expert.json';
    }
  }

  static Future<File> _cacheFileForLevel(String level) async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/questions_cache_$level.json');
  }

  /// Load parsed questions for [level]. Uses cached future if available.
  static Future<List<Question>> load(String level) {
    final key = level;
    if (_cache.containsKey(key)) {
      // Already loading or loaded; return the cached future.
      debugPrint('QuestionsRepository: returning cached future for level=$level');
      return _cache[key]!;
    }

    debugPrint('QuestionsRepository: starting load for level=$level');
    final f = _loadAndParse(_assetForLevel(level));
    // When the future completes, log timing info (best-effort)
    f.then((_) => debugPrint('QuestionsRepository: load complete for level=$level'));
    _cache[key] = f;
    return f;
  }

  /// Start preloading in background (fire-and-forget).
  static void preload(String level) {
    // Kick off the load but intentionally don't await here.
    load(level);
  }

  static Future<List<Question>> _loadAndParse(String assetPath) async {
    final stopwatch = Stopwatch()..start();
    // Try disk cache first
    final level = assetPath.contains('beginner')
        ? 'easy'
        : assetPath.contains('intermediate')
            ? 'intermediate'
            : 'expert';
    try {
      final cacheFile = await _cacheFileForLevel(level);
      if (await cacheFile.exists()) {
        final cached = await cacheFile.readAsString();
        final List<Map<String, dynamic>> list = await compute(_decodeJson, cached);
        stopwatch.stop();
        debugPrint('QuestionsRepository: cache hit for level=$level read+decode=${stopwatch.elapsedMilliseconds}ms');
        return list.map((e) => Question(id: e['id'] as String, text: e['text'] as String, options: List<String>.from(e['options'] as List<dynamic>), correctIndex: e['correctIndex'] as int)).toList();
      }
    } catch (err) {
      debugPrint('QuestionsRepository: cache read failed for level=$level: $err');
      // ignore cache errors and fall back to asset
    }

    // Fallback: load from bundled asset and parse on background isolate
    final raw = await rootBundle.loadString(assetPath);
    final List<Map<String, dynamic>> list = await compute(_decodeJson, raw);
    stopwatch.stop();
    debugPrint('QuestionsRepository: parsed asset for level=$level decode=${stopwatch.elapsedMilliseconds}ms');

    // Persist parsed JSON to disk for faster subsequent cold starts (best-effort)
    try {
      final cacheFile = await _cacheFileForLevel(level);
      await cacheFile.create(recursive: true);
      await cacheFile.writeAsString(jsonEncode(list));
      debugPrint('QuestionsRepository: wrote cache file for level=$level');
    } catch (err) {
      debugPrint('QuestionsRepository: failed to write cache for level=$level: $err');
    }

    return list.map((e) => Question(id: e['id'] as String, text: e['text'] as String, options: List<String>.from(e['options'] as List<dynamic>), correctIndex: e['correctIndex'] as int)).toList();
  }
}
