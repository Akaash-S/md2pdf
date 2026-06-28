import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../app.dart';
import '../../core/utils/markdown_converter.dart';
import '../../models/converted_file.dart';
import '../../providers/settings_provider.dart';
import '../home/home_screen.dart';
import '../viewer/pdf_viewer_screen.dart';

class ConverterScreen extends ConsumerStatefulWidget {
  const ConverterScreen({super.key});

  @override
  ConsumerState<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends ConsumerState<ConverterScreen> {
  final _converter = MarkdownConverter();
  final _uuid = const Uuid();

  String? _selectedMdPath;
  String? _selectedFileName;
  bool _isConverting = false;
  bool _isViewing = false;
  double _progress = 0;
  String _statusText = '';
  ConvertedFile? _convertedFile;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['md', 'markdown', 'txt'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
      _safeSetState(() {
        _selectedMdPath = result.files.single.path;
        _selectedFileName = result.files.single.name;
        _statusText = '';
        _convertedFile = null;
        _isViewing = false;
      });
    }
  }

  Future<void> _convert() async {
    if (_selectedMdPath == null) return;

    if (!mounted) return;
    setState(() {
      _isConverting = true;
      _isViewing = false;
      _progress = 0;
      _statusText = 'Reading markdown file...';
      _convertedFile = null;
    });

    try {
      await _animateProgress(0.3, 'Parsing markdown...');
      await _animateProgress(0.6, 'Generating PDF...');
      await _animateProgress(0.85, 'Saving file...');

      final settings = ref.read(settingsProvider);
      final pdfPath = await _converter.convertToPdf(
        _selectedMdPath!,
        settings: settings,
      );
      final pdfFile = File(pdfPath);

      await _animateProgress(1.0, 'Done!');

      final convertedFile = ConvertedFile(
        id: _uuid.v4(),
        originalMdPath: _selectedMdPath!,
        pdfPath: pdfPath,
        fileName: p.basenameWithoutExtension(_selectedFileName ?? 'document'),
        convertedAt: DateTime.now(),
        fileSizeBytes: await pdfFile.length(),
      );

      if (!mounted) return;
      setState(() {
        _isConverting = false;
        _convertedFile = convertedFile;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isConverting = false;
        _statusText = 'Error: ${e.toString()}';
      });
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) try { setState(fn); } catch (_) {}
  }

  Future<void> _animateProgress(double target, String text) async {
    _safeSetState(() => _statusText = text);
    while (_progress < target) {
      await Future.delayed(const Duration(milliseconds: 30));
      _safeSetState(() {
        if (_progress < target) _progress += 0.02;
      });
    }
    _safeSetState(() => _progress = target);
  }

  Future<void> _onViewPdf() async {
    if (_isViewing) return;
    final file = _convertedFile;
    if (file == null) return;
    _isViewing = true;

    // Save to history first
    await ref.read(historyProvider.notifier).add(file);
    if (!mounted) return;

    // Navigate directly to the PDF viewer — no pop needed
    // ConverterScreen is a tab, not a pushed route
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(file: file),
      ),
    );

    if (!mounted) return;
    _isViewing = false;

    // After viewer closes, switch bottom nav to History tab
    ref.read(appTabIndexProvider.notifier).state = 0;
  }

  Future<void> _onSharePdf() async {
    final file = _convertedFile;
    if (file == null) return;
    try {
      await Share.shareXFiles(
        [XFile(file.pdfPath)],
        text: file.fileName,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 64,
        leading: Container(
          width: 44,
          height: 44,
          margin: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.picture_as_pdf_rounded,
              color: scheme.onPrimaryContainer, size: 28),
        ),
        title: const Text('Convert Markdown'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFilePickerCard(scheme),
            const SizedBox(height: 16),

            if (_statusText.startsWith('Error:'))
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_statusText,
                    style: TextStyle(color: scheme.error, fontSize: 13),
                    textAlign: TextAlign.center),
              ),

            SizedBox(height: _statusText.startsWith('Error:') ? 8 : 16),

            if (_selectedMdPath != null && !_isConverting && _convertedFile == null) ...[
              _buildFilePreview(),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _convert,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Convert to PDF'),
              ).animate().fadeIn().scale(),
            ],

            if (_isConverting) ...[
              _buildProgressSection(scheme),
            ],

            if (_convertedFile != null && !_isConverting) ...[
              _SuccessCard(
                file: _convertedFile!,
                onView: _onViewPdf,
                onShare: _onSharePdf,
              ).animate().fadeIn().scale(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilePickerCard(ColorScheme scheme) {
    return GestureDetector(
      onTap: _isConverting ? null : _pickFile,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedMdPath != null
                ? scheme.primary
                : Colors.grey.shade300,
            width: 2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(16),
          color: _selectedMdPath != null
              ? scheme.primary.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
        child: Column(
          children: [
            Icon(
              _selectedMdPath != null
                  ? Icons.check_circle_outline
                  : Icons.upload_file_outlined,
              size: 48,
              color: _selectedMdPath != null ? scheme.primary : Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              _selectedMdPath != null
                  ? 'File selected'
                  : 'Tap to select .md file',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _selectedMdPath != null
                      ? scheme.primary
                      : Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              'Supports .md, .markdown, .txt',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ).animate().fadeIn(),
    );
  }

  Widget _buildFilePreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.description, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_selectedFileName ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  _selectedMdPath!,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() {
              _selectedMdPath = null;
              _selectedFileName = null;
              _convertedFile = null;
            }),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildProgressSection(ColorScheme scheme) {
    return Column(
      children: [
        Text(_statusText,
            style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 8,
            backgroundColor: scheme.primary.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
          ),
        ),
        const SizedBox(height: 8),
        Text('${(_progress * 100).toInt()}%',
            style: const TextStyle(color: Colors.grey)),
      ],
    ).animate().fadeIn();
  }
}

class _SuccessCard extends StatelessWidget {
  final ConvertedFile file;
  final Future<void> Function() onView;
  final VoidCallback onShare;

  const _SuccessCard({
    required this.file,
    required this.onView,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 56),
            const SizedBox(height: 12),
            Text('Conversion Complete',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface)),
            const SizedBox(height: 6),
            Text(
              '${file.fileName} \u2022 ${file.formattedSize}',
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onView,
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View PDF'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
