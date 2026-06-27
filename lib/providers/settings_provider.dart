import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/settings/settings_service.dart';
import '../models/app_settings.dart';

final settingsServiceProvider = Provider((_) => SettingsService());

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsService _service;

  SettingsNotifier(this._service) : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    state = await _service.load();
  }

  Future<void> update(AppSettings updated) async {
    state = updated;
    await _service.save(updated);
  }

  Future<void> reset() async {
    await _service.reset();
    state = const AppSettings();
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(settingsServiceProvider));
});

final themeModeProvider =
    Provider((ref) => ref.watch(settingsProvider.select((s) => s.themeMode)));

final useDynamicColorProvider =
    Provider((ref) => ref.watch(settingsProvider.select((s) => s.useDynamicColor)));

final seedColorProvider =
    Provider((ref) => ref.watch(settingsProvider.select((s) => s.seedColor)));

final reduceMotionProvider =
    Provider((ref) => ref.watch(settingsProvider.select((s) => s.reduceMotion)));

final highContrastProvider =
    Provider((ref) => ref.watch(settingsProvider.select((s) => s.highContrast)));

final textScaleProvider =
    Provider((ref) => ref.watch(settingsProvider.select((s) => s.textScaleFactor)));

final biometricEnabledProvider =
    Provider((ref) => ref.watch(settingsProvider.select((s) => s.biometricEnabled)));

final screenshotProtectionProvider =
    Provider((ref) => ref.watch(settingsProvider.select((s) => s.screenshotProtection)));
