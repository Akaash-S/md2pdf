import 'package:flutter/material.dart';

enum AppThemeMode { system, light, dark }

enum PdfPageSize { a4, letter, a3 }

enum PdfMargin { narrow, normal, wide }

enum PdfFontScale { small, normal, large, xlarge }

enum AutoLockDelay { immediately, after30s, after1m, after5m, never }

class AppSettings {
  final AppThemeMode themeMode;
  final bool useDynamicColor;
  final Color seedColor;
  final bool biometricEnabled;
  final AutoLockDelay autoLockDelay;
  final bool screenshotProtection;
  final PdfPageSize pageSize;
  final PdfFontScale fontScale;
  final PdfMargin margin;
  final bool showHeader;
  final bool showFooter;
  final String pdfAuthorName;
  final int autoDeleteDays;
  final String? customOutputPath;
  final bool conversionNotification;
  final double textScaleFactor;
  final bool highContrast;
  final bool reduceMotion;

  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.useDynamicColor = true,
    this.seedColor = const Color(0xFF6C63FF),
    this.biometricEnabled = true,
    this.autoLockDelay = AutoLockDelay.immediately,
    this.screenshotProtection = true,
    this.pageSize = PdfPageSize.a4,
    this.fontScale = PdfFontScale.normal,
    this.margin = PdfMargin.normal,
    this.showHeader = true,
    this.showFooter = true,
    this.pdfAuthorName = '',
    this.autoDeleteDays = 0,
    this.customOutputPath,
    this.conversionNotification = true,
    this.textScaleFactor = 1.0,
    this.highContrast = false,
    this.reduceMotion = false,
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    bool? useDynamicColor,
    Color? seedColor,
    bool? biometricEnabled,
    AutoLockDelay? autoLockDelay,
    bool? screenshotProtection,
    PdfPageSize? pageSize,
    PdfFontScale? fontScale,
    PdfMargin? margin,
    bool? showHeader,
    bool? showFooter,
    String? pdfAuthorName,
    int? autoDeleteDays,
    String? customOutputPath,
    bool? conversionNotification,
    double? textScaleFactor,
    bool? highContrast,
    bool? reduceMotion,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        useDynamicColor: useDynamicColor ?? this.useDynamicColor,
        seedColor: seedColor ?? this.seedColor,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        autoLockDelay: autoLockDelay ?? this.autoLockDelay,
        screenshotProtection: screenshotProtection ?? this.screenshotProtection,
        pageSize: pageSize ?? this.pageSize,
        fontScale: fontScale ?? this.fontScale,
        margin: margin ?? this.margin,
        showHeader: showHeader ?? this.showHeader,
        showFooter: showFooter ?? this.showFooter,
        pdfAuthorName: pdfAuthorName ?? this.pdfAuthorName,
        autoDeleteDays: autoDeleteDays ?? this.autoDeleteDays,
        customOutputPath: customOutputPath ?? this.customOutputPath,
        conversionNotification:
            conversionNotification ?? this.conversionNotification,
        textScaleFactor: textScaleFactor ?? this.textScaleFactor,
        highContrast: highContrast ?? this.highContrast,
        reduceMotion: reduceMotion ?? this.reduceMotion,
      );

  String get themeModeLabel => switch (themeMode) {
        AppThemeMode.system => 'Follow system',
        AppThemeMode.light => 'Light',
        AppThemeMode.dark => 'Dark',
      };

  String get pageSizeLabel => switch (pageSize) {
        PdfPageSize.a4 => 'A4  (210 x 297 mm)',
        PdfPageSize.letter => 'Letter  (8.5 x 11 in)',
        PdfPageSize.a3 => 'A3  (297 x 420 mm)',
      };

  String get fontScaleLabel => switch (fontScale) {
        PdfFontScale.small => 'Small',
        PdfFontScale.normal => 'Normal',
        PdfFontScale.large => 'Large',
        PdfFontScale.xlarge => 'Extra large',
      };

  double get fontScaleValue => switch (fontScale) {
        PdfFontScale.small => 0.85,
        PdfFontScale.normal => 1.00,
        PdfFontScale.large => 1.20,
        PdfFontScale.xlarge => 1.45,
      };

  String get marginLabel => switch (margin) {
        PdfMargin.narrow => 'Narrow  (20 mm)',
        PdfMargin.normal => 'Normal  (25 mm)',
        PdfMargin.wide => 'Wide  (35 mm)',
      };

  double get marginValue => switch (margin) {
        PdfMargin.narrow => 20.0,
        PdfMargin.normal => 25.0,
        PdfMargin.wide => 35.0,
      };

  String get autoLockLabel => switch (autoLockDelay) {
        AutoLockDelay.immediately => 'Immediately',
        AutoLockDelay.after30s => 'After 30 seconds',
        AutoLockDelay.after1m => 'After 1 minute',
        AutoLockDelay.after5m => 'After 5 minutes',
        AutoLockDelay.never => 'Never',
      };

  Duration? get autoLockDuration => switch (autoLockDelay) {
        AutoLockDelay.immediately => Duration.zero,
        AutoLockDelay.after30s => const Duration(seconds: 30),
        AutoLockDelay.after1m => const Duration(minutes: 1),
        AutoLockDelay.after5m => const Duration(minutes: 5),
        AutoLockDelay.never => null,
      };
}
