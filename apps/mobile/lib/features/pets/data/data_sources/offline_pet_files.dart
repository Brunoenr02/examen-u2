import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

abstract interface class OfflinePetFiles {
  Future<Uint8List?> read(String name);
  Future<void> writeAtomic(String name, Uint8List bytes);
  Future<void> deleteAll();
}

/// Private app support files. Tests substitute this adapter with memory only.
class NativeOfflinePetFiles implements OfflinePetFiles {
  NativeOfflinePetFiles({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;
  final Future<Directory> Function() _directory;

  Future<File> _file(String name) async {
    final directory = await _directory();
    await directory.create(recursive: true);
    return File('${directory.path}/$name');
  }

  @override
  Future<Uint8List?> read(String name) async {
    final file = await _file(name);
    return await file.exists() ? file.readAsBytes() : null;
  }

  @override
  Future<void> writeAtomic(String name, Uint8List bytes) async {
    final file = await _file(name);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsBytes(bytes, flush: true);
    await temporary.rename(file.path);
  }

  @override
  Future<void> deleteAll() async {
    final directory = await _directory();
    if (!await directory.exists()) return;
    final pattern = RegExp(
      r'^pets_[A-Za-z0-9_-]+_(active|archived)\.json(\.tmp)?$',
    );
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is File && pattern.hasMatch(entity.uri.pathSegments.last)) {
        await entity.delete();
      }
    }
  }
}
