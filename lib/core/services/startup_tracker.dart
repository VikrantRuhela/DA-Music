// SPDX-License-Identifier: GPL-3.0-only
// Copyright (c) 2026 DA Tunes Contributors
// Licensed under GPL-3.0.

import 'dart:async';
import 'logger_service.dart';

class StartupStepRecord {
  final String name;
  final DateTime startTime;
  DateTime? endTime;
  bool isSuccess;
  String? error;

  StartupStepRecord({
    required this.name,
    required this.startTime,
    this.endTime,
    this.isSuccess = false,
    this.error,
  });

  int get durationMs => endTime != null ? endTime!.difference(startTime).inMilliseconds : 0;
}

class StartupTracker {
  static final List<StartupStepRecord> _records = [];
  static final DateTime _overallStartTime = DateTime.now();

  static Timer? _stallDetectorTimer;
  static DateTime _lastTickTime = DateTime.now();
  static final List<String> _stalls = [];

  static void startStallDetector() {
    _lastTickTime = DateTime.now();
    _stalls.clear();
    _stallDetectorTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      final now = DateTime.now();
      final elapsed = now.difference(_lastTickTime).inMilliseconds;
      if (elapsed > 150) {
        final stallMsg = 'Main thread stall detected: ${elapsed}ms delay (expected 50ms)';
        _stalls.add('[$now] $stallMsg');
        DALogger.warning('[STARTUP PROFILE] ⚠ $stallMsg');
      }
      _lastTickTime = now;
    });
  }

  static void stopStallDetector() {
    _stallDetectorTimer?.cancel();
    _stallDetectorTimer = null;
  }

  static StartupStepRecord startStep(String name) {
    final record = StartupStepRecord(name: name, startTime: DateTime.now());
    _records.add(record);
    DALogger.info('[STARTUP DIAGNOSTICS] ▶ Starting step "$name"...');
    return record;
  }

  static void endStep(StartupStepRecord record, {bool success = true, String? error}) {
    record.endTime = DateTime.now();
    record.isSuccess = success;
    record.error = error;
    if (success) {
      DALogger.info('[STARTUP DIAGNOSTICS] ✔ Completed step "${record.name}" in ${record.durationMs}ms');
    } else {
      DALogger.error('[STARTUP DIAGNOSTICS] ✖ Step "${record.name}" failed after ${record.durationMs}ms: ${error ?? 'Unknown error'}');
    }
  }

  static Future<T> runStep<T>(String name, Future<T> Function() action) async {
    final record = startStep(name);
    try {
      final result = await action();
      endStep(record, success: true);
      return result;
    } catch (e) {
      endStep(record, success: false, error: e.toString());
      rethrow;
    }
  }

  static void printSummary() {
    final totalDurationMs = DateTime.now().difference(_overallStartTime).inMilliseconds;
    final buffer = StringBuffer();
    buffer.writeln('=== DA TUNES STARTUP TIMING DIAGNOSTICS ===');
    buffer.writeln('Total Startup Time: ${totalDurationMs}ms');
    for (int i = 0; i < _records.length; i++) {
      final r = _records[i];
      final statusStr = r.isSuccess ? 'SUCCESS' : 'FAILED (${r.error})';
      buffer.writeln('${i + 1}. ${r.name.padRight(40)} : ${r.durationMs}ms [$statusStr]');
    }
    if (_stalls.isNotEmpty) {
      buffer.writeln('\n=== MAIN THREAD STALLS DETECTED ===');
      for (final stall in _stalls) {
        buffer.writeln(stall);
      }
    } else {
      buffer.writeln('\nNo major main thread stalls detected.');
    }
    buffer.writeln('===========================================');
    DALogger.info(buffer.toString());
  }

  static List<StartupStepRecord> get records => List.unmodifiable(_records);
}
