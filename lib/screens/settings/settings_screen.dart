import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'sub/appearance_settings.dart';
import 'sub/security_settings.dart';
import 'sub/pdf_settings.dart';
import 'sub/storage_settings.dart';
import 'sub/about_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final sections = [
      _SettingsSection(
        icon: Icons.palette_outlined,
        iconColor: scheme.primary,
        title: 'Appearance',
        subtitle: 'Theme, color, dynamic color',
        screen: const AppearanceSettings(),
      ),
      _SettingsSection(
        icon: Icons.security_rounded,
        iconColor: const Color(0xFF00897B),
        title: 'Security',
        subtitle: 'PIN, biometrics, auto-lock',
        screen: const SecuritySettings(),
      ),
      _SettingsSection(
        icon: Icons.picture_as_pdf_outlined,
        iconColor: const Color(0xFFE53935),
        title: 'PDF Output',
        subtitle: 'Page size, font, margins, header',
        screen: const PdfSettings(),
      ),
      _SettingsSection(
        icon: Icons.folder_outlined,
        iconColor: const Color(0xFFFB8C00),
        title: 'Storage',
        subtitle: 'Output folder, auto-delete, usage',
        screen: const StorageSettings(),
      ),
      _SettingsSection(
        icon: Icons.info_outline_rounded,
        iconColor: scheme.secondary,
        title: 'About',
        subtitle: 'Version, licenses, reset',
        screen: const AboutSettings(),
      ),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            automaticallyImplyLeading: false,
            backgroundColor: scheme.surface,
            title: const Text('Settings'),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            sliver: SliverList.builder(
              itemCount: sections.length,
              itemBuilder: (context, i) {
                final s = sections[i];
                return _SectionCard(section: s)
                    .animate()
                    .fadeIn(delay: (i * 55).ms)
                    .slideY(begin: 0.07, curve: Curves.easeOutCubic);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget screen;
  const _SettingsSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.screen,
  });
}

class _SectionCard extends StatelessWidget {
  final _SettingsSection section;
  const _SectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => section.screen),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: section.iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(section.icon, color: section.iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(section.title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(section.subtitle,
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
