import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:paperflow/src/common/providers.dart';
import '../../../common/theme/colors.dart';
import '../../../common/theme/typography.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _backendUrlController;
  late TextEditingController _accessKeyController;
  late TextEditingController _modelController;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _backendUrlController = TextEditingController(text: s.backendUrl);
    _accessKeyController = TextEditingController(text: s.accessKey);
    _modelController = TextEditingController(text: s.modelName);
  }

  @override
  void dispose() {
    _backendUrlController.dispose();
    _accessKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text('Settings', style: AppTypography.title2.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        )),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        children: [
          _SectionHeader(label: 'Appearance', isDark: isDark),
          _SettingTile(
            icon: Icons.brightness_6,
            label: 'Theme',
            value: _themeName(settings.themeMode),
            isDark: isDark,
            onTap: () => _pickTheme(settings),
          ),
          _SettingSlider(
            icon: Icons.text_fields,
            label: 'Font Size',
            value: settings.fontSize,
            min: 12, max: 28, divisions: 16,
            suffix: 'px',
            isDark: isDark,
            onChanged: (v) { settings.setFontSize(v); ref.invalidate(settingsProvider); },
          ),
          _SettingSlider(
            icon: Icons.width_normal,
            label: 'Reading Width',
            value: settings.readingWidth,
            min: 400, max: 900, divisions: 10,
            suffix: 'px',
            isDark: isDark,
            onChanged: (v) { settings.setReadingWidth(v); ref.invalidate(settingsProvider); },
          ),
          _SettingSlider(
            icon: Icons.format_line_spacing,
            label: 'Line Height',
            value: settings.lineHeight,
            min: 1.0, max: 2.5, divisions: 15,
            suffix: '',
            isDark: isDark,
            onChanged: (v) { settings.setLineHeight(v); ref.invalidate(settingsProvider); },
          ),
          const SizedBox(height: 24),
          _SectionHeader(label: 'Language', isDark: isDark),
          _SettingTile(
            icon: Icons.language,
            label: 'Language',
            value: settings.locale == 'zh' ? '中文' : 'English',
            isDark: isDark,
            onTap: () => _pickLocale(settings),
          ),
          const SizedBox(height: 24),
          _SectionHeader(label: 'AI Model', isDark: isDark),
          _SettingTile(
            icon: Icons.link,
            label: 'Backend URL',
            value: settings.backendUrl,
            isDark: isDark,
            onTap: () => _editField('Backend URL', _backendUrlController, (v) {
              settings.setBackendUrl(v); ref.invalidate(settingsProvider);
            }),
          ),
          _SettingTile(
            icon: Icons.key,
            label: 'Access Key',
            value: settings.accessKey.isEmpty ? 'Not set' : '••••••••',
            isDark: isDark,
            onTap: () => _editField('Access Key', _accessKeyController, (v) {
              settings.setAccessKey(v); ref.invalidate(settingsProvider);
            }),
          ),
          _SettingTile(
            icon: Icons.smart_toy,
            label: 'Model',
            value: settings.modelName,
            isDark: isDark,
            onTap: () => _editField('Model Name', _modelController, (v) {
              settings.setModelName(v); ref.invalidate(settingsProvider);
            }),
          ),
          _SettingTile(
            icon: Icons.wifi_tethering,
            label: 'Test Connection',
            value: '',
            isDark: isDark,
            onTap: () => _testConnection(),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _themeName(String m) => m == 'dark' ? 'Dark' : m == 'light' ? 'Light' : 'System';

  void _pickTheme(dynamic settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final entry in {'system': 'System', 'light': 'Light', 'dark': 'Dark'}.entries)
            ListTile(
              title: Text(entry.value, style: AppTypography.bodySans),
              trailing: settings.themeMode == entry.key
                  ? const Icon(Icons.check, color: AppColors.accent) : null,
              onTap: () { settings.setThemeMode(entry.key); ref.invalidate(settingsProvider); Navigator.pop(ctx); },
            ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  void _pickLocale(dynamic settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            title: Text('中文', style: AppTypography.bodySans),
            trailing: settings.locale == 'zh' ? const Icon(Icons.check, color: AppColors.accent) : null,
            onTap: () { settings.setLocale('zh'); ref.invalidate(settingsProvider); Navigator.pop(ctx); },
          ),
          ListTile(
            title: Text('English', style: AppTypography.bodySans),
            trailing: settings.locale == 'en' ? const Icon(Icons.check, color: AppColors.accent) : null,
            onTap: () { settings.setLocale('en'); ref.invalidate(settingsProvider); Navigator.pop(ctx); },
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  void _editField(String label, TextEditingController ctrl, ValueChanged<String> onSave) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(label, style: AppTypography.title3),
        content: TextField(controller: ctrl, autofocus: true, decoration: InputDecoration(hintText: label)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () { onSave(ctrl.text); Navigator.pop(ctx); }, child: const Text('Save')),
        ],
      ),
    );
  }

  Future<void> _testConnection() async {
    final aiClient = ref.read(aiClientProvider);
    showDialog(context: context, barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()));
    try {
      final ok = await aiClient.testConnection();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'Connected!' : 'Failed'),
          backgroundColor: ok ? AppColors.success : AppColors.error,
        ));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(label.toUpperCase(), style: AppTypography.caption2.copyWith(
        color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
      )),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: AppTypography.bodySans.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ))),
            if (value.isNotEmpty)
              Flexible(
                child: Text(value, textAlign: TextAlign.end,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: AppTypography.subheadline.copyWith(
                      color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                    )),
              ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18,
                color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _SettingSlider extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String suffix;
  final bool isDark;
  final ValueChanged<double> onChanged;

  const _SettingSlider({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.suffix,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              const SizedBox(width: 14),
              Expanded(child: Text(label, style: AppTypography.bodySans.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ))),
              Text('${value.round()}$suffix', style: AppTypography.subheadline.copyWith(
                color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
              )),
            ],
          ),
          Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged),
        ],
      ),
    );
  }
}
