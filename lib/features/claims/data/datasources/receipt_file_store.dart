import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Copies picked receipt images into the app's documents directory so they
/// survive the picker's temporary cache being cleared.
class ReceiptFileStore {
  ReceiptFileStore({Future<Directory> Function()? baseDirectory})
      : _baseDirectory = baseDirectory ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _baseDirectory;

  Future<String> persist(String sourcePath, {required String claimId}) async {
    final base = await _baseDirectory();
    final dir = Directory(p.join(base.path, 'receipts'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final ext = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
    final target = File(p.join(dir.path, '$claimId$ext'));
    await File(sourcePath).copy(target.path);
    return target.path;
  }

  Future<void> delete(String path) async {
    if (path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}