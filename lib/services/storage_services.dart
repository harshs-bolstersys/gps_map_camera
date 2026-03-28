import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class SharedPrefHelper {
  static final SharedPrefHelper _instance = SharedPrefHelper._internal();
  factory SharedPrefHelper() => _instance;
  SharedPrefHelper._internal();

  static SharedPreferences? _prefs;
  static bool _isInitialized = false;

  /// Initialize SharedPreferences
  static Future<void> init() async {
    if (!_isInitialized) {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      debugPrint('SharedPrefHelper: Initialized successfully');
    }
  }

  /// Ensure SharedPreferences is initialized
  static Future<void> _ensureInitialized() async {
    if (!_isInitialized || _prefs == null) {
      await init();
    }
  }

  /// Save a string value
  static Future<void> setString(String key, String value) async {
    await _ensureInitialized();
    await _prefs?.setString(key, value);
    debugPrint('SharedPrefHelper: setString($key, $value)');
  }

  /// Get a string value
  static Future<String?> getString(String key) async {
    await _ensureInitialized();
    final value = _prefs?.getString(key);
    debugPrint('SharedPrefHelper: getString($key) = $value');
    return value;
  }

  /// Save an integer value
  static Future<void> setInt(String key, int value) async {
    await _prefs?.setInt(key, value);
  }

  /// Get an integer value
  static int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  /// Save a boolean value
  static Future<void> setBool(String key, bool value) async {
    await _ensureInitialized();
    await _prefs?.setBool(key, value);
    debugPrint('SharedPrefHelper: setBool($key, $value)');
  }

  /// Get a boolean value
  static Future<bool?> getBool(String key) async {
    await _ensureInitialized();
    final value = _prefs?.getBool(key);
    debugPrint('SharedPrefHelper: getBool($key) = $value');
    return value;
  }

  /// Save a double value
  static Future<void> setDouble(String key, double value) async {
    await _prefs?.setDouble(key, value);
  }

  /// Get a double value
  static double? getDouble(String key) {
    return _prefs?.getDouble(key);
  }

  /// Save a list of strings
  static Future<void> setStringList(String key, List<String> value) async {
    await _prefs?.setStringList(key, value);
  }

  /// Get a list of strings
  static List<String>? getStringList(String key) {
    return _prefs?.getStringList(key);
  }

  /// Remove a specific key
  static Future<void> remove(String key) async {
    await _ensureInitialized();
    await _prefs?.remove(key);
    debugPrint('SharedPrefHelper: remove($key)');
  }

  /// Clear all preferences
  static Future<void> clear() async {
    await _prefs?.clear();
  }
}
