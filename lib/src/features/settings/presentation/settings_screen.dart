import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperflow/src/common/providers.dart';

import '../../../common/ai/ai_client.dart';
import '../data/settings_repository.dart';
import '../../library/presentation/library_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _backendUrlController;
  late TextEditingController _accessKeyController;
  late TextEditingController _modelController;
  late TextEditingController _fontSizeController;
  late TextEditingController _readingWidthController;
  late TextEditingController _lineHeightController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _backendUrlController = TextEditingController(text: settings.backendUrl);
    _accessKeyController = TextEditingController(text: settings.accessKey);
    _modelController = TextEditingController(text: settings.modelName);
    _fontSizeController =
        TextEditingController(text: settings.fontSize.toString());
    _readingWidthController =
        TextEditingController(text: settings.readingWidth.toString());
    _lineHeightController =
        TextEditingController(text: settings.lineHeight.toString());
  }

  @override
  void dispose() {
    _backendUrlController.dispose();
    _accessKeyController.dispose();
    _modelController.dispose();
    _fontSizeController.dispose();
    _readingWidthController.dispose();
    _lineHeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Appearance'),
          _buildThemeTile(context, settings),
          _buildFontSizeTile(context, settings),
          _buildReadingWidthTile(context, settings),
          _buildLineHeightTile(context, settings),
          const Divider(height: 32),
          _buildSectionHeader(context, 'Language'),
          _buildLanguageTile(context, settings),
          const Divider(height: 32),
          _buildSectionHeader(context, 'AI Model'),
          _buildApiUrlTile(context, settings),
          _buildApiKeyTile(context, settings),
          _buildModelTile(context, settings),
          _buildTestConnectionTile(context),
          const Divider(height: 32),
          _buildSectionHeader(context, 'Data'),
          _buildExportVocabularyTile(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildThemeTile(BuildContext context, SettingsRepository settings) {
    return ListTile(
      leading: const Icon(Icons.brightness_6),
      title: const Text('Theme'),
      subtitle: Text(_themeName(settings.themeMode)),
      onTap: () => _showThemePicker(context, settings),
    );
  }

  String _themeName(String mode) {
    switch (mode) {
      case 'dark':
        return 'Dark Mode';
      case 'light':
        return 'Light Mode';
      default:
        return 'System Default';
    }
  }

  void _showThemePicker(BuildContext context, SettingsRepository settings) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone_android),
              title: const Text('System Default'),
              trailing: settings.themeMode == 'system'
                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                settings.setThemeMode('system');
                ref.invalidate(settingsProvider);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Light Mode'),
              trailing: settings.themeMode == 'light'
                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                settings.setThemeMode('light');
                ref.invalidate(settingsProvider);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Dark Mode'),
              trailing: settings.themeMode == 'dark'
                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                settings.setThemeMode('dark');
                ref.invalidate(settingsProvider);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSizeTile(
      BuildContext context, SettingsRepository settings) {
    return ListTile(
      leading: const Icon(Icons.text_fields),
      title: const Text('Font Size'),
      subtitle: Text('${settings.fontSize.round()}px'),
      trailing: SizedBox(
        width: 200,
        child: Slider(
          value: settings.fontSize,
          min: 12,
          max: 28,
          divisions: 16,
          label: '${settings.fontSize.round()}px',
          onChanged: (value) {
            settings.setFontSize(value);
            ref.invalidate(settingsProvider);
          },
        ),
      ),
    );
  }

  Widget _buildReadingWidthTile(
      BuildContext context, SettingsRepository settings) {
    return ListTile(
      leading: const Icon(Icons.width_normal),
      title: const Text('Reading Width'),
      subtitle: Text('${settings.readingWidth.round()}px'),
      trailing: SizedBox(
        width: 200,
        child: Slider(
          value: settings.readingWidth,
          min: 400,
          max: 900,
          divisions: 10,
          label: '${settings.readingWidth.round()}px',
          onChanged: (value) {
            settings.setReadingWidth(value);
            ref.invalidate(settingsProvider);
          },
        ),
      ),
    );
  }

  Widget _buildLineHeightTile(
      BuildContext context, SettingsRepository settings) {
    return ListTile(
      leading: const Icon(Icons.format_line_spacing),
      title: const Text('Line Height'),
      subtitle: Text(settings.lineHeight.toStringAsFixed(1)),
      trailing: SizedBox(
        width: 200,
        child: Slider(
          value: settings.lineHeight,
          min: 1.0,
          max: 2.5,
          divisions: 15,
          label: settings.lineHeight.toStringAsFixed(1),
          onChanged: (value) {
            settings.setLineHeight(value);
            ref.invalidate(settingsProvider);
          },
        ),
      ),
    );
  }

  Widget _buildLanguageTile(
      BuildContext context, SettingsRepository settings) {
    return ListTile(
      leading: const Icon(Icons.language),
      title: const Text('Language'),
      subtitle: Text(settings.locale == 'zh' ? '中文' : 'English'),
      onTap: () => _showLanguagePicker(context, settings),
    );
  }

  void _showLanguagePicker(
      BuildContext context, SettingsRepository settings) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇨🇳', style: TextStyle(fontSize: 24)),
              title: const Text('中文'),
              trailing: settings.locale == 'zh'
                  ? Icon(Icons.check,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                settings.setLocale('zh');
                ref.invalidate(settingsProvider);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: const Text('English'),
              trailing: settings.locale == 'en'
                  ? Icon(Icons.check,
                      color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                settings.setLocale('en');
                ref.invalidate(settingsProvider);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiUrlTile(
      BuildContext context, SettingsRepository settings) {
    return ListTile(
      leading: const Icon(Icons.link),
      title: const Text('Backend URL'),
      subtitle: Text(settings.backendUrl),
      onTap: () => _showTextDialog(
        context,
        'Backend URL',
        _backendUrlController,
        (value) {
          settings.setBackendUrl(value);
          ref.invalidate(settingsProvider);
        },
      ),
    );
  }

  Widget _buildApiKeyTile(
      BuildContext context, SettingsRepository settings) {
    return ListTile(
      leading: const Icon(Icons.key),
      title: const Text('Access Key'),
      subtitle: Text(
        settings.accessKey.isEmpty
            ? 'Not set'
            : '${settings.accessKey.substring(0, 8)}...',
      ),
      onTap: () => _showTextDialog(
        context,
        'Access Key',
        _accessKeyController,
        (value) {
          settings.setAccessKey(value);
          ref.invalidate(settingsProvider);
        },
        obscure: true,
      ),
    );
  }

  Widget _buildModelTile(
      BuildContext context, SettingsRepository settings) {
    return ListTile(
      leading: const Icon(Icons.smart_toy),
      title: const Text('Model Name'),
      subtitle: Text(settings.modelName),
      onTap: () => _showTextDialog(
        context,
        'Model Name',
        _modelController,
        (value) {
          settings.setModelName(value);
          ref.invalidate(settingsProvider);
        },
      ),
    );
  }

  Widget _buildTestConnectionTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.wifi_tethering),
      title: const Text('Test Connection'),
      onTap: () => _testConnection(context),
    );
  }

  Widget _buildExportVocabularyTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.copy),
      title: const Text('Export Vocabulary'),
      subtitle: const Text('Copy all words to clipboard'),
      onTap: () {
        // Handled in vocabulary list screen
      },
    );
  }

  Future<void> _showTextDialog(
    BuildContext context,
    String title,
    TextEditingController controller,
    ValueChanged<String> onSave, {
    bool obscure = false,
  }) async {
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: controller.text.length),
    );

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: title,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _testConnection(BuildContext context) async {
    final aiClient = ref.read(aiClientProvider);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final response = await aiClient.chat([
        {'role': 'user', 'content': 'Say "OK" if you can hear me.'},
      ]);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection successful: ${response.substring(0, 50)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
