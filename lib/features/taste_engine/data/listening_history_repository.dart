import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../../core/services/logger_service.dart';

class ListeningHistoryRepository {
  File? _cacheFile;
  List<Map<String, dynamic>>? _inMemoryLogs;

  Future<File> _getCacheFile() async {
    if (_cacheFile != null) return _cacheFile!;
    final docDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docDir.path, 'da_tunes_taste'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cacheFile = File(p.join(dir.path, 'history_logs.json'));
    return _cacheFile!;
  }

  Future<List<Map<String, dynamic>>> loadLogs() async {
    if (_inMemoryLogs != null) {
      return List<Map<String, dynamic>>.from(_inMemoryLogs!);
    }
    try {
      final file = await _getCacheFile();
      if (!await file.exists()) {
        _inMemoryLogs = [];
        return [];
      }
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        _inMemoryLogs = [];
        return [];
      }
      final list = jsonDecode(content);
      if (list is List) {
        _inMemoryLogs = list.map((item) => Map<String, dynamic>.from(item)).toList();
        return List<Map<String, dynamic>>.from(_inMemoryLogs!);
      }
    } catch (e) {
      DALogger.error('ListeningHistoryRepository: Failed to load logs', e);
    }
    _inMemoryLogs = [];
    return [];
  }

  Future<void> appendLog(Map<String, dynamic> log) async {
    try {
      final logs = await loadLogs();
      logs.add(log);
      _inMemoryLogs = logs;
      
      final file = await _getCacheFile();
      final jsonStr = jsonEncode(logs);
      unawaited(file.writeAsString(jsonStr));
    } catch (e) {
      DALogger.error('ListeningHistoryRepository: Failed to append log', e);
    }
  }

  Future<void> clearHistory() async {
    try {
      _inMemoryLogs = [];
      final file = await _getCacheFile();
      if (await file.exists()) {
        await file.writeAsString(jsonEncode([]));
      }
    } catch (e) {
      DALogger.error('ListeningHistoryRepository: Failed to clear history', e);
    }
  }
}
