import '../entities/pet.dart';
import '../entities/offline_pet_read_result.dart';

abstract interface class OfflinePetStorage {
  Future<OfflinePetReadResult> readResult(
    String ownerId, {
    bool archived = false,
  });
  Future<void> deleteAll();
  Future<void> save(String ownerId, List<Pet> pets, {bool archived = false});
  Future<List<Pet>?> read(String ownerId, {bool archived = false});
}
