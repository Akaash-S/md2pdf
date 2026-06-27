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
  double _progress = 0;
  String _statusText = '';

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
      });
    }
  }

  Future<void> _convert() async {
    if (_selectedMdPath == null) return;

    setState(() {
      _isConverting = true;
      _progress = 0;
      _statusText = 'Reading markdown file...';
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

      if (mounted) {
        final action = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Conversion Complete'),
            content: Text('${convertedFile.fileName}\n${convertedFile.formattedSize}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'share'),
                child: const Text('Share'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, 'view'),
                child: const Text('View PDF'),
              ),
            ],
          ),
        );
        if (action == 'view') {
          ref.read(historyProvider.notifier).add(convertedFile);
          ref.read(appTabIndexProvider.notifier).state = 0;
        } else if (action == 'share') {
          try {
            await Share.shareXFiles(
              [XFile(pdfPath)],
              text: convertedFile.fileName,
            );
          } catch (_) {}
        }
      }
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Convert Markdown')),
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

            if (_selectedMdPath != null && !_isConverting) ...[
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
