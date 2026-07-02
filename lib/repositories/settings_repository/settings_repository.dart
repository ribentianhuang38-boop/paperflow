import 'package:shared_preferences/shared_preferences.dart';
import '../../models/settings/settings.dart';

class SettingsRepository {
  static const _keyThemeMode = 'theme_mode';
  static const _keyFontSize = 'font_size';
  static const _keyReadingWidth = 'reading_width';
  static const _keyLineHeight = 'line_height';
  static const _keyLocale = 'locale';
  static const _keyBackendUrl = 'backend_url';
  static const _keyAccessKey = 'access_key';
  static const _keyModelName = 'model_name';

  static const _keyReadingGoalEnabled = 'reading_goal_enabled';
  static const _keyReadingGoalType = 'reading_goal_type';
  static const _keyReadingGoalValue = 'reading_goal_value';

  static const _keyTotalReadingTime = 'total_reading_time';
  static const _keyTodayReadingTime = 'today_reading_time';
  static const _keyTodayReadDate = 'today_read_date';
  static const _keyTodayPapersRead = 'today_papers_read';

  final SharedPreferences _prefs;

  SettingsRepository(this._prefs);

  Settings getSettings() {
    return Settings(
      themeMode: themeMode,
      fontSize: fontSize,
      readingWidth: readingWidth,
      lineHeight: lineHeight,
      locale: locale,
      backendUrl: backendUrl,
      accessKey: accessKey,
      modelName: modelName,
      readingGoalEnabled: readingGoalEnabled,
      readingGoalType: readingGoalType,
      readingGoalValue: readingGoalValue,
    );
  }

  String get themeMode => _prefs.getString(_keyThemeMode) ?? 'system';
  double get fontSize => _prefs.getDouble(_keyFontSize) ?? 18.0;
  double get readingWidth => _prefs.getDouble(_keyReadingWidth) ?? 680.0;
  double get lineHeight => _prefs.getDouble(_keyLineHeight) ?? 1.6;
  String get locale => _prefs.getString(_keyLocale) ?? 'zh';
  String get backendUrl => _prefs.getString(_keyBackendUrl) ?? 'https://api.xiaomimimo.com';
  String get accessKey => _prefs.getString(_keyAccessKey) ?? 'sk-cqumxtso5suztny5h5r01ar3g23cbp2phz3tuwkgo6lcjzoh';
  String get modelName => _prefs.getString(_keyModelName) ?? 'mimo-v2.5';

  bool get readingGoalEnabled => _prefs.getBool(_keyReadingGoalEnabled) ?? false;
  String get readingGoalType => _prefs.getString(_keyReadingGoalType) ?? 'time';
  int get readingGoalValue => _prefs.getInt(_keyReadingGoalValue) ?? 30;

  Future<void> setThemeMode(String value) => _prefs.setString(_keyThemeMode, value);
  Future<void> setFontSize(double value) => _prefs.setDouble(_keyFontSize, value);
  Future<void> setReadingWidth(double value) => _prefs.setDouble(_keyReadingWidth, value);
  Future<void> setLineHeight(double value) => _prefs.setDouble(_keyLineHeight, value);
  Future<void> setLocale(String value) => _prefs.setString(_keyLocale, value);
  Future<void> setBackendUrl(String value) => _prefs.setString(_keyBackendUrl, value);
  Future<void> setAccessKey(String value) => _prefs.setString(_keyAccessKey, value);
  Future<void> setModelName(String value) => _prefs.setString(_keyModelName, value);

  Future<void> setReadingGoalEnabled(bool value) => _prefs.setBool(_keyReadingGoalEnabled, value);
  Future<void> setReadingGoalType(String value) => _prefs.setString(_keyReadingGoalType, value);
  Future<void> setReadingGoalValue(int value) => _prefs.setInt(_keyReadingGoalValue, value);

  // --- Statistics ---
  int get totalReadingTime => _prefs.getInt(_keyTotalReadingTime) ?? 0;

  int get todayReadingTime {
    _checkDailyReset();
    return _prefs.getInt(_keyTodayReadingTime) ?? 0;
  }

  int get todayPapersRead {
    _checkDailyReset();
    return _prefs.getInt(_keyTodayPapersRead) ?? 0;
  }

  Future<void> addReadingTime(int seconds) async {
    _checkDailyReset();
    final total = totalReadingTime + seconds;
    final today = todayReadingTime + seconds;
    await _prefs.setInt(_keyTotalReadingTime, total);
    await _prefs.setInt(_keyTodayReadingTime, today);
  }

  Future<void> incrementTodayPapersRead() async {
    _checkDailyReset();
    final todayPapers = todayPapersRead + 1;
    await _prefs.setInt(_keyTodayPapersRead, todayPapers);
  }

  String _todayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _checkDailyReset() {
    final todayStr = _todayDateString();
    final savedDate = _prefs.getString(_keyTodayReadDate) ?? '';
    if (savedDate != todayStr) {
      _prefs.setString(_keyTodayReadDate, todayStr);
      _prefs.setInt(_keyTodayReadingTime, 0);
      _prefs.setInt(_keyTodayPapersRead, 0);
    }
  }
}
