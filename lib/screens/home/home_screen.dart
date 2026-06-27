import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/security/secure_storage_service.dart';
import '../../models/converted_file.dart';
import '../converter/converter_screen.dart';
import '../viewer/pdf_viewer_screen.dart';
import '../../widgets/file_card.dart';
import '../../app.dart';

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<ConvertedFile>>(
  (ref) => HistoryNotifier(),
);

class HistoryNotifier extends StateNotifier<List<ConvertedFile>> {
  final _storage = SecureStorageService();
  HistoryNotifier() : super([]) {
    load();
  }

  Future<void> load() async {
    state = await _storage.getHistory();
  }

  Future<void> add(ConvertedFile file) async {
    await _storage.addToHistory(file);
    state = [file, ...state];
  }

  Future<void> remove(String id) async {
    await _storage.removeFromHistory(id);
    state = state.where((f) => f.id != id).toList();
  }

  Future<void> clear() async {
    await _storage.clearHistory();
    state = [];
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MD to PDF'),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              tooltip: 'Clear history',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmClear(context, ref),
            ),
          IconButton(
            tooltip: 'Lock app',
            icon: const Icon(Icons.lock_outline),
            onPressed: () =>
                ref.read(isAuthenticatedProvider.notifier).state = false,
          ),
        ],
      ),
      body: history.isEmpty
          ? _buildEmpty(context)
          : _buildHistory(context, ref, history),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openConverter(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Convert MD'),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined,
              size: 80, color: Colors.grey.shade300)
              .animate()
              .scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text('No conversions yet',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.grey)),
          const SizedBox(height: 8),
          Text('Tap the button below to convert your first MD file',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildHistory(
      BuildContext context, WidgetRef ref, List<ConvertedFile> history) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: history.length,
      itemBuilder: (_, i) {
        final file = history[i];
        return FileCard(
          file: file,
          onTap: () => _openViewer(context, file),
          onDelete: () => ref.read(historyProvider.notifier).remove(file.id),
        ).animate().fadeIn(delay: (i * 50).ms).slideY(begin: 0.1);
      },
    );
  }

  Future<void> _openConverter(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.push<ConvertedFile>(
      context,
      MaterialPageRoute(builder: (_) => const ConverterScreen()),
    );
    if (result != null) {
      ref.read(historyProvider.notifier).add(result);
    }
  }

  void _openViewer(BuildContext context, ConvertedFile file) {
    if (!File(file.pdfPath).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF file not found on device')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(file: file),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
            'Remove all conversion history? PDF files on disk will not be deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Clear', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) ref.read(historyProvider.notifier).clear();
  }
}
