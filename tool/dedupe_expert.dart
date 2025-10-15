// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

void main() async {
  final path = 'assets/questions_expert.json';
  final backup = 'assets/questions_expert.json.bak';
  final f = File(path);
  if (!await f.exists()) {
    print('File not found: $path');
    return;
  }
  final raw = await f.readAsString();
  final List<dynamic> data = jsonDecode(raw) as List<dynamic>;
  final seen = <String>{};
  final duplicates = <String, int>{};
  final kept = <dynamic>[];
  for (final item in data) {
    final id = item['id'] as String?;
    if (id == null) continue;
    if (seen.contains(id)) {
      duplicates[id] = (duplicates[id] ?? 1) + 1;
    } else {
      seen.add(id);
      kept.add(item);
    }
  }
  if (duplicates.isEmpty) {
    print('No duplicates found.');
    return;
  }
  print('Found ${duplicates.length} duplicate ids.');
  duplicates.forEach((k, v) => print('$k -> $v occurrences'));
  // backup and write deduped
  await File(backup).writeAsString(raw);
  await f.writeAsString(JsonEncoder.withIndent('  ').convert(kept));
  print('Backup written to $backup and deduplicated file saved.');
}
