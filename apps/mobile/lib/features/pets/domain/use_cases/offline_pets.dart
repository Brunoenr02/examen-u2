import '../entities/pet.dart';
import '../failures/pet_failure.dart';
import '../repositories/offline_pet_storage.dart';

class OfflinePets {
  const OfflinePets(this.storage);
  final OfflinePetStorage storage;

  Future<void> deleteAll() => storage.deleteAll();

  Future<void> save(String ownerId, List<Pet> pets, {bool archived = false}) {
    if (ownerId.isEmpty ||
        pets.any((p) => p.ownerId != ownerId || p.isArchived != archived)) {
      throw const PetFailure(PetFailureKind.forbidden);
    }
    return storage.save(ownerId, pets, archived: archived);
  }

  Future<List<Pet>?> read(String ownerId, {bool archived = false}) async {
    final pets = await storage.read(ownerId, archived: archived);
    if (ownerId.isEmpty ||
        (pets?.any((p) => p.ownerId != ownerId || p.isArchived != archived) ??
            false)) {
      throw const PetFailure(PetFailureKind.forbidden);
    }
    return pets;
  }
}
