import 'dart:collection';

import 'package:flutter/foundation.dart';

enum MindCoachV2LogLevel { info, warn, error }

class MindCoachV2LogEntry {
  MindCoachV2LogEntry({
    required this.timestamp,
    required this.tag,
    required this.level,
    required this.message,
    this.payload,
  });

  final DateTime timestamp;
  final String tag;
  final MindCoachV2LogLevel level;
  final String message;
  final Map<String, dynamic>? payload;

  @override
  String toString() {
    final prefix =
        '[${timestamp.toIso8601String()}] ${level.name.toUpperCase()} [$tag]';
    final payloadStr =
        payload != null && payload!.isNotEmpty ? ' | $payload' : '';
    return '$prefix $message$payloadStr';
  }
}

class MindCoachV2DebugLogger {
  MindCoachV2DebugLogger._();

  static MindCoachV2DebugLogger? _instance;
  static MindCoachV2DebugLogger get instance =>
      _instance ??= MindCoachV2DebugLogger._();

  static const int _maxEntries = 200;
  final Queue<MindCoachV2LogEntry> _entries = Queue<MindCoachV2LogEntry>();

  List<MindCoachV2LogEntry> get entries => _entries.toList();

  void _add(MindCoachV2LogEntry entry) {
    _entries.addLast(entry);
    while (_entries.length > _maxEntries) {
      _entries.removeFirst();
    }
    if (kDebugMode) {
      debugPrint(entry.toString());
    }
  }

  void log(String tag, String message, [Map<String, dynamic>? payload]) {
    _add(MindCoachV2LogEntry(
      timestamp: DateTime.now(),
      tag: tag,
      level: MindCoachV2LogLevel.info,
      message: message,
      payload: payload,
    ));
  }

  void warn(String tag, String message, [Map<String, dynamic>? payload]) {
    _add(MindCoachV2LogEntry(
      timestamp: DateTime.now(),
      tag: tag,
      level: MindCoachV2LogLevel.warn,
      message: message,
      payload: payload,
    ));
  }

  void error(String tag, String message,
      [Map<String, dynamic>? payload, Object? exception, StackTrace? stack]) {
    final enriched = <String, dynamic>{...?payload};
    if (exception != null) {
      enriched['exception'] = exception.toString();
    }
    if (stack != null) {
      enriched['stackTrace'] = stack.toString().split('\n').take(5).join('\n');
    }
    _add(MindCoachV2LogEntry(
      timestamp: DateTime.now(),
      tag: tag,
      level: MindCoachV2LogLevel.error,
      message: message,
      payload: enriched.isNotEmpty ? enriched : null,
    ));
  }

  List<String> dumpLogs() {
    return _entries.map((e) => e.toString()).toList();
  }

  void clear() {
    _entries.clear();
  }
}
