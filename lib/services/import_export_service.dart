import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import '../data/models/password_entry.dart';
import '../data/models/note_entry.dart';

class ImportExportResult {
  final List<Map<String, dynamic>> items;
  final String format;
  final int totalCount;
  final String dataType; // 'password' or 'note'

  ImportExportResult({
    required this.items,
    required this.format,
    required this.totalCount,
    this.dataType = 'password',
  });
}

class ImportExportService {
  String _csvEncodeField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  Map<String, dynamic> _parseCsvLine(String line) {
    final fields = <String>[];
    bool inQuotes = false;
    StringBuffer current = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        fields.add(current.toString().trim());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    fields.add(current.toString().trim());

    return {
      'title': fields.isNotEmpty ? fields[0] : '',
      'username': fields.length > 1 ? fields[1] : '',
      'password': fields.length > 2 ? fields[2] : '',
      'website': fields.length > 3 ? fields[3] : '',
      'notes': fields.length > 4 ? fields.sublist(4).join(',') : '',
    };
  }

  ImportExportResult parseCsv(String csvContent) {
    final lines = csvContent.split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return ImportExportResult(items: [], format: 'csv', totalCount: 0);
    }

    final headerLine = lines[0].toLowerCase();
    final isNote = !headerLine.contains('password') && !headerLine.contains('username');
    final hasHeader = headerLine.contains('name') ||
        headerLine.contains('title') ||
        headerLine.contains('username') ||
        headerLine.contains('content');

    final dataLines = hasHeader ? lines.sublist(1) : lines;
    final items = isNote
        ? dataLines.map(_parseCsvLineNote).toList()
        : dataLines.map(_parseCsvLine).toList();

    return ImportExportResult(
      items: items,
      format: 'csv',
      totalCount: items.length,
      dataType: isNote ? 'note' : 'password',
    );
  }

  Map<String, dynamic> _parseCsvLineNote(String line) {
    final fields = <String>[];
    bool inQuotes = false;
    StringBuffer current = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        fields.add(current.toString().trim());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    fields.add(current.toString().trim());

    return {
      'title': fields.isNotEmpty ? fields[0] : '',
      'content': fields.length > 1 ? fields.sublist(1).join(',') : '',
    };
  }

  ImportExportResult parseJson(String jsonContent) {
    final decoded = jsonDecode(jsonContent);

    List<dynamic> items;
    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map && decoded.containsKey('passwords')) {
      items = decoded['passwords'] as List;
    } else if (decoded is Map && decoded.containsKey('notes')) {
      items = decoded['notes'] as List;
    } else {
      items = [];
    }

    // Detect type from content
    final isNote = items.any((item) {
      final map = item as Map<String, dynamic>;
      return map.containsKey('content') && !map.containsKey('password');
    });

    if (isNote) {
      final notes = items.map((item) {
        final map = item as Map<String, dynamic>;
        return {
          'title': map['title']?.toString() ?? '',
          'content': map['content']?.toString() ?? '',
        };
      }).toList();

      return ImportExportResult(
        items: notes,
        format: 'json',
        totalCount: notes.length,
        dataType: 'note',
      );
    }

    final passwords = items.map((item) {
      final map = item as Map<String, dynamic>;
      return {
        'title': map['title']?.toString() ?? map['name']?.toString() ?? '',
        'username': map['username']?.toString() ?? '',
        'password': map['password']?.toString() ?? '',
        'website': map['website']?.toString() ?? map['uri']?.toString() ?? map['url']?.toString() ?? '',
        'notes': map['notes']?.toString() ?? '',
      };
    }).toList();

    return ImportExportResult(
      items: passwords,
      format: 'json',
      totalCount: passwords.length,
      dataType: 'password',
    );
  }

  String generateNotesCsv(List<Note> notes) {
    final buffer = StringBuffer();
    buffer.writeln('title,content');

    for (final n in notes) {
      buffer.writeln([
        _csvEncodeField(n.title),
        _csvEncodeField(n.content),
      ].join(','));
    }

    return buffer.toString();
  }

  String generateNotesJson(List<Note> notes) {
    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'notes': notes.map((n) => {
        'title': n.title,
        'content': n.content,
      }).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  String generateCsv(List<PasswordEntry> passwords) {
    final buffer = StringBuffer();
    buffer.writeln('name,username,password,uri,notes');

    for (final p in passwords) {
      buffer.writeln([
        _csvEncodeField(p.title),
        _csvEncodeField(p.username),
        _csvEncodeField(p.password),
        _csvEncodeField(p.website),
        _csvEncodeField(p.notes),
      ].join(','));
    }

    return buffer.toString();
  }

  String generateJson(List<PasswordEntry> passwords) {
    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'passwords': passwords.map((p) => {
        'title': p.title,
        'username': p.username,
        'password': p.password,
        'website': p.website,
        'notes': p.notes,
      }).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<PlatformFile?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'json'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return null;
    return result.files.first;
  }

  String readFileContent(PlatformFile file) {
    if (file.path != null) {
      return File(file.path!).readAsStringSync();
    }
    if (file.bytes != null) {
      return utf8.decode(file.bytes!);
    }
    throw Exception('Cannot read file');
  }

  Future<void> exportAndShare(String content, String filename, String mimeType) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: mimeType)],
      sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
    );
  }
}
