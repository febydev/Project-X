import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/baby_profile.dart';
import '../models/chat_message.dart';
import '../models/log_entry.dart';
import '../services/storage_service.dart';

/// Single source of truth for Mira, persisted on-device via shared_preferences.
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  final _storage = StorageService.instance;

  // Keys
  static const _kProfile = 'profile';
  static const _kEntries = 'entries';
  static const _kPremium = 'premium';
  static const _kProxyUrl = 'proxy_url';
  static const _kChat = 'chat_history';
  static const _kAccent = 'accent';
  static const _kMsgCountDate = 'msg_count_date';
  static const _kMsgCount = 'msg_count';

  BabyProfile? _profile;
  final List<LogEntry> _entries = [];
  final List<ChatMessage> _chat = [];
  bool _premium = false;
  String _proxyUrl = AppConfig.defaultProxyUrl;
  int _accent = 0; // index into AppColors.accents

  // ---- Getters ----
  BabyProfile? get profile => _profile;
  bool get hasProfile => _profile != null;
  bool get premium => _premium;
  String get proxyUrl => _proxyUrl;
  int get accent => _accent;
  List<ChatMessage> get chat => List.unmodifiable(_chat);

  List<LogEntry> get entries {
    final list = [..._entries]..sort((a, b) => b.time.compareTo(a.time));
    return List.unmodifiable(list);
  }

  List<LogEntry> get today {
    final now = DateTime.now();
    return entries
        .where((e) =>
            e.time.year == now.year &&
            e.time.month == now.month &&
            e.time.day == now.day)
        .toList();
  }

  LogEntry? lastOf(LogType type) {
    for (final e in entries) {
      if (e.type == type) return e;
    }
    return null;
  }

  String get babyName => _profile?.name ?? 'your little one';

  // ---- Lifecycle ----
  Future<void> load() async {
    await _storage.init();

    final profileRaw = _storage.getString(_kProfile);
    if (profileRaw != null) {
      _profile = BabyProfile.fromJson(
          jsonDecode(profileRaw) as Map<String, dynamic>);
    }

    final entriesRaw = _storage.getString(_kEntries);
    if (entriesRaw != null) {
      final list = jsonDecode(entriesRaw) as List<dynamic>;
      _entries
        ..clear()
        ..addAll(list.map((e) => LogEntry.fromJson(e as Map<String, dynamic>)));
    }

    final chatRaw = _storage.getString(_kChat);
    if (chatRaw != null) {
      final list = jsonDecode(chatRaw) as List<dynamic>;
      _chat
        ..clear()
        ..addAll(
            list.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)));
    }

    _premium = _storage.getBool(_kPremium);
    _proxyUrl = _storage.getString(_kProxyUrl) ?? AppConfig.defaultProxyUrl;
    _accent = _storage.getInt(_kAccent);
    notifyListeners();
  }

  // ---- Profile ----
  Future<void> saveProfile(BabyProfile profile) async {
    _profile = profile;
    await _storage.setString(_kProfile, jsonEncode(profile.toJson()));
    notifyListeners();
  }

  // ---- Logs ----
  Future<void> addLog(LogType type, {String? note, DateTime? time}) async {
    _entries.add(LogEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      time: time ?? DateTime.now(),
      note: note,
    ));
    await _persistEntries();
    notifyListeners();
  }

  Future<void> removeLog(LogEntry entry) async {
    _entries.removeWhere((e) => e.id == entry.id);
    await _persistEntries();
    notifyListeners();
  }

  Future<void> _persistEntries() async {
    await _storage.setString(
        _kEntries, jsonEncode(_entries.map((e) => e.toJson()).toList()));
  }

  // ---- Chat ----
  Future<void> addChatMessage(ChatMessage message) async {
    _chat.add(message);
    await _storage.setString(
        _kChat, jsonEncode(_chat.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  Future<void> clearChat() async {
    _chat.clear();
    await _storage.remove(_kChat);
    notifyListeners();
  }

  // ---- Premium ----
  Future<void> setPremium(bool value) async {
    _premium = value;
    await _storage.setBool(_kPremium, value);
    notifyListeners();
  }

  // ---- Settings ----
  Future<void> setProxyUrl(String url) async {
    _proxyUrl = url.trim();
    await _storage.setString(_kProxyUrl, _proxyUrl);
    notifyListeners();
  }

  Future<void> setAccent(int index) async {
    _accent = index;
    await _storage.setInt(_kAccent, index);
    notifyListeners();
  }

  // ---- Daily message quota (client-side guard; server enforces too) ----
  bool canSendMessage() {
    if (_premium) return true;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final storedDate = _storage.getString(_kMsgCountDate);
    final count = storedDate == today ? _storage.getInt(_kMsgCount) : 0;
    return count < AppConfig.freeDailyMessageLimit;
  }

  Future<void> recordMessageSent() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final storedDate = _storage.getString(_kMsgCountDate);
    final count = storedDate == today ? _storage.getInt(_kMsgCount) : 0;
    await _storage.setString(_kMsgCountDate, today);
    await _storage.setInt(_kMsgCount, count + 1);
  }

  int get remainingFreeMessages {
    if (_premium) return 9999;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final storedDate = _storage.getString(_kMsgCountDate);
    final count = storedDate == today ? _storage.getInt(_kMsgCount) : 0;
    return (AppConfig.freeDailyMessageLimit - count).clamp(0, 9999);
  }
}
