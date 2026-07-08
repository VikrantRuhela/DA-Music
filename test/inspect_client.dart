import 'dart:io';

void main() {
  final file = File(r'C:\Users\vikrantrajput\.gemini\antigravity\scratch\bloom-factory\ytmusic\src\client.rs');
  final code = file.readAsStringSync();

  final index = code.indexOf('fn get_streams_tv');
  if (index != -1) {
    print('\n--- get_streams_tv and following code ---');
    print(code.substring(index, Math.min(code.length, index + 4000)));
  }
}

class Math {
  static int min(int a, int b) => a < b ? a : b;
}
