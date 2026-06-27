import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../providers/settings_provider.dart';
import '../widgets/settings_widgets.dart';

class AboutSettings extends ConsumerStatefulWidget {
  const AboutSettings({super.key});
  @override
  ConsumerState<AboutSettings> createState() => _AboutSettingsState();
}

class _AboutSettingsState extends ConsumerState<AboutSettings> {
  String _version = '';
  String _buildNum = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() {
          _version = info.version;
          _buildNum = info.buildNumber;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final notify = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(Icons.picture_as_pdf_rounded,
                        size: 44, color: scheme.onPrimaryContainer),
                  ),
                  const SizedBox(height: 16),
                  const Text('MD to PDF',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    _version.isEmpty
                        ? 'Loading...'
                        : 'Version $_version (Build $_buildNum)',
                    style: TextStyle(
                        fontSize: 13, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Secure Markdown to PDF Converter',
                    style: TextStyle(
                        fontSize: 13, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SettingsGroupCard(
            label: 'INFO',
            children: [
              ActionSettingTile(
                icon: Icons.article_outlined,
                title: 'Open-source licenses',
                subtitle: 'Flutter and third-party packages',
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'MD to PDF',
                  applicationVersion: _version,
                  applicationLegalese: '(c) 2025. Personal use only.',
                ),
              ),
              ActionSettingTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy policy',
                subtitle: 'All data stays on your device - no servers',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          SettingsGroupCard(
            label: 'SECURITY SUMMARY',
            children: const [
              _InfoRow(
                  icon: Icons.lock_rounded,
                  text: 'PIN-protected with SHA-256 hash'),
              _InfoRow(
                  icon: Icons.storage_rounded,
                  text: 'Data stored in AES-encrypted keystore'),
              _InfoRow(
                  icon: Icons.cloud_off_rounded,
                  text: 'No internet access - fully offline'),
              _InfoRow(
                  icon: Icons.no_photography_rounded,
                  text: 'Screenshot protection (Android)'),
            ],
          ),
          const SizedBox(height: 16),
          SettingsGroupCard(
            label: 'RESET',
            children: [
              ActionSettingTile(
                icon: Icons.restart_alt_rounded,
                iconColor: scheme.error,
                title: 'Reset all settings',
                subtitle:
                    'Restore all settings to defaults (keeps PIN and history)',
                textColor: scheme.error,
                onTap: () => _confirmReset(context, notify),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Center(
            child: Text(
              'Made using Flutter & Material 3',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _confirmReset(
      BuildContext context, SettingsNotifier notifier) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.restart_alt_rounded),
        title: const Text('Reset all settings?'),
        content: const Text(
            'All appearance, PDF, storage, and security preferences will return to defaults. Your PIN and conversion history are not affected.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reset')),
        ],
      ),
    );
    if (ok == true) {
      await notifier.reset();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings reset to defaults')),
        );
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
