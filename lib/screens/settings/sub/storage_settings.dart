import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../core/security/auth_service.dart';
import '../../../providers/settings_provider.dart';
import '../../../screens/home/home_screen.dart';
import '../../../widgets/pin_pad.dart';
import '../widgets/settings_widgets.dart';

class StorageSettings extends ConsumerStatefulWidget {
  const StorageSettings({super.key});
  @override
  ConsumerState<StorageSettings> createState() => _StorageSettingsState();
}

class _StorageSettingsState extends ConsumerState<StorageSettings> {
  final _auth = AuthService();
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
      final s = ref.read(settingsProvider);
      if (s.customOutputPath != null && await Directory(s.customOutputPath!).exists()) {
        _outputPath = s.customOutputPath!;
      } else {
        final base = await getApplicationDocumentsDirectory();
        _outputPath = p.join(base.path, 'md_to_pdf_outputs');
      }

      final dir = Directory(_outputPath);
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

  Future<void> _pickOutputFolder() async {
    final selected = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select output folder',
    );
    if (selected != null && mounted) {
      final s = ref.read(settingsProvider);
      await ref.read(settingsProvider.notifier).update(
          s.copyWith(customOutputPath: selected));
      await _loadStorageInfo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Output folder updated')),
        );
      }
    }
  }

  String _formatBytes(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<bool> _requirePin(BuildContext context) async {
    final scheme = Theme.of(context).colorScheme;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => _PinVerifySheet(scheme: scheme, auth: _auth),
    );

    return result ?? false;
  }

  Future<void> _clearAllPdfs(BuildContext context) async {
    final verified = await _requirePin(context);
    if (!verified || !mounted) return;

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
      final dir = Directory(_outputPath);
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          await entity.delete(recursive: true);
        }
      }
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
                    width: 56, height: 56,
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
                              height: 12, width: 60,
                              child: LinearProgressIndicator())
                        else
                          Text(
                            '$_storageUsed - $_pdfCount file${_pdfCount != 1 ? 's' : ''}',
                            style: TextStyle(
                                fontSize: 13, color: scheme.onSurfaceVariant),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text('Saved to',
                              style: TextStyle(
                                  fontSize: 12, color: scheme.onSurfaceVariant)),
                        ),
                        TextButton.icon(
                          onPressed: _pickOutputFolder,
                          icon: const Icon(Icons.folder_open, size: 16),
                          label: const Text('Change'),
                        ),
                      ],
                    ),
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

class _PinVerifySheet extends StatefulWidget {
  final ColorScheme scheme;
  final AuthService auth;
  const _PinVerifySheet({required this.scheme, required this.auth});

  @override
  State<_PinVerifySheet> createState() => _PinVerifySheetState();
}

class _PinVerifySheetState extends State<_PinVerifySheet> {
  String? _error;

  void _onPin(String pin) async {
    final valid = await widget.auth.verifyPin(pin);
    if (!mounted) return;
    if (valid) {
      Navigator.pop(context, true);
    } else {
      setState(() => _error = 'Incorrect PIN');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: widget.scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(Icons.lock_outline, size: 40, color: widget.scheme.primary),
            const SizedBox(height: 12),
            Text('Enter PIN to continue',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            PinPad(onComplete: _onPin, errorText: _error),
          ],
        ),
      ),
    );
  }
}
