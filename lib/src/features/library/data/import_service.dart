import 'dart:io';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../common/database/app_database.dart';
import '../../common/database/tables.dart';

enum DocumentFileType { pdf, epub, markdown, html, txt, unknown }

class ImportService {
  final AppDatabase _db;
  static const _uuid = Uuid();

  ImportService(this._db);

  DocumentFileType detectFileType(String path) {
    final ext = p.extension(path).toLowerCase();
    switch (ext) {
      case '.pdf':
        return DocumentFileType.pdf;
      case '.epub':
        return DocumentFileType.epub;
      case '.md':
      case '.markdown':
        return DocumentFileType.markdown;
      case '.html':
      case '.htm':
        return DocumentFileType.html;
      case '.txt':
        return DocumentFileType.txt;
      default:
        return DocumentFileType.unknown;
    }
  }

  String fileTypeToString(DocumentFileType type) {
    switch (type) {
      case DocumentFileType.pdf:
        return 'pdf';
      case DocumentFileType.epub:
        return 'epub';
      case DocumentFileType.markdown:
        return 'md';
      case DocumentFileType.html:
        return 'html';
      case DocumentFileType.txt:
        return 'txt';
      case DocumentFileType.unknown:
        return 'unknown';
    }
  }

  Future<int> importDocument(String sourcePath) async {
    final fileType = detectFileType(sourcePath);
    if (fileType == DocumentFileType.unknown) {
      throw UnsupportedError('Unsupported file type: $sourcePath');
    }

    final appDir = await getApplicationDocumentsDirectory();
    final papersDir = Directory(p.join(appDir.path, 'papers'));
    if (!await papersDir.exists()) {
      await papersDir.create(recursive: true);
    }

    final fileName = p.basename(sourcePath);
    final uniqueName = '${_uuid.v4()}_$fileName';
    final destPath = p.join(papersDir.path, uniqueName);

    await File(sourcePath).copy(destPath);

    final title = _extractTitle(fileName);

    final documentId = await _db.into(_db.documents).insert(
          DocumentsCompanion(
            title: Value(title),
            filePath: Value(destPath),
            fileType: Value(fileTypeToString(fileType)),
            importDate: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );

    return documentId;
  }

  Future<List<int>> importMultipleDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'epub', 'md', 'markdown', 'html', 'htm', 'txt'],
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) return [];

    final ids = <int>[];
    for (final file in result.files) {
      if (file.path != null) {
        final id = await importDocument(file.path!);
        ids.add(id);
      }
    }
    return ids;
  }

  String _extractTitle(String fileName) {
    return p.basenameWithoutExtension(fileName);
  }
}
