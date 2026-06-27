import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/security/auth_service.dart';
import '../../core/security/secure_storage_service.dart';
import '../../app.dart';

final biometricEnabledProvider = StateProvider<bool>((ref) => true);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _authService = AuthService();
  final _storage = SecureStorageService();
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? 0;
    final biometricEnabled = prefs.getBool('biometric_enabled') ?? true;
    final bioAvailable = await _authService.isBiometricAvailable();

    if (!mounted) return;
    ref.read(themeModeProvider.notifier).state = ThemeMode.values[themeIndex];
    ref.read(biometricEnabledProvider.notifier).state = biometricEnabled;

    setState(() => _biometricAvailable = bioAvailable);
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    ref.read(themeModeProvider.notifier).state = mode;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    await prefs.setInt('theme_mode', mode.index);
  }

  Future<void> _setBiometricEnabled(bool enabled) async {
    ref.read(biometricEnabledProvider.notifier).state = enabled;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    await prefs.setBool('biometric_enabled', enabled);
  }

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
            'This will delete your PIN and all conversion history. You will be prompted to set up a new PIN. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Clear All',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await _authService.clearAll();
      await _storage.clearHistory();
      if (!mounted) return;
      ref.read(isFirstLaunchProvider.notifier).state = true;
      ref.read(isAuthenticatedProvider.notifier).state = false;
    }
  }

  Future<void> _changePin() async {
    await _authService.clearAll();
    if (!mounted) return;
    ref.read(isFirstLaunchProvider.notifier).state = true;
    ref.read(isAuthenticatedProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final biometricEnabled = ref.watch(biometricEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Appearance', Icons.palette_outlined, scheme),
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ListTile(
                  leading: Icon(Icons.brightness_6),
                  title: Text('Theme'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(value: ThemeMode.system, label: Text('System')),
                      ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                      ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (v) => _setThemeMode(v.first),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Security', Icons.security_outlined, scheme),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint),
                  title: const Text('Biometric Authentication'),
                  subtitle: Text(
                      _biometricAvailable ? 'Available' : 'Not available on this device'),
                  value: _biometricAvailable && biometricEnabled,
                  onChanged: _biometricAvailable ? (v) => _setBiometricEnabled(v) : null,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.lock_reset),
                  title: const Text('Change PIN'),
                  subtitle: const Text('Set a new 6-digit PIN'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _changePin,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Data', Icons.storage_outlined, scheme),
          Card(
            child: ListTile(
              leading: Icon(Icons.delete_forever, color: scheme.error),
              title: Text('Clear All Data',
                  style: TextStyle(color: scheme.error)),
              subtitle: const Text('Remove PIN and conversion history'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _clearAllData,
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('About', Icons.info_outline, scheme),
          const Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: Icon(Icons.info),
                  title: Text('MD to PDF'),
                  subtitle: Text('Version 1.0.0'),
                ),
                Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.description),
                  title: Text('Description'),
                  subtitle: Text(
                      'A secure Markdown to PDF converter and viewer. '
                      'Convert .md files to beautifully formatted PDFs with '
                      'biometric security and encrypted storage.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary)),
        ],
      ),
    );
  }

}
