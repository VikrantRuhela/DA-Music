import 'dart:io';

void main() {
  final file = File('lib/core/services/youtube_music_adapter.dart');
  final lines = file.readAsLinesSync();
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].contains('class InterceptingClient')) {
      print('Found InterceptingClient at line ${i + 1}:');
      for (int j = i; j < i + 35 && j < lines.length; j++) {
        print('${j + 1}: ${lines[j]}');
      }
      break;
    }
  }
}
