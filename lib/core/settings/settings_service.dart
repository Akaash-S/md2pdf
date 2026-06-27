import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/app_settings.dart';

class SettingsService {
  static final SettingsService _i = SettingsService._();
  factory SettingsService() => _i;
  SettingsService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> get _p async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<AppSettings> load() async {
    final p = await _p;
    return AppSettings(
      themeMode: AppThemeMode.values[
          p.getInt('themeMode')?.clamp(0, AppThemeMode.values.length - 1) ?? 0],
      useDynamicColor: p.getBool('useDynamicColor') ?? true,
      seedColor: Color(p.getInt('seedColor') ?? 0xFF6C63FF),
      biometricEnabled: p.getBool('biometricEnabled') ?? true,
      autoLockDelay: AutoLockDelay.values[p
              .getInt('autoLockDelay')
              ?.clamp(0, AutoLockDelay.values.length - 1) ??
          0],
      screenshotProtection: p.getBool('screenshotProtection') ?? true,
      pageSize: PdfPageSize.values[
          p.getInt('pageSize')?.clamp(0, PdfPageSize.values.length - 1) ?? 0],
      fontScale: PdfFontScale.values[
          p.getInt('fontScale')?.clamp(0, PdfFontScale.values.length - 1) ?? 1],
      margin: PdfMargin.values[
          p.getInt('margin')?.clamp(0, PdfMargin.values.length - 1) ?? 1],
      showHeader: p.getBool('showHeader') ?? true,
      showFooter: p.getBool('showFooter') ?? true,
      pdfAuthorName: p.getString('pdfAuthorName') ?? '',
      autoDeleteDays: p.getInt('autoDeleteDays') ?? 0,
      customOutputPath: p.getString('customOutputPath'),
      conversionNotification: p.getBool('conversionNotification') ?? true,
      textScaleFactor: p.getDouble('textScaleFactor') ?? 1.0,
      highContrast: p.getBool('highContrast') ?? false,
      reduceMotion: p.getBool('reduceMotion') ?? false,
    );
  }

  Future<void> save(AppSettings s) async {
    final p = await _p;
    await Future.wait([
      p.setInt('themeMode', s.themeMode.index),
      p.setBool('useDynamicColor', s.useDynamicColor),
      p.setInt('seedColor', s.seedColor.value),
      p.setBool('biometricEnabled', s.biometricEnabled),
      p.setInt('autoLockDelay', s.autoLockDelay.index),
      p.setBool('screenshotProtection', s.screenshotProtection),
      p.setInt('pageSize', s.pageSize.index),
      p.setInt('fontScale', s.fontScale.index),
      p.setInt('margin', s.margin.index),
      p.setBool('showHeader', s.showHeader),
      p.setBool('showFooter', s.showFooter),
      p.setString('pdfAuthorName', s.pdfAuthorName),
      p.setInt('autoDeleteDays', s.autoDeleteDays),
      p.setBool('conversionNotification', s.conversionNotification),
      p.setDouble('textScaleFactor', s.textScaleFactor),
      p.setBool('highContrast', s.highContrast),
      p.setBool('reduceMotion', s.reduceMotion),
    ]);
  }

  Future<void> reset() async {
    final p = await _p;
    await p.clear();
  }
}
