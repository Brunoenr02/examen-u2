import '../../domain/entities/pet.dart';
import '../../domain/entities/offline_pet_read_result.dart';
import '../../domain/repositories/offline_pet_storage.dart';

class OfflinePetFileSource implements OfflinePetStorage {
  @override
  Future<OfflinePetReadResult> readResult(
    String ownerId, {
    bool archived = false,
  }) async => const OfflinePetReadResult(pets: []);
  @override
  Future<void> deleteAll() async =>
      throw UnsupportedError('Solo disponible en Android');
  @override
  Future<List<Pet>?> read(String ownerId, {bool archived = false}) async =>
      null;
  @override
  Future<void> save(
    String ownerId,
    List<Pet> pets, {
    bool archived = false,
  }) async {
    throw UnsupportedError('Guardado disponible en la app móvil');
  }
}
