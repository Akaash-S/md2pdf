import 'dart:io';
import 'package:markdown/markdown.dart' as md;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class MarkdownConverter {
  static final MarkdownConverter _instance = MarkdownConverter._internal();
  factory MarkdownConverter() => _instance;
  MarkdownConverter._internal();

  Future<String> convertToPdf(String mdFilePath) async {
    final mdFile = File(mdFilePath);
    if (!await mdFile.exists()) throw Exception('Markdown file not found');
    final markdownContent = await mdFile.readAsString();

    final nodes = md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
    ).parseLines(markdownContent.split('\n'));

    final pdf = pw.Document(
      author: 'MD to PDF App',
      creator: 'MD to PDF',
      title: p.basenameWithoutExtension(mdFilePath),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => _buildPdfWidgets(nodes, markdownContent),
      ),
    );

    final outputDir = await _getOutputDirectory();
    final fileName =
        '${p.basenameWithoutExtension(mdFilePath)}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final outputPath = p.join(outputDir, fileName);

    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(await pdf.save());

    return outputPath;
  }

  List<pw.Widget> _buildPdfWidgets(
      List<md.Node> nodes, String rawMarkdown) {
    final widgets = <pw.Widget>[];
    final lines = rawMarkdown.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        widgets.add(pw.SizedBox(height: 8));
        continue;
      }

      if (trimmed.startsWith('# ')) {
        widgets.add(_buildHeading(trimmed.substring(2), 1));
      } else if (trimmed.startsWith('## ')) {
        widgets.add(_buildHeading(trimmed.substring(3), 2));
      } else if (trimmed.startsWith('### ')) {
        widgets.add(_buildHeading(trimmed.substring(4), 3));
      } else if (trimmed.startsWith('#### ')) {
        widgets.add(_buildHeading(trimmed.substring(5), 4));
      } else if (trimmed == '---' || trimmed == '***' || trimmed == '___') {
        widgets.add(pw.Divider(color: PdfColors.grey400));
        widgets.add(pw.SizedBox(height: 4));
      } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        final text = trimmed.startsWith('- ')
            ? trimmed.substring(2)
            : trimmed.substring(2);
        widgets.add(_buildBullet(text));
      } else if (RegExp(r'^\d+\. ').hasMatch(trimmed)) {
        final text = trimmed.replaceFirst(RegExp(r'^\d+\. '), '');
        widgets.add(_buildNumbered(text, widgets.length + 1));
      } else if (trimmed.startsWith('> ')) {
        widgets.add(_buildBlockquote(trimmed.substring(2)));
      } else if (trimmed.startsWith('```')) {
      } else {
        widgets.add(_buildParagraph(trimmed));
      }
    }

    return widgets;
  }

  pw.Widget _buildHeading(String text, int level) {
    final sizes = {1: 24.0, 2: 20.0, 3: 16.0, 4: 14.0};
    final colors = {
      1: PdfColors.deepPurple700,
      2: PdfColors.deepPurple500,
      3: PdfColors.deepPurple300,
      4: PdfColors.grey800,
    };
    return pw.Padding(
      padding: pw.EdgeInsets.only(top: level <= 2 ? 16 : 10, bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            text,
        style: pw.TextStyle(
              fontSize: sizes[level] ?? 14,
              fontWeight: pw.FontWeight.bold,
              color: colors[level] ?? PdfColors.black,
            ),
          ),
          if (level <= 2)
            pw.Container(
              height: 2,
              color: colors[level] ?? PdfColors.grey,
              margin: const pw.EdgeInsets.only(top: 4),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildParagraph(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 11, lineSpacing: 2),
      ),
    );
  }

  pw.Widget _buildBullet(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('• ', style: const pw.TextStyle(fontSize: 11)),
          pw.Expanded(
            child: pw.Text(text,
                style: const pw.TextStyle(fontSize: 11, lineSpacing: 2)),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildNumbered(String text, int number) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('$number. ', style: const pw.TextStyle(fontSize: 11)),
          pw.Expanded(
            child: pw.Text(text,
                style: const pw.TextStyle(fontSize: 11, lineSpacing: 2)),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildBlockquote(String text) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 6),
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(color: PdfColors.deepPurple300, width: 4),
        ),
        color: PdfColors.grey100,
      ),
      child: pw.Text(
        text,
        style: const pw.TextStyle(
          fontSize: 11,
          fontStyle: pw.FontStyle.italic,
          color: PdfColors.grey700,
        ),
      ),
    );
  }

  Future<String> _getOutputDirectory() async {
    Directory dir;
    if (Platform.isAndroid) {
      dir = await getApplicationDocumentsDirectory();
    } else if (Platform.isIOS) {
      dir = await getApplicationDocumentsDirectory();
    } else {
      dir = await getApplicationDocumentsDirectory();
    }
    final outputDir = Directory(p.join(dir.path, 'md_to_pdf_outputs'));
    if (!await outputDir.exists()) await outputDir.create(recursive: true);
    return outputDir.path;
  }
}
