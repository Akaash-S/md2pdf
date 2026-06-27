import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../providers/settings_provider.dart';
import '../../../screens/home/home_screen.dart';
import '../widgets/settings_widgets.dart';

class StorageSettings extends ConsumerStatefulWidget {
  const StorageSettings({super.key});
  @override
  ConsumerState<StorageSettings> createState() => _StorageSettingsState();
}

class _StorageSettingsState extends ConsumerState<StorageSettings> {
  String _outputPath = '';
  String _storageUsed = 'Calculating...';
  int _pdfCount = 0;
  bool _calculating = true;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    setState(() => _calculating = true);
    try {
      final base = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(base.path, 'md_to_pdf_outputs'));
      _outputPath = dir.path;

      if (await dir.exists()) {
        final files = dir.listSync().whereType<File>().toList();
        int totalBytes = 0;
        for (final f in files) totalBytes += await f.length();
        _pdfCount = files.length;
        _storageUsed = _formatBytes(totalBytes);
      } else {
        _pdfCount = 0;
        _storageUsed = '0 B';
      }
    } catch (_) {
      _storageUsed = 'Unknown';
    }
    if (mounted) setState(() => _calculating = false);
  }

  String _formatBytes(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<void> _clearAllPdfs(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_forever_rounded),
        title: const Text('Delete all PDF files?'),
        content: Text(
            'This permanently deletes all $_pdfCount PDF files from storage. History entries will also be cleared. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final base = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(base.path, 'md_to_pdf_outputs'));
      if (await dir.exists()) await dir.delete(recursive: true);
      ref.read(historyProvider.notifier).clear();
      await _loadStorageInfo();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All PDF files deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final notify = ref.read(settingsProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    final autoDeleteOptions = {
      0: 'Never',
      7: 'After 7 days',
      14: 'After 14 days',
      30: 'After 30 days',
      90: 'After 90 days',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Storage')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.folder_rounded,
                        color: scheme.onPrimaryContainer, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PDF Storage',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        if (_calculating)
                          const SizedBox(
                              height: 12,
                              width: 60,
                              child: LinearProgressIndicator())
                        else
                          Text(
                            '$_storageUsed - $_pdfCount file${_pdfCount != 1 ? 's' : ''}',
                            style: TextStyle(
                                fontSize: 13,
                                color: scheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _loadStorageInfo,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SettingsGroupCard(
            label: 'OUTPUT FOLDER',
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saved to',
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _outputPath.isEmpty ? 'Loading...' : _outputPath,
                        style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                            fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SettingsGroupCard(
            label: 'AUTO-DELETE',
            children: autoDeleteOptions.entries.map((entry) {
              return RadioSettingTile<int>(
                icon: Icons.auto_delete_outlined,
                title: entry.value,
                value: entry.key,
                groupValue: s.autoDeleteDays,
                onChanged: (v) => notify.update(s.copyWith(autoDeleteDays: v)),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SettingsGroupCard(
            label: 'DANGER ZONE',
            children: [
              ActionSettingTile(
                icon: Icons.delete_sweep_rounded,
                iconColor: scheme.error,
                title: 'Delete all PDF files',
                subtitle:
                    'Removes all $_pdfCount converted PDFs from device storage',
                textColor: scheme.error,
                onTap: () => _clearAllPdfs(context),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
