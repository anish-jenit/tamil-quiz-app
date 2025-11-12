import 'dart:convert';
import 'dart:io';

void main() {
  final pngBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMAASsJTYQAAAAASUVORK5CYII=';
  final outDir = Directory('${Directory.current.path.replaceAll('\\', '/')}/assets/avatars');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);
  final names = List<String>.generate(4, (i) => 'male_${i+1}.png') + List<String>.generate(4, (i) => 'female_${i+1}.png');
  for (final name in names) {
    final file = File('${outDir.path}/$name');
    file.writeAsBytesSync(base64Decode(pngBase64));
  }
}
