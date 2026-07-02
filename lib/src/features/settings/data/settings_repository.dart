import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const _keyThemeMode = 'theme_mode';
  static const _keyFontSize = 'font_size';
  static const _keyReadingWidth = 'reading_width';
  static const _keyLineHeight = 'line_height';
  static const _keyLocale = 'locale';
  static const _keyBackendUrl = 'backend_url';
  static const _keyAccessKey = 'access_key';
  static const _keyModelName = 'model_name';

  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  String get themeMode => _prefs.getString(_keyThemeMode) ?? 'system';
  double get fontSize => _prefs.getDouble(_keyFontSize) ?? 18.0;
  double get readingWidth => _prefs.getDouble(_keyReadingWidth) ?? 680.0;
  double get lineHeight => _prefs.getDouble(_keyLineHeight) ?? 1.6;
  String get locale => _prefs.getString(_keyLocale) ?? 'zh';
  String get backendUrl =>
      _prefs.getString(_keyBackendUrl) ?? 'https://api.siliconflow.cn';
  String get accessKey => _prefs.getString(_keyAccessKey) ?? 'sk-cqumxtso5suztny5h5r01ar3g23cbp2phz3tuwkgo6lcjzoh';
  String get modelName => _prefs.getString(_keyModelName) ?? 'deepseek-ai/DeepSeek-V3';

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
  Future<void> setBackendUrl(String value) =>
      _prefs.setString(_keyBackendUrl, value);
  Future<void> setAccessKey(String value) =>
      _prefs.setString(_keyAccessKey, value);
  Future<void> setModelName(String value) =>
      _prefs.setString(_keyModelName, value);
}
