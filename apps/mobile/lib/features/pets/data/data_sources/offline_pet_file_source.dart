import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/pet.dart';
import '../../domain/repositories/offline_pet_storage.dart';
import '../models/pet_dto.dart';
import '../../../../core/platform/android_keystore_cipher.dart';

/// Item 2: only an authenticated encrypted envelope is written to disk.
class OfflinePetFileSource implements OfflinePetStorage {
  OfflinePetFileSource({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;
  final Future<Directory> Function() _directory;
  final _cipher = AndroidKeystoreCipher();
  Future<void> _pending = Future.value();

  // Serialize file operations so deleting cannot race an unfinished save.
  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _pending.then((_) => action());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  @override
  Future<void> deleteAll() => _serial(() async {
    final directory = await _directory();
    if (await directory.exists()) {
      final pattern = RegExp(
        r'^pets_[A-Za-z0-9_-]+_(active|archived)\.json(\.tmp)?$',
      );
      await for (final entity in directory.list(followLinks: false)) {
        if (entity is File && pattern.hasMatch(entity.uri.pathSegments.last)) {
          await entity.delete();
        }
      }
    }
    await _cipher.deleteKey();
  });

  String _context(String ownerId, bool archived) =>
      'entrehuellas/pets/v1/$ownerId/${archived ? 'archived' : 'active'}';

  Future<File> _file(String ownerId, bool archived) async {
    final directory = await _directory();
    await directory.create(recursive: true);
    final account = base64Url.encode(utf8.encode(ownerId)).replaceAll('=', '');
    return File(
      '${directory.path}/pets_${account}_${archived ? 'archived' : 'active'}.json',
    );
  }

  @override
  Future<void> save(String ownerId, List<Pet> pets, {bool archived = false}) =>
      _serial(() async {
        final file = await _file(ownerId, archived);
        final rows = pets
            .map(
              (p) => <String, dynamic>{
                'id': p.id,
                'owner_id': p.ownerId,
                'version': p.version,
                'name': p.fields.name,
                'species': p.fields.species?.name,
                'sex': p.fields.sex?.name,
                'age_months': p.fields.ageMonths,
                'traits': p.fields.traits,
                'species_detail': p.fields.speciesDetail,
                'size': p.fields.size?.name,
                'archived_at': p.archivedAt?.toIso8601String(),
                'case_history_at': p.caseHistoryAt?.toIso8601String(),
                'active_case_count': p.activeCaseCount,
              },
            )
            .toList();
        final temporary = File('${file.path}.tmp');
        final encrypted = await _cipher.encrypt(
          Uint8List.fromList(utf8.encode(jsonEncode(rows))),
          _context(ownerId, archived),
        );
        await temporary.writeAsBytes(encrypted, flush: true);
        await temporary.rename(file.path);
      });

  @override
  Future<List<Pet>?> read(String ownerId, {bool archived = false}) =>
      _serial(() async {
        final file = await _file(ownerId, archived);
        if (!await file.exists()) return null;
        final plaintext = await _cipher.decrypt(
          await file.readAsBytes(),
          _context(ownerId, archived),
        );
        final rows = jsonDecode(utf8.decode(plaintext)) as List;
        return rows
            .map(
              (row) => PetDto.fromMap(
                Map<String, dynamic>.from(row as Map),
              ).toEntity(),
            )
            .toList();
      });
}
