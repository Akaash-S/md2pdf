import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/security/auth_service.dart';
import 'core/settings/settings_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Resolve both before first frame — eliminates blank-screen flash
  final results = await Future.wait([
    AuthService().hasPin(),
    SettingsService().init(),
  ]);
  final hasPin = results[0] as bool;

  runApp(
    ProviderScope(
      overrides: [
        // Pre-seed the provider with the correct value synchronously
        isFirstLaunchProvider.overrideWith((ref) => !hasPin),
      ],
      child: const MdToPdfApp(),
    ),
  );
}
