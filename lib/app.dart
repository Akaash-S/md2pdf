import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/security/auth_service.dart';
import 'screens/auth/lock_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/auth/setup_pin_screen.dart';


final isAuthenticatedProvider = StateProvider<bool>((ref) => false);
final isFirstLaunchProvider = StateProvider<bool>((ref) => true);
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class MdToPdfApp extends ConsumerStatefulWidget {
  const MdToPdfApp({super.key});

  @override
  ConsumerState<MdToPdfApp> createState() => _MdToPdfAppState();
}

class _MdToPdfAppState extends ConsumerState<MdToPdfApp>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkFirstLaunch();
    _loadTheme();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? 0;
    ref.read(themeModeProvider.notifier).state = ThemeMode.values[themeIndex];
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      ref.read(isAuthenticatedProvider.notifier).state = false;
    }
  }

  Future<void> _checkFirstLaunch() async {
    final authService = AuthService();
    final hasPin = await authService.hasPin();
    ref.read(isFirstLaunchProvider.notifier).state = !hasPin;
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final isFirstLaunch = ref.watch(isFirstLaunchProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'MD to PDF',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: _resolveScreen(isAuthenticated, isFirstLaunch),
    );
  }

  Widget _resolveScreen(bool isAuthenticated, bool isFirstLaunch) {
    if (isFirstLaunch) return const SetupPinScreen();
    if (!isAuthenticated) return const LockScreen();
    return const HomeScreen();
  }
}
