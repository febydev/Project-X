import 'package:flutter/foundation.dart';

import '../models/log_entry.dart';

/// A lightweight in-memory store for Phase 1.
/// In Phase 2 this gets swapped for on-device persistence (no servers).
class BabyStore extends ChangeNotifier {
  BabyStore._();
  static final BabyStore instance = BabyStore._();

  String babyName = 'your little one';

  final List<LogEntry> _entries = [];

  List<LogEntry> get entries =>
      List.unmodifiable(_entries..sort((a, b) => b.time.compareTo(a.time)));

  /// Entries from today, newest first.
  List<LogEntry> get today {
    final now = DateTime.now();
    return entries
        .where((e) =>
            e.time.year == now.year &&
            e.time.month == now.month &&
            e.time.day == now.day)
        .toList();
  }

  LogEntry? get lastSleep {
    for (final e in entries) {
      if (e.type == LogType.sleep) return e;
    }
    return null;
  }

  LogEntry? lastOf(LogType type) {
    for (final e in entries) {
      if (e.type == type) return e;
    }
    return null;
  }

  void add(LogType type, {String? note, DateTime? time}) {
    _entries.add(LogEntry(type: type, time: time ?? DateTime.now(), note: note));
    notifyListeners();
  }

  void remove(LogEntry entry) {
    _entries.remove(entry);
    notifyListeners();
  }
}
