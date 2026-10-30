import '../../domain/entities/pet.dart';
import '../../domain/repositories/offline_pet_storage.dart';

class OfflinePetFileSource implements OfflinePetStorage {
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
