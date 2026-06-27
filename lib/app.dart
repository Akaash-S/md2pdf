import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'core/theme/app_theme.dart';
import 'core/security/auth_service.dart';
import 'models/app_settings.dart';
import 'providers/settings_provider.dart';
import 'screens/auth/lock_screen.dart';
import 'screens/auth/setup_pin_screen.dart';
import 'screens/shell/app_shell.dart';

final isAuthenticatedProvider = StateProvider<bool>((_) => false);
final isFirstLaunchProvider = StateProvider<bool>((_) => true);
final appTabIndexProvider = StateProvider<int>((_) => 0);

class MdToPdfApp extends ConsumerStatefulWidget {
  const MdToPdfApp({super.key});
  @override
  ConsumerState<MdToPdfApp> createState() => _MdToPdfAppState();
}

class _MdToPdfAppState extends ConsumerState<MdToPdfApp>
    with WidgetsBindingObserver {
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkFirstLaunch();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final settings = ref.read(settingsProvider);
    final lockDelay = settings.autoLockDuration;

    if (state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
      if (lockDelay == Duration.zero) {
        ref.read(isAuthenticatedProvider.notifier).state = false;
      }
    }

    if (state == AppLifecycleState.resumed && _backgroundedAt != null) {
      if (lockDelay == null) return;
      final elapsed = DateTime.now().difference(_backgroundedAt!);
      if (elapsed >= lockDelay) {
        ref.read(isAuthenticatedProvider.notifier).state = false;
      }
      _backgroundedAt = null;
    }
  }

  Future<void> _checkFirstLaunch() async {
    final hasPin = await AuthService().hasPin();
    ref.read(isFirstLaunchProvider.notifier).state = !hasPin;
  }

  @override
  Widget build(BuildContext context) {
    final isAuth = ref.watch(isAuthenticatedProvider);
    final isFirst = ref.watch(isFirstLaunchProvider);
    final settings = ref.watch(settingsProvider);
    final useDynamic = settings.useDynamicColor;
    final seedColor = settings.seedColor;
    final textScale = settings.textScaleFactor;
    final highContrast = settings.highContrast;
    final reduceMotion = settings.reduceMotion;

    final themeMode = switch (settings.themeMode) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        ColorScheme lightScheme;
        ColorScheme darkScheme;

        if (useDynamic && lightDynamic != null && darkDynamic != null) {
          lightScheme = lightDynamic.harmonized();
          darkScheme = darkDynamic.harmonized();
        } else {
          lightScheme = ColorScheme.fromSeed(
              seedColor: seedColor, brightness: Brightness.light);
          darkScheme = ColorScheme.fromSeed(
              seedColor: seedColor, brightness: Brightness.dark);
        }

        if (highContrast) {
          lightScheme = lightScheme.copyWith(
            surface: Colors.white,
            onSurface: Colors.black,
            primary: Colors.black,
            onPrimary: Colors.white,
          );
          darkScheme = darkScheme.copyWith(
            surface: Colors.black,
            onSurface: Colors.white,
            primary: Colors.white,
            onPrimary: Colors.black,
          );
        }

        return MaterialApp(
          title: 'MD to PDF',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.fromScheme(lightScheme),
          darkTheme: AppTheme.fromScheme(darkScheme),
          themeMode: themeMode,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: reduceMotion
                ? _NoAnimationScope(child: child!)
                : child!,
          ),
          home: _resolve(isAuth, isFirst),
        );
      },
    );
  }

  Widget _resolve(bool isAuth, bool isFirst) {
    if (isFirst) return const SetupPinScreen();
    if (!isAuth) return const LockScreen();
    return const AppShell();
  }
}

class _NoAnimationScope extends StatelessWidget {
  final Widget child;
  const _NoAnimationScope({required this.child});
  @override
  Widget build(BuildContext context) {
    return child;
  }
}
