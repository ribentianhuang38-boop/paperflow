import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'src/common/providers.dart';
import 'src/features/settings/data/settings_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final settingsRepo = SettingsRepository(prefs);

  runApp(
    ProviderScope(
      overrides: [
        settingsProvider.overrideWithValue(settingsRepo),
      ],
      child: const PaperFlowApp(),
    ),
  );
}
