import '../entities/pet.dart';

abstract interface class OfflinePetStorage {
  Future<void> deleteAll();
  Future<void> save(String ownerId, List<Pet> pets, {bool archived = false});
  Future<List<Pet>?> read(String ownerId, {bool archived = false});
}
