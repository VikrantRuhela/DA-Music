import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../../core/services/logger_service.dart';

class ListeningHistoryRepository {
  File? _cacheFile;

  Future<File> _getCacheFile() async {
    if (_cacheFile != null) return _cacheFile!;
    final docDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docDir.path, 'da_music_taste'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    _cacheFile = File(p.join(dir.path, 'history_logs.json'));
    return _cacheFile!;
  }

  Future<List<Map<String, dynamic>>> loadLogs() async {
    try {
      final file = await _getCacheFile();
      if (!file.existsSync()) return [];
      final content = await file.readAsString();
      if (content.trim().isEmpty) return [];
      final list = jsonDecode(content);
      if (list is List) {
        return list.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      DALogger.error('ListeningHistoryRepository: Failed to load logs', e);
    }
    return [];
  }

  Future<void> appendLog(Map<String, dynamic> log) async {
    try {
      final file = await _getCacheFile();
      final logs = await loadLogs();
      logs.add(log);
      await file.writeAsString(jsonEncode(logs));
    } catch (e) {
      DALogger.error('ListeningHistoryRepository: Failed to append log', e);
    }
  }

  Future<void> clearHistory() async {
    try {
      final file = await _getCacheFile();
      if (file.existsSync()) {
        await file.writeAsString(jsonEncode([]));
      }
    } catch (e) {
      DALogger.error('ListeningHistoryRepository: Failed to clear history', e);
    }
  }
}
