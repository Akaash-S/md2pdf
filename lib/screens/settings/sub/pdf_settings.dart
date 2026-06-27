import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/app_settings.dart';
import '../../../providers/settings_provider.dart';
import '../widgets/settings_widgets.dart';

class PdfSettings extends ConsumerStatefulWidget {
  const PdfSettings({super.key});
  @override
  ConsumerState<PdfSettings> createState() => _PdfSettingsState();
}

class _PdfSettingsState extends ConsumerState<PdfSettings> {
  late TextEditingController _authorCtrl;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _authorCtrl = TextEditingController(text: s.pdfAuthorName);
  }

  @override
  void dispose() {
    _authorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final notify = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('PDF Output')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          SettingsGroupCard(
            label: 'PAGE SIZE',
            children: PdfPageSize.values.map((size) => RadioSettingTile(
                  icon: Icons.crop_landscape_outlined,
                  title: _pageSizeTitle(size),
                  subtitle: _pageSizeSubtitle(size),
                  value: size,
                  groupValue: s.pageSize,
                  onChanged: (v) => notify.update(s.copyWith(pageSize: v)),
                )).toList(),
          ),
          const SizedBox(height: 16),
          SettingsGroupCard(
            label: 'BODY TEXT SIZE',
            children: PdfFontScale.values.map((scale) => RadioSettingTile(
                  icon: Icons.format_size_rounded,
                  title: _fontScaleTitle(scale),
                  subtitle: _fontScaleSubtitle(scale),
                  value: scale,
                  groupValue: s.fontScale,
                  onChanged: (v) => notify.update(s.copyWith(fontScale: v)),
                )).toList(),
          ),
          const SizedBox(height: 16),
          SettingsGroupCard(
            label: 'MARGINS',
            children: PdfMargin.values.map((m) => RadioSettingTile(
                  icon: Icons.space_bar_rounded,
                  title: _marginTitle(m),
                  subtitle: _marginSubtitle(m),
                  value: m,
                  groupValue: s.margin,
                  onChanged: (v) => notify.update(s.copyWith(margin: v)),
                )).toList(),
          ),
          const SizedBox(height: 16),
          SettingsGroupCard(
            label: 'HEADER & FOOTER',
            children: [
              SwitchSettingTile(
                icon: Icons.vertical_align_top_rounded,
                title: 'Show header',
                subtitle: 'File name and date at top of each page',
                value: s.showHeader,
                onChanged: (v) => notify.update(s.copyWith(showHeader: v)),
              ),
              SwitchSettingTile(
                icon: Icons.vertical_align_bottom_rounded,
                title: 'Show footer',
                subtitle: 'Page number at bottom of each page',
                value: s.showFooter,
                onChanged: (v) => notify.update(s.copyWith(showFooter: v)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SettingsGroupCard(
            label: 'PDF METADATA',
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: TextField(
                  controller: _authorCtrl,
                  decoration: InputDecoration(
                    labelText: 'Author name',
                    hintText: 'Embedded in PDF file info',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check_rounded),
                      tooltip: 'Save',
                      onPressed: () {
                        notify.update(s.copyWith(
                            pdfAuthorName: _authorCtrl.text.trim()));
                        FocusScope.of(context).unfocus();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Author name saved')),
                        );
                      },
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (v) =>
                      notify.update(s.copyWith(pdfAuthorName: v.trim())),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _pageSizeTitle(PdfPageSize s) => switch (s) {
        PdfPageSize.a4 => 'A4',
        PdfPageSize.letter => 'US Letter',
        PdfPageSize.a3 => 'A3',
      };

  String _pageSizeSubtitle(PdfPageSize s) => switch (s) {
        PdfPageSize.a4 => '210 x 297 mm - International standard',
        PdfPageSize.letter => '8.5 x 11 in - North America',
        PdfPageSize.a3 => '297 x 420 mm - Large format',
      };

  String _fontScaleTitle(PdfFontScale s) => switch (s) {
        PdfFontScale.small => 'Small  (9 pt)',
        PdfFontScale.normal => 'Normal  (11 pt)',
        PdfFontScale.large => 'Large  (13 pt)',
        PdfFontScale.xlarge => 'Extra Large  (16 pt)',
      };

  String _fontScaleSubtitle(PdfFontScale s) => switch (s) {
        PdfFontScale.small => 'Fits more content per page',
        PdfFontScale.normal => 'Recommended for most documents',
        PdfFontScale.large => 'Easier to read on screen',
        PdfFontScale.xlarge => 'Maximum readability',
      };

  String _marginTitle(PdfMargin m) => switch (m) {
        PdfMargin.narrow => 'Narrow  (20 mm)',
        PdfMargin.normal => 'Normal  (25 mm)',
        PdfMargin.wide => 'Wide  (35 mm)',
      };

  String _marginSubtitle(PdfMargin m) => switch (m) {
        PdfMargin.narrow => 'More content area, less whitespace',
        PdfMargin.normal => 'Standard - good for most use cases',
        PdfMargin.wide => 'Generous whitespace, easier reading',
      };
}
