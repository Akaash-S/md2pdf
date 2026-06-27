import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/converted_file.dart';

class FileCard extends StatelessWidget {
  final ConvertedFile file;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  const FileCard({
    super.key,
    required this.file,
    required this.onTap,
    required this.onShare,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final exists = File(file.pdfPath).existsSync();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: exists ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: exists
                      ? scheme.primary.withValues(alpha: 0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.picture_as_pdf,
                  color: exists ? scheme.primary : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.fileName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(file.convertedAt),
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                    Text(
                      file.formattedSize,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade400),
                    ),
                    if (!exists)
                      Text('File not found',
                          style: TextStyle(
                              fontSize: 11, color: scheme.error)),
                  ],
                ),
              ),
              if (exists)
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 20),
                  color: Colors.grey,
                  tooltip: 'Share PDF',
                  onPressed: onShare,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: Colors.grey,
                tooltip: 'Rename',
                onPressed: onRename,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: Colors.grey,
                onPressed: () => _confirmDelete(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from History'),
        content: const Text('Remove this entry? The PDF file won\'t be deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) onDelete();
  }
}
