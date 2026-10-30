import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_entrehuellas/features/pets/data/data_sources/offline_pet_file_source.dart';
import 'package:flutter_application_entrehuellas/features/pets/domain/entities/pet.dart';
import 'package:flutter_application_entrehuellas/features/pets/domain/use_cases/offline_pets.dart';
import 'support/fake_offline_pet_adapters.dart';

void main() {
  late MemoryOfflinePetFiles files;
  late FakeLocalCipher cipher;
  late OfflinePets offline;
  const pet = Pet(
    id: 'one',
    ownerId: 'test-owner',
    version: 1,
    fields: PetFields(
      name: 'Cliente Prueba',
      species: PetSpecies.dog,
      size: PetSize.medium,
      ageMonths: 12,
      traits: 'Dato de prueba',
    ),
  );
  setUp(() {
    files = MemoryOfflinePetFiles();
    cipher = FakeLocalCipher();
    offline = OfflinePets(OfflinePetFileSource(files: files, cipher: cipher));
  });

  test(
    '(a) Archivo alterado devuelve lista vacía y mensaje sin lanzar error',
    () async {
      await offline.save('test-owner', [pet]);
      final name = files.contents.keys.single;
      // Corrupt an actual saved token so the fake decryption operation fails.
      final damaged = Uint8List.fromList(files.contents[name]!);
      damaged[0] ^= 1;
      files.contents[name] = damaged;

      final result = await offline.readResult('test-owner');
      expect(cipher.decryptCalls, 1);
      expect(result.pets, isEmpty);
      expect(
        result.message,
        'Datos locales no disponibles, conéctese para actualizar',
      );
      // The legacy list API is also safe after the same failed decryption.
      expect(await offline.read('test-owner'), isEmpty);
    },
  );

  test('(b) Borrar elimina el contenido del archivo y la clave', () async {
    await offline.save('test-owner', [pet]);
    final encryptedBeforeDeletion = Uint8List.fromList(
      files.contents.values.single,
    );
    expect(files.contents.values.single, isNotEmpty);
    expect(cipher.keyExists, isTrue);

    await offline.deleteAll();

    expect(files.contents, isEmpty);
    expect(cipher.keyExists, isFalse);
    expect(cipher.deleteKeyCalls, 1);
    // The formerly valid bytes can no longer be decrypted by the fake keystore.
    await expectLater(
      cipher.decrypt(
        encryptedBeforeDeletion,
        'entrehuellas/pets/v1/test-owner/active',
      ),
      throwsStateError,
    );
    final result = await offline.readResult('test-owner');
    expect(result.pets, isEmpty);
    expect(result.message, isNull);
  });
}
