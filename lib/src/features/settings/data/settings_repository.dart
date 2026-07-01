import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const _keyThemeMode = 'theme_mode';
  static const _keyFontSize = 'font_size';
  static const _keyReadingWidth = 'reading_width';
  static const _keyLineHeight = 'line_height';
  static const _keyLocale = 'locale';
  static const _keyApiBaseUrl = 'api_base_url';
  static const _keyApiKey = 'api_key';
  static const _keyModelName = 'model_name';

  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  String get themeMode => _prefs.getString(_keyThemeMode) ?? 'system';
  double get fontSize => _prefs.getDouble(_keyFontSize) ?? 18.0;
  double get readingWidth => _prefs.getDouble(_keyReadingWidth) ?? 680.0;
  double get lineHeight => _prefs.getDouble(_keyLineHeight) ?? 1.6;
  String get locale => _prefs.getString(_keyLocale) ?? 'zh';
  String get apiBaseUrl =>
      _prefs.getString(_keyApiBaseUrl) ?? 'https://api.openai.com/v1';
  String get apiKey => _prefs.getString(_keyApiKey) ?? '';
  String get modelName => _prefs.getString(_keyModelName) ?? 'longcat';

  Future<void> setThemeMode(String value) =>
      _prefs.setString(_keyThemeMode, value);
  Future<void> setFontSize(double value) =>
      _prefs.setDouble(_keyFontSize, value);
  Future<void> setReadingWidth(double value) =>
      _prefs.setDouble(_keyReadingWidth, value);
  Future<void> setLineHeight(double value) =>
      _prefs.setDouble(_keyLineHeight, value);
  Future<void> setLocale(String value) =>
      _prefs.setString(_keyLocale, value);
  Future<void> setApiBaseUrl(String value) =>
      _prefs.setString(_keyApiBaseUrl, value);
  Future<void> setApiKey(String value) =>
      _prefs.setString(_keyApiKey, value);
  Future<void> setModelName(String value) =>
      _prefs.setString(_keyModelName, value);
}
