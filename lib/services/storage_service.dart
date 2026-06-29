import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper over shared_preferences. All of Mira's data lives on-device.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  String? getString(String key) => _prefs?.getString(key);
  bool getBool(String key, {bool fallback = false}) =>
      _prefs?.getBool(key) ?? fallback;
  int getInt(String key, {int fallback = 0}) => _prefs?.getInt(key) ?? fallback;

  Future<void> setString(String key, String value) async =>
      _prefs?.setString(key, value);
  Future<void> setBool(String key, bool value) async =>
      _prefs?.setBool(key, value);
  Future<void> setInt(String key, int value) async =>
      _prefs?.setInt(key, value);
  Future<void> remove(String key) async => _prefs?.remove(key);
}
