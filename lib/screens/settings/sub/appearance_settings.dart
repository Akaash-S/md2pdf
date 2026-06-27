import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/app_settings.dart';
import '../../../providers/settings_provider.dart';
import '../widgets/settings_widgets.dart';

class AppearanceSettings extends ConsumerWidget {
  const AppearanceSettings({super.key});

  static const _seedColors = [
    Color(0xFF6C63FF),
    Color(0xFF1E8E3E),
    Color(0xFFE37400),
    Color(0xFFD93025),
    Color(0xFF9334E6),
    Color(0xFF00ACC1),
    Color(0xFFE91E63),
    Color(0xFF546E7A),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final notify = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          SettingsGroupCard(
            label: 'THEME',
            children: [
              ...AppThemeMode.values.map((mode) => RadioSettingTile(
                    title: _themeModeLabel(mode),
                    subtitle: _themeModeSubtitle(mode),
                    icon: _themeModeIcon(mode),
                    value: mode,
                    groupValue: s.themeMode,
                    onChanged: (v) =>
                        notify.update(s.copyWith(themeMode: v)),
                  )),
            ],
          ),
          const SizedBox(height: 16),
          SettingsGroupCard(
            label: 'COLOR',
            children: [
              SwitchSettingTile(
                title: 'Dynamic color',
                subtitle: 'Adapt to your wallpaper (Android 12+)',
                icon: Icons.auto_awesome_rounded,
                value: s.useDynamicColor,
                onChanged: (v) => notify.update(s.copyWith(useDynamicColor: v)),
              ),
              if (!s.useDynamicColor)
                _ColorPickerTile(
                  selected: s.seedColor,
                  colors: _seedColors,
                  onPicked: (c) => notify.update(s.copyWith(seedColor: c)),
                ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _themeModeLabel(AppThemeMode m) => switch (m) {
        AppThemeMode.system => 'Follow system',
        AppThemeMode.light => 'Light',
        AppThemeMode.dark => 'Dark',
      };

  String _themeModeSubtitle(AppThemeMode m) => switch (m) {
        AppThemeMode.system => 'Matches your device setting',
        AppThemeMode.light => 'Always use light theme',
        AppThemeMode.dark => 'Always use dark theme',
      };

  IconData _themeModeIcon(AppThemeMode m) => switch (m) {
        AppThemeMode.system => Icons.brightness_auto_rounded,
        AppThemeMode.light => Icons.light_mode_rounded,
        AppThemeMode.dark => Icons.dark_mode_rounded,
      };
}

class _ColorPickerTile extends StatelessWidget {
  final Color selected;
  final List<Color> colors;
  final ValueChanged<Color> onPicked;
  const _ColorPickerTile(
      {required this.selected, required this.colors, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('App color',
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: colors.map((c) {
              final isSelected = c.value == selected.value;
              return GestureDetector(
                onTap: () => onPicked(c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.onSurface,
                            width: 3)
                        : null,
                    boxShadow: isSelected
                        ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8)]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 22)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
