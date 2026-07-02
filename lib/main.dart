import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'src/common/providers.dart';
import 'src/features/settings/data/settings_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  // Auto-migrate old default backend configuration to official MiMo API defaults
  final currentUrl = prefs.getString('backend_url');
  final currentKey = prefs.getString('access_key');
  final currentModel = prefs.getString('model_name');
  if (currentUrl == null || 
      currentUrl == 'https://backend-swart-three-sgl5999uxy.vercel.app/api' || 
      currentUrl == 'https://api.siliconflow.cn') {
    await prefs.setString('backend_url', 'https://api.xiaomimimo.com');
  }
  if (currentKey == null || currentKey == 'paperflow-s3cr3t-2026') {
    await prefs.setString('access_key', 'sk-cqumxtso5suztny5h5r01ar3g23cbp2phz3tuwkgo6lcjzoh');
  }
  if (currentModel == null || 
      currentModel == 'deepseek-ai/DeepSeek-V3' || 
      currentModel == 'mimo-v2.5') {
    await prefs.setString('model_name', 'mimo-v2.5');
  }

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
