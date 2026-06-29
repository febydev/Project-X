import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/baby_profile.dart';
import '../models/chat_message.dart';
import '../models/log_entry.dart';
import '../models/mom_anim.dart';
import '../models/mom_checkin.dart';
import '../services/storage_service.dart';

/// Single source of truth for Mira, persisted on-device via shared_preferences.
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  final _storage = StorageService.instance;

  /// Drives the animated mom character. UI listens to this.
  final ValueNotifier<MomAnim> character = ValueNotifier(MomAnim.idle);

  // Keys
  static const _kProfile = 'profile';
  static const _kEntries = 'entries';
  static const _kPremium = 'premium';
  static const _kProxyUrl = 'proxy_url';
  static const _kChat = 'chat_history';
  static const _kAccent = 'accent';
  static const _kMsgCountDate = 'msg_count_date';
  static const _kMsgCount = 'msg_count';
  static const _kAiConsent = 'ai_consent';
  static const _kCheckins = 'mom_checkins';
  static const _kFirstBaby = 'first_baby';
  static const _kUsedBy = 'used_by';
  static const _kWorry = 'biggest_worry';
  static const _kNapSchedule = 'nap_schedule';
  static const _kActivityDate = 'activity_date';
  static const _kActivityText = 'activity_text';
  static const _kActivityDone = 'activity_done';
  static const _kPartnerName = 'partner_name';
  static const _kPartnerCode = 'partner_code';

  BabyProfile? _profile;
  final List<LogEntry> _entries = [];
  final List<ChatMessage> _chat = [];
  final List<MomCheckin> _checkins = [];
  bool _premium = false;
  String _proxyUrl = AppConfig.defaultProxyUrl;
  int _accent = 0;
  bool _aiConsent = false;
  bool? _firstBaby;
  String? _usedBy;
  String? _worry;
  int _napSchedule = 0; // 0 = auto
  String? _activityText;
  String _activityDate = '';
  bool _activityDone = false;
  String? _partnerName;
  String? _partnerCode;

  // ---- Getters ----
  BabyProfile? get profile => _profile;
  bool get hasProfile => _profile != null;
  bool get premium => _premium;
  String get proxyUrl => _proxyUrl;
  int get accent => _accent;
  bool get aiConsent => _aiConsent;
  bool? get firstBaby => _firstBaby;
  String? get usedBy => _usedBy;
  String? get worry => _worry;
  int get napSchedule => _napSchedule;
  String? get activityText => _activityText;
  bool get activityDone => _activityDone;
  String? get partnerName => _partnerName;
  String? get partnerCode => _partnerCode;
  List<ChatMessage> get chat => List.unmodifiable(_chat);
  List<MomCheckin> get checkins => List.unmodifiable(_checkins);

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

  /// A currently-running (open) sleep, if any.
  LogEntry? get runningSleep {
    for (final e in _entries) {
      if (e.type == LogType.sleep && e.endTime == null) return e;
    }
    return null;
  }

  String get babyName => _profile?.name ?? 'your little one';
  int get ageMonths => _profile?.ageInMonths ?? 0;

  void emitCharacter(MomAnim a) {
    character.value = a;
  }

  String get _todayKey {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  // ---- Lifecycle ----
  Future<void> load() async {
    await _storage.init();

    final profileRaw = _storage.getString(_kProfile);
    if (profileRaw != null) {
      _profile =
          BabyProfile.fromJson(jsonDecode(profileRaw) as Map<String, dynamic>);
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

    final ciRaw = _storage.getString(_kCheckins);
    if (ciRaw != null) {
      final list = jsonDecode(ciRaw) as List<dynamic>;
      _checkins
        ..clear()
        ..addAll(
            list.map((e) => MomCheckin.fromJson(e as Map<String, dynamic>)));
    }

    _premium = _storage.getBool(_kPremium);
    _proxyUrl = _storage.getString(_kProxyUrl) ?? AppConfig.defaultProxyUrl;
    _accent = _storage.getInt(_kAccent);
    _aiConsent = _storage.getBool(_kAiConsent);
    final fb = _storage.getString(_kFirstBaby);
    _firstBaby = fb == null ? null : fb == 'true';
    _usedBy = _storage.getString(_kUsedBy);
    _worry = _storage.getString(_kWorry);
    _napSchedule = _storage.getInt(_kNapSchedule);
    _activityText = _storage.getString(_kActivityText);
    _activityDate = _storage.getString(_kActivityDate) ?? '';
    _activityDone = _storage.getBool(_kActivityDone);
    _partnerName = _storage.getString(_kPartnerName);
    _partnerCode = _storage.getString(_kPartnerCode);
    notifyListeners();
  }

  // ---- Profile / onboarding ----
  Future<void> saveProfile(BabyProfile profile) async {
    _profile = profile;
    await _storage.setString(_kProfile, jsonEncode(profile.toJson()));
    notifyListeners();
  }

  Future<void> saveOnboardingExtras({
    bool? firstBaby,
    String? usedBy,
    String? worry,
  }) async {
    if (firstBaby != null) {
      _firstBaby = firstBaby;
      await _storage.setString(_kFirstBaby, firstBaby.toString());
    }
    if (usedBy != null) {
      _usedBy = usedBy;
      await _storage.setString(_kUsedBy, usedBy);
    }
    if (worry != null) {
      _worry = worry;
      await _storage.setString(_kWorry, worry);
    }
    notifyListeners();
  }

  // ---- Logs ----
  Future<void> _persistEntries() async {
    await _storage.setString(
        _kEntries, jsonEncode(_entries.map((e) => e.toJson()).toList()));
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> addLog(LogType type,
      {String? note, DateTime? time, Map<String, dynamic>? details}) async {
    _entries.add(LogEntry(
      id: _newId(),
      type: type,
      time: time ?? DateTime.now(),
      note: note,
      details: details,
    ));
    await _persistEntries();
    notifyListeners();
  }

  Future<void> addFeed({Map<String, dynamic>? details}) async {
    await addLog(LogType.feed, details: details);
    emitCharacter(MomAnim.celebrate);
  }

  Future<void> addDiaper(String kind) async {
    await addLog(LogType.diaper, details: {'kind': kind});
    emitCharacter(MomAnim.diaper);
  }

  Future<void> addGrowth(
      {double? weightKg, double? heightCm}) async {
    await addLog(LogType.growth,
        details: {'weightKg': weightKg, 'heightCm': heightCm});
    emitCharacter(MomAnim.celebrate);
  }

  /// Start a sleep timer (open-ended sleep entry).
  Future<void> startSleep({DateTime? time}) async {
    if (runningSleep != null) return;
    _entries.add(LogEntry(
        id: _newId(), type: LogType.sleep, time: time ?? DateTime.now()));
    await _persistEntries();
    emitCharacter(MomAnim.shhh);
    notifyListeners();
  }

  /// Stop the running sleep timer.
  Future<void> stopSleep(
      {DateTime? endTime, Map<String, dynamic>? details}) async {
    final s = runningSleep;
    if (s == null) return;
    s.endTime = endTime ?? DateTime.now();
    if (details != null) s.details.addAll(details);
    await _persistEntries();
    emitCharacter(MomAnim.wake);
    notifyListeners();
  }

  /// Add a completed sleep with explicit start/end.
  Future<void> addSleep(DateTime start, DateTime end,
      {Map<String, dynamic>? details}) async {
    _entries.add(LogEntry(
        id: _newId(),
        type: LogType.sleep,
        time: start,
        endTime: end,
        details: details));
    await _persistEntries();
    notifyListeners();
  }

  Future<void> removeLog(LogEntry entry) async {
    _entries.removeWhere((e) => e.id == entry.id);
    await _persistEntries();
    notifyListeners();
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

  // ---- Mom check-in ----
  bool get hasCheckedInToday =>
      _checkins.any((c) => c.date == _todayKey);

  Future<void> addCheckin(int sleep, int mood, int body) async {
    _checkins.removeWhere((c) => c.date == _todayKey);
    _checkins.add(
        MomCheckin(date: _todayKey, sleep: sleep, mood: mood, body: body));
    await _storage.setString(
        _kCheckins, jsonEncode(_checkins.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  /// Consecutive recent days (incl. today) with a low score (< 3).
  int get lowStreak {
    final sorted = [..._checkins]..sort((a, b) => b.date.compareTo(a.date));
    var streak = 0;
    for (final c in sorted) {
      if (c.score < 3.0) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // ---- Daily activity ----
  bool get needsNewActivity => _activityDate != _todayKey;

  Future<void> setActivity(String text) async {
    _activityText = text;
    _activityDate = _todayKey;
    _activityDone = false;
    await _storage.setString(_kActivityText, text);
    await _storage.setString(_kActivityDate, _todayKey);
    await _storage.setBool(_kActivityDone, false);
    notifyListeners();
  }

  Future<void> markActivityDone() async {
    _activityDone = true;
    await _storage.setBool(_kActivityDone, true);
    emitCharacter(MomAnim.dance);
    notifyListeners();
  }

  // ---- Premium / settings ----
  Future<void> setPremium(bool value) async {
    _premium = value;
    await _storage.setBool(_kPremium, value);
    notifyListeners();
  }

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

  Future<void> setAiConsent(bool value) async {
    _aiConsent = value;
    await _storage.setBool(_kAiConsent, value);
    notifyListeners();
  }

  Future<void> setNapSchedule(int naps) async {
    _napSchedule = naps;
    await _storage.setInt(_kNapSchedule, naps);
    notifyListeners();
  }

  Future<void> setPartner(String name, String code) async {
    _partnerName = name;
    _partnerCode = code;
    await _storage.setString(_kPartnerName, name);
    await _storage.setString(_kPartnerCode, code);
    notifyListeners();
  }

  // ---- AI context + quota ----
  String buildAiContext() {
    final now = DateTime.now();
    final last24 =
        entries.where((e) => now.difference(e.time) <= const Duration(hours: 24));

    String agoOf(LogType t) {
      final e = lastOf(t);
      if (e == null) return 'none logged';
      final d = now.difference(e.time);
      if (d.inMinutes < 60) return '${d.inMinutes}m ago';
      final h = d.inHours, m = d.inMinutes % 60;
      return m == 0 ? '${h}h ago' : '${h}h ${m}m ago';
    }

    int countToday(LogType t) => today.where((e) => e.type == t).length;
    int count24(LogType t) => last24.where((e) => e.type == t).length;

    if (entries.isEmpty) return 'No activity logged yet.';

    final extras = <String>[];
    if (_worry != null) extras.add('Parent\u2019s main concern: $_worry.');
    if (_firstBaby == true) extras.add('First-time parent.');

    return [
      'Today so far: ${countToday(LogType.feed)} feeds, '
          '${countToday(LogType.sleep)} sleeps, '
          '${countToday(LogType.diaper)} diaper changes.',
      'Last feed: ${agoOf(LogType.feed)}. Last sleep: ${agoOf(LogType.sleep)}. '
          'Last diaper: ${agoOf(LogType.diaper)}.',
      'Last 24h: ${count24(LogType.feed)} feeds, ${count24(LogType.sleep)} sleeps, '
          '${count24(LogType.diaper)} diapers.',
      ...extras,
    ].join(' ');
  }

  bool canSendMessage() {
    if (_premium) return true;
    final storedDate = _storage.getString(_kMsgCountDate);
    final count = storedDate == _todayKey ? _storage.getInt(_kMsgCount) : 0;
    return count < AppConfig.freeDailyMessageLimit;
  }

  Future<void> recordMessageSent() async {
    final storedDate = _storage.getString(_kMsgCountDate);
    final count = storedDate == _todayKey ? _storage.getInt(_kMsgCount) : 0;
    await _storage.setString(_kMsgCountDate, _todayKey);
    await _storage.setInt(_kMsgCount, count + 1);
  }

  int get remainingFreeMessages {
    if (_premium) return 9999;
    final storedDate = _storage.getString(_kMsgCountDate);
    final count = storedDate == _todayKey ? _storage.getInt(_kMsgCount) : 0;
    return (AppConfig.freeDailyMessageLimit - count).clamp(0, 9999);
  }
}
