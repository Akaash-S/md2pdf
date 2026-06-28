import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../models/converted_file.dart';

class PdfViewerScreen extends StatefulWidget {
  final ConvertedFile file;
  const PdfViewerScreen({super.key, required this.file});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _controller = PdfViewerController();
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isLoaded = false;
  bool _appBarsVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    });
  }

  void _toggleBars() {
    setState(() => _appBarsVisible = !_appBarsVisible);
  }

  Future<void> _sharePdf(BuildContext context) async {
    try {
      await Share.shareXFiles(
        [XFile(widget.file.pdfPath)],
        text: '${widget.file.fileName}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: _appBarsVisible
          ? AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () { Navigator.of(context).pop(); },
                tooltip: 'Back',
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.file.fileName,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    DateFormat('MMM dd, yyyy · HH:mm')
                        .format(widget.file.convertedAt),
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  tooltip: 'Share PDF',
                  onPressed: () => _sharePdf(context),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text('READ ONLY',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: _toggleBars,
        child: Stack(
          children: [
            Container(
              color: scheme.surface,
              child: SfPdfViewer.file(
                File(widget.file.pdfPath),
                controller: _controller,
                pageSpacing: 8,
                canShowScrollHead: false,
                canShowScrollStatus: false,
                canShowPaginationDialog: false,
                onDocumentLoaded: (details) {
                  setState(() {
                    _totalPages = details.document.pages.count;
                    _isLoaded = true;
                  });
                },
                onPageChanged: (details) {
                  setState(() {
                    _currentPage = details.newPageNumber;
                  });
                },
              ),
            ),
            if (!_isLoaded)
              Center(
                child: CircularProgressIndicator(color: scheme.primary),
              ),
            if (_isLoaded && _appBarsVisible)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_currentPage / $_totalPages',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
