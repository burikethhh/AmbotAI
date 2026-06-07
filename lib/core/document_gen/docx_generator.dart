import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import '../storage/output_storage_service.dart';

class DocxGenerator {
  static Future<String> generateDocx({
    required String title,
    required String content,
  }) async {
    final filePath = await OutputStorageService.instance
        .generatePath(OutputType.documents, 'docx');
    final documentXml = _buildDocumentXml(title, content);

    final archive = Archive();
    archive.addFile(ArchiveFile(
      '[Content_Types].xml',
      _contentTypesXml.length,
      utf8.encode(_contentTypesXml),
    ));
    archive.addFile(ArchiveFile(
      '_rels/.rels',
      _relsXml.length,
      utf8.encode(_relsXml),
    ));
    archive.addFile(ArchiveFile(
      'word/_rels/document.xml.rels',
      _docRelsXml.length,
      utf8.encode(_docRelsXml),
    ));
    archive.addFile(ArchiveFile(
      'word/document.xml',
      documentXml.length,
      utf8.encode(documentXml),
    ));

    final zipBytes = ZipEncoder().encode(archive);
    final file = File(filePath);
    await file.writeAsBytes(zipBytes);
    return filePath;
  }

  static const String _contentTypesXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\n'
      '  <Default Extension="rels" '
      'ContentType="application/vnd.openxmlformats-package.relationships+xml"/>\n'
      '  <Default Extension="xml" ContentType="application/xml"/>\n'
      '  <Override PartName="/word/document.xml" '
      'ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>\n'
      '</Types>';

  static const String _relsXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
      '  <Relationship Id="rId1" '
      'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" '
      'Target="word/document.xml"/>\n'
      '</Relationships>';

  static const String _docRelsXml =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"/>\n';

  static String _buildDocumentXml(String title, String content) {
    final body = StringBuffer();
    body.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    body.writeln(
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">');
    body.writeln('<w:body>');

    // Title paragraph
    body.writeln('<w:p>');
    body.writeln('<w:pPr><w:jc w:val="center"/></w:pPr>');
    body.writeln(
        '<w:r><w:rPr><w:b/><w:sz w:val="32"/></w:rPr><w:t>${_escapeXml(title)}</w:t></w:r>');
    body.writeln('</w:p>');
    body.writeln('<w:p><w:pPr><w:spacing w:after="200"/></w:pPr></w:p>');

    // Process content line by line
    final lines = content.split('\n');
    for (final rawLine in lines) {
      final trimmed = rawLine.trimLeft();

      if (trimmed.isEmpty) {
        body.writeln('<w:p><w:pPr><w:spacing w:after="120"/></w:pPr></w:p>');
        continue;
      }

      if (trimmed.startsWith('### ')) {
        _writeParagraph(body, trimmed.substring(4), bold: true, fontSize: 24);
      } else if (trimmed.startsWith('## ')) {
        _writeParagraph(body, trimmed.substring(3), bold: true, fontSize: 28);
      } else if (trimmed.startsWith('# ')) {
        _writeParagraph(body, trimmed.substring(2), bold: true, fontSize: 32);
      } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        _writeParagraph(body, '• ${trimmed.substring(2)}', indent: true);
      } else if (RegExp(r'^\d+[.)] ').hasMatch(trimmed)) {
        _writeParagraph(body, trimmed, indent: true);
      } else {
        _writeParagraph(body, rawLine);
      }
    }

    body.writeln('</w:body>');
    body.writeln('</w:document>');
    return body.toString();
  }

  static void _writeParagraph(
    StringBuffer body,
    String text, {
    bool bold = false,
    int fontSize = 22,
    bool indent = false,
  }) {
    body.write('<w:p>');
    body.write('<w:pPr>');
    if (indent) {
      body.write('<w:ind w:left="720"/>');
    }
    body.write('</w:pPr>');
    _writeFormattedRun(body, text, bold: bold, fontSize: fontSize);
    body.writeln('</w:p>');
  }

  static void _writeFormattedRun(
    StringBuffer body,
    String text, {
    bool bold = false,
    int fontSize = 22,
  }) {
    final regex = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|<u>(.+?)</u>');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        _writeRun(body, text.substring(lastEnd, match.start),
            bold: bold, fontSize: fontSize);
      }

      if (match.group(1) != null) {
        _writeRun(body, match.group(1)!, bold: true, fontSize: fontSize);
      } else if (match.group(2) != null) {
        _writeRun(body, match.group(2)!, italic: true, fontSize: fontSize);
      } else if (match.group(3) != null) {
        _writeRun(body, match.group(3)!,
            underline: true, fontSize: fontSize);
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      _writeRun(body, text.substring(lastEnd),
          bold: bold, fontSize: fontSize);
    }
  }

  static void _writeRun(
    StringBuffer body,
    String text, {
    bool bold = false,
    bool italic = false,
    bool underline = false,
    int fontSize = 22,
  }) {
    if (text.isEmpty) return;
    body.write('<w:r><w:rPr>');
    if (bold) body.write('<w:b/>');
    if (italic) body.write('<w:i/>');
    if (underline) body.write('<w:u w:val="single"/>');
    body.write('<w:sz w:val="$fontSize"/>');
    body.write('</w:rPr><w:t xml:space="preserve">${_escapeXml(text)}</w:t></w:r>');
  }

  static String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
