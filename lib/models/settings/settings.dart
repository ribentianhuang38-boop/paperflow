class Settings {
  final String themeMode;
  final double fontSize;
  final double readingWidth;
  final double lineHeight;
  final String locale;
  final String backendUrl;
  final String accessKey;
  final String modelName;
  final bool readingGoalEnabled;
  final String readingGoalType;
  final int readingGoalValue;

  Settings({
    this.themeMode = 'system',
    this.fontSize = 18.0,
    this.readingWidth = 680.0,
    this.lineHeight = 1.6,
    this.locale = 'zh',
    this.backendUrl = 'https://api.xiaomimimo.com',
    this.accessKey = 'sk-cqumxtso5suztny5h5r01ar3g23cbp2phz3tuwkgo6lcjzoh',
    this.modelName = 'mimo-v2.5',
    this.readingGoalEnabled = false,
    this.readingGoalType = 'time',
    this.readingGoalValue = 30,
  });

  Settings copyWith({
    String? themeMode,
    double? fontSize,
    double? readingWidth,
    double? lineHeight,
    String? locale,
    String? backendUrl,
    String? accessKey,
    String? modelName,
    bool? readingGoalEnabled,
    String? readingGoalType,
    int? readingGoalValue,
  }) {
    return Settings(
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      readingWidth: readingWidth ?? this.readingWidth,
      lineHeight: lineHeight ?? this.lineHeight,
      locale: locale ?? this.locale,
      backendUrl: backendUrl ?? this.backendUrl,
      accessKey: accessKey ?? this.accessKey,
      modelName: modelName ?? this.modelName,
      readingGoalEnabled: readingGoalEnabled ?? this.readingGoalEnabled,
      readingGoalType: readingGoalType ?? this.readingGoalType,
      readingGoalValue: readingGoalValue ?? this.readingGoalValue,
    );
  }
}
