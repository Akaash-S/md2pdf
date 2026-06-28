import 'dart:io';
import 'package:markdown/markdown.dart' as md;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../models/app_settings.dart';
import 'text_sanitizer.dart';

class MarkdownConverter {
  static final MarkdownConverter _instance = MarkdownConverter._internal();
  factory MarkdownConverter() => _instance;
  MarkdownConverter._internal();


  bool _nodeHasContent(md.Element elem) {
    final children = elem.children ?? [];
    if (children.isEmpty) return false;
    for (final child in children) {
      if (child is md.Text) {
        if (child.text.trim().isNotEmpty) return true;
      } else if (child is md.Element) {
        return true;
      }
    }
    return false;
  }

  Future<String> convertToPdf(
    String mdFilePath, {
    AppSettings settings = const AppSettings(),
  }) async {
    final mdFile = File(mdFilePath);
    if (!await mdFile.exists()) throw Exception('Markdown file not found');
    final markdownContent = await mdFile.readAsString();
    final normalized = markdownContent.replaceAll('\r\n', '\n').replaceAll('\r', '');
    final ast = md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
      encodeHtml: false,
    ).parseLines(normalized.split('\n'));
    final pageFormat = switch (settings.pageSize) {
      PdfPageSize.a4 => PdfPageFormat.a4,
      PdfPageSize.letter => PdfPageFormat.letter,
      PdfPageSize.a3 => PdfPageFormat.a3,
    };

    final marginValue = settings.marginValue * PdfPageFormat.mm;
    final margin = pageFormat.copyWith(
      marginLeft: marginValue,
      marginTop: marginValue,
      marginRight: marginValue,
      marginBottom: marginValue,
    );

    final baseFontSize = 11.0 * settings.fontScaleValue;

    final pdf = pw.Document(
      author: settings.pdfAuthorName.isEmpty
          ? 'MD2PDF'
          : settings.pdfAuthorName,
      creator: 'MD2PDF',
      title: p.basenameWithoutExtension(mdFilePath),
    );
    pdf.addPage(
      pw.MultiPage(
        maxPages: 500,
        pageFormat: margin,
        header: settings.showHeader ? _header(mdFilePath) : null,
        footer: settings.showFooter ? _footer() : null,
        build: (context) => _buildBlocks(ast, baseFontSize),
      ),
    );
    final outputDir = await _getOutputDirectory(settings.customOutputPath);
    final fileName = '${p.basenameWithoutExtension(mdFilePath)}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final outputPath = p.join(outputDir, fileName);
    final outputFile = File(outputPath);
    final bytes = await pdf.save();
    await outputFile.writeAsBytes(bytes);
    return outputPath;
  }

  pw.Widget Function(pw.Context) _header(String mdFilePath) =>
      (ctx) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 10),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5)),
            ),
            height: 2,
          );

  pw.Widget Function(pw.Context) _footer() =>
      (ctx) => pw.Container(
            margin: const pw.EdgeInsets.only(top: 8),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'MD2PDF',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
                pw.Text(
                  'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
              ],
            ),
          );

  List<pw.Widget> _buildBlocks(List<md.Node> nodes, double baseFontSize) {
    final widgets = <pw.Widget>[];
    for (final node in nodes) {
      if (node is md.Element) {
        if (!_nodeHasContent(node)) continue;
        switch (node.tag) {
          case 'h1': case 'h2': case 'h3': case 'h4': case 'h5': case 'h6':
            final heading = _buildHeading(node, int.parse(node.tag.substring(1)), baseFontSize);
            if (heading is! pw.SizedBox) widgets.add(heading);
            break;
          case 'p':
            widgets.add(_buildParagraph(node, baseFontSize));
            widgets.add(pw.SizedBox(height: 6));
            break;
          case 'ul':
            widgets.addAll(_buildList(node, ordered: false, base: baseFontSize));
            break;
          case 'ol':
            widgets.addAll(_buildList(node, ordered: true, base: baseFontSize));
            break;
          case 'blockquote':
            widgets.add(_buildBlockquote(node, baseFontSize));
            break;
          case 'pre':
            widgets.add(_buildCodeBlock(node, baseFontSize));
            break;
          case 'table':
            final table = _buildTable(node, baseFontSize);
            if (table is! pw.SizedBox) widgets.add(table);
            break;
          case 'hr': case 'hrule':
            widgets.add(pw.Divider(color: PdfColors.grey400));
            widgets.add(pw.SizedBox(height: 4));
            break;
        }
      }
    }
    return widgets;
  }

  pw.Widget _buildHeading(md.Element elem, int level, double base) {
    if (!_nodeHasContent(elem)) return pw.SizedBox();
    final sizes = {1: base * 2.2, 2: base * 1.7, 3: base * 1.35, 4: base * 1.15, 5: base * 1.0, 6: base * 0.9};
    final colors = {
      1: PdfColors.deepPurple700, 2: PdfColors.deepPurple500,
      3: PdfColors.deepPurple300, 4: PdfColors.grey800,
      5: PdfColors.grey700, 6: PdfColors.grey600,
    };
    final style = pw.TextStyle(
      fontSize: sizes[level] ?? base,
      fontWeight: pw.FontWeight.bold,
      color: colors[level] ?? PdfColors.black,
    );
    return pw.Padding(
      padding: pw.EdgeInsets.only(top: level <= 2 ? 14 : 10, bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildInlineWidget(elem.children ?? [], style),
          if (level <= 2)
            pw.Container(
              height: 1.5, color: colors[level] ?? PdfColors.grey,
              margin: const pw.EdgeInsets.only(top: 2),
            ),
        ],
      ),
    );
  }

  pw.Widget _buildParagraph(md.Element elem, double base) {
    final style = pw.TextStyle(fontSize: base, lineSpacing: base * 0.2);
    return _buildInlineWidget(elem.children ?? [], style);
  }

  List<pw.Widget> _buildList(md.Element elem, {required bool ordered, required double base}) {
    final widgets = <pw.Widget>[];
    int counter = 1;
    for (final child in elem.children ?? []) {
      if (child is md.Element && child.tag == 'li') {
        widgets.add(_buildListItem(child, ordered ? '$counter. ' : '* ', ordered, base));
        counter++;
      }
    }
    return widgets;
  }

  pw.Widget _buildListItem(md.Element li, String prefix, bool ordered, double base) {
    final style = pw.TextStyle(fontSize: base, lineSpacing: base * 0.2);
    List<md.Node> content = [];
    for (final child in li.children ?? []) {
      if (child is md.Element && child.tag == 'p') {
        content = child.children ?? [];
        return pw.Padding(
          padding: pw.EdgeInsets.only(left: 16, bottom: 4),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(prefix, style: style),
              pw.Flexible(child: _buildInlineWidget(content, style)),
            ],
          ),
        );
      }
    }
    return pw.Padding(
      padding: pw.EdgeInsets.only(left: 16, bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(prefix, style: style),
          pw.Flexible(child: pw.Text(_textContent(li.children ?? []), style: style)),
        ],
      ),
    );
  }

  pw.Widget _buildBlockquote(md.Element elem, double base) {
    final style = pw.TextStyle(
      fontSize: base, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700,
    );
    return pw.Container(
      margin: pw.EdgeInsets.symmetric(vertical: 6),
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(color: PdfColors.deepPurple300, width: 4),
        ),
        color: PdfColors.grey100,
      ),
      child: _buildInlineWidget(elem.children ?? [], style),
    );
  }

  pw.Widget _buildCodeBlock(md.Element elem, double base) {
    final text = _textContent(elem.children ?? []);
    return pw.Container(
      margin: pw.EdgeInsets.symmetric(vertical: 8),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: base * 0.85, font: pw.Font.courier(), lineSpacing: base * 0.25),
      ),
    );
  }

  pw.Widget _buildTable(md.Element elem, double base) {
    final rows = <pw.TableRow>[];
    bool firstRow = true;
    void addRow(md.Element tr) {
      final cells = <md.Element>[];
      for (final cell in tr.children ?? []) {
        if (cell is md.Element && (cell.tag == 'th' || cell.tag == 'td')) {
          cells.add(cell);
        }
      }
      if (cells.isEmpty) return;
      final cellStyle = pw.TextStyle(
        fontSize: base * 0.9,
        fontWeight: firstRow ? pw.FontWeight.bold : pw.FontWeight.normal,
      );
      rows.add(pw.TableRow(
        children: cells.map((c) => pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: _buildInlineWidget(c.children ?? [], cellStyle),
        )).toList(),
      ));
      firstRow = false;
    }
    for (final child in elem.children ?? []) {
      if (child is md.Element) {
        if (child.tag == 'thead' || child.tag == 'tbody') {
          for (final row in child.children ?? []) {
            if (row is md.Element && row.tag == 'tr') addRow(row);
          }
        } else if (child.tag == 'tr') {
          addRow(child);
        }
      }
    }
    if (rows.isEmpty) return pw.SizedBox();
    return pw.Container(
      margin: pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        children: rows,
      ),
    );
  }

  pw.Widget _buildInlineWidget(List<md.Node> nodes, pw.TextStyle baseStyle) {
    if (nodes.isEmpty) return pw.Text('', style: baseStyle);
    for (final node in nodes) {
      if (node is md.Element) {
        return pw.RichText(text: _buildInlineSpans(nodes, baseStyle));
      }
    }
    return pw.Text(_textContent(nodes), style: baseStyle);
  }

  pw.TextSpan _buildInlineSpans(List<md.Node> nodes, pw.TextStyle baseStyle) {
    final spans = <pw.InlineSpan>[];
    for (final node in nodes) {
      if (node is md.Text) {
        if (node.text.isNotEmpty) {
          spans.add(pw.TextSpan(text: TextSanitizer.sanitize(node.text), style: baseStyle));
        }
      } else if (node is md.Element) {
        switch (node.tag) {
          case 'strong':
            spans.add(_buildInlineSpans(node.children ?? [],
                baseStyle.copyWith(fontWeight: pw.FontWeight.bold)));
            break;
          case 'em':
            spans.add(_buildInlineSpans(node.children ?? [],
                baseStyle.copyWith(fontStyle: pw.FontStyle.italic)));
            break;
          case 'code':
            spans.add(pw.TextSpan(
              text: _textContent(node.children ?? []),
              style: baseStyle.copyWith(font: pw.Font.courier(), fontSize: baseStyle.fontSize! * 0.9),
            ));
            break;
          case 'del':
            spans.add(_buildInlineSpans(node.children ?? [], baseStyle));
            break;
          case 'a':
            spans.add(pw.TextSpan(
              text: _textContent(node.children ?? []),
              style: baseStyle.copyWith(color: PdfColors.blue),
            ));
            break;
          default:
            final child = _buildInlineSpans(node.children ?? [], baseStyle);
            if (child.children != null) spans.addAll(child.children!);
            else if (child.text != null && child.text!.isNotEmpty) spans.add(child);
        }
      }
    }
    if (spans.length == 1 && spans[0] is pw.TextSpan) {
      final ts = spans[0] as pw.TextSpan;
      if (ts.children == null || ts.children!.isEmpty) return ts;
    }
    return pw.TextSpan(children: spans);
  }

  String _textContent(List<md.Node> nodes) {
    final buf = StringBuffer();
    for (final node in nodes) {
      if (node is md.Text) buf.write(node.text);
      else if (node is md.Element) buf.write(_textContent(node.children ?? []));
    }
    return TextSanitizer.sanitize(buf.toString());
  }

  Future<String> _getOutputDirectory([String? customPath]) async {
    if (customPath != null && customPath.isNotEmpty) {
      try {
        final dir = Directory(customPath);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        return customPath;
      } catch (_) {
        // fall through to default
      }
    }
    final dir = await getApplicationDocumentsDirectory();
    final outputDir = Directory(p.join(dir.path, 'md_to_pdf_outputs'));
    if (!await outputDir.exists()) await outputDir.create(recursive: true);
    return outputDir.path;
  }
}
