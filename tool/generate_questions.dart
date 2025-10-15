import 'dart:convert';
import 'dart:io';

void main() {
  generate('beginner', 200);
  generate('intermediate', 200);
  generate('expert', 200);
}

void generate(String level, int count) {
  final List<Map<String, dynamic>> items = [];
  for (var i = 0; i < count; i++) {
    final prefix = level.substring(0, 3);
    final idx = i + 1;
    final idxStr = idx.toString().padLeft(3, '0');
  final id = '${prefix}_$idxStr';
  final label = _levelLabel(level);
  final text = '$label கேள்வி $idx: இது ஒரு மாதிரி தமிழ் கேள்வி?';
    items.add({
      'id': id,
      'text': text,
      'options': ['விருப்பம் A', 'விருப்பம் B', 'விருப்பம் C', 'விருப்பம் D'],
      'correctIndex': i % 4,
    });
  }
  final file = File('assets/questions_$level.json');
  file.createSync(recursive: true);
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(items));
  // Use stdout to avoid linter's avoid_print warning in tools
  stdout.writeln('Wrote ${file.path} ($count items)');
}

String _levelLabel(String level) {
  switch (level) {
    case 'beginner': return 'அரம்ப நிலை';
    case 'intermediate': return 'நடுத்தர நிலை';
    case 'expert': return 'மேம்பட்ட நிலை';
    default: return 'நிலை';
  }
}
