import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../../domain/entities/pet.dart';
import '../../domain/entities/offline_pet_read_result.dart';
import '../../domain/repositories/offline_pet_storage.dart';
import '../models/pet_dto.dart';
import '../../../../core/platform/android_keystore_cipher.dart';
import '../../../../core/platform/local_cipher.dart';
import 'offline_pet_files.dart';

/// Item 2: only an authenticated encrypted envelope is written to disk.
class OfflinePetFileSource implements OfflinePetStorage {
  OfflinePetFileSource({
    Future<Directory> Function()? directory,
    OfflinePetFiles? files,
    LocalCipher? cipher,
  }) : _files = files ?? NativeOfflinePetFiles(directory: directory),
       _cipher = cipher ?? AndroidKeystoreCipher();
  final OfflinePetFiles _files;
  final LocalCipher _cipher;
  Future<void> _pending = Future.value();

  // Serialize file operations so deleting cannot race an unfinished save.
  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _pending.then((_) => action());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  @override
  Future<void> deleteAll() => _serial(() async {
    await _files.deleteAll();
    await _cipher.deleteKey();
  });

  String _context(String ownerId, bool archived) =>
      'entrehuellas/pets/v1/$ownerId/${archived ? 'archived' : 'active'}';

  String _fileName(String ownerId, bool archived) {
    final account = base64Url.encode(utf8.encode(ownerId)).replaceAll('=', '');
    return 'pets_${account}_${archived ? 'archived' : 'active'}.json';
  }

  @override
  Future<void> save(String ownerId, List<Pet> pets, {bool archived = false}) =>
      _serial(() async {
        final name = _fileName(ownerId, archived);
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
        final encrypted = await _cipher.encrypt(
          Uint8List.fromList(utf8.encode(jsonEncode(rows))),
          _context(ownerId, archived),
        );
        await _files.writeAtomic(name, encrypted);
      });

  @override
  Future<List<Pet>?> read(String ownerId, {bool archived = false}) async =>
      (await readResult(ownerId, archived: archived)).pets;

  @override
  Future<OfflinePetReadResult> readResult(
    String ownerId, {
    bool archived = false,
  }) => _serial(() async {
    try {
      final encrypted = await _files.read(_fileName(ownerId, archived));
      if (encrypted == null) return const OfflinePetReadResult(pets: []);
      final plaintext = await _cipher.decrypt(
        encrypted,
        _context(ownerId, archived),
      );
      final rows = jsonDecode(utf8.decode(plaintext)) as List;
      final pets = rows
          .map(
            (row) => PetDto.fromMap(
              Map<String, dynamic>.from(row as Map),
            ).toEntity(),
          )
          .toList();
      return OfflinePetReadResult(pets: pets);
    } catch (_) {
      return const OfflinePetReadResult(
        pets: [],
        message: OfflinePetReadResult.unavailableMessage,
      );
    }
  });
}
