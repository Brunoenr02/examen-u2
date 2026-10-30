import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_entrehuellas/features/pets/data/data_sources/offline_pet_file_source.dart';
import 'package:flutter_application_entrehuellas/features/pets/domain/entities/pet.dart';
import 'package:flutter_application_entrehuellas/features/pets/domain/use_cases/offline_pets.dart';
import 'support/fake_offline_pet_adapters.dart';

void main() {
  late MemoryOfflinePetFiles files;
  late FakeLocalCipher cipher;
  late OfflinePets offline;
  setUp(() {
    files = MemoryOfflinePetFiles();
    cipher = FakeLocalCipher();
    offline = OfflinePets(OfflinePetFileSource(files: files, cipher: cipher));
  });

  test('(a) El archivo guardado no contiene Cliente Prueba', () async {
    await offline.save('test-owner', [_pet('one', 'Cliente Prueba')]);
    final bytes = files.contents.values.single;
    expect(bytes, isNotEmpty);
    expect(cipher.encryptCalls, 1);
    expect(bytes, orderedEquals(cipher.lastEncrypted!));
    expect(
      utf8.decode(bytes, allowMalformed: true),
      isNot(contains('Cliente Prueba')),
    );
  });

  test(
    '(b) Tres registros guardados y leídos son iguales a los originales',
    () async {
      final original = [
        _pet('one', 'Luna Prueba'),
        _pet('two', 'Milo Prueba', species: PetSpecies.cat, sex: PetSex.female),
        Pet(
          id: 'three',
          ownerId: 'test-owner',
          version: 7,
          fields: const PetFields(
            name: 'Ave Prueba',
            species: PetSpecies.other,
            speciesDetail: 'Loro',
            size: PetSize.small,
            ageMonths: 6,
            traits: 'Plumas verdes, señal de prueba',
          ),
          caseHistoryAt: DateTime.utc(2026, 10, 1),
          activeCaseCount: 1,
        ),
      ];
      await offline.save('test-owner', original);
      // A fresh storage instance must recover from the simulated file, not a list cache.
      final reopened = OfflinePets(
        OfflinePetFileSource(files: files, cipher: cipher),
      );
      final restored = await reopened.read('test-owner');
      expect(restored, hasLength(3));
      expect(restored!.map(_snapshot), orderedEquals(original.map(_snapshot)));
      expect(cipher.decryptCalls, 1);
    },
  );

  test(
    '(c) Sin archivo guardado la lectura devuelve una lista vacía sin error',
    () async {
      expect(files.contents, isEmpty);
      final restored = await offline.read('test-owner');
      expect(restored, isEmpty);
      expect(cipher.encryptCalls, 0);
      expect(cipher.decryptCalls, 0);
    },
  );
}

Pet _pet(
  String id,
  String name, {
  PetSpecies species = PetSpecies.dog,
  PetSex sex = PetSex.male,
}) => Pet(
  id: id,
  ownerId: 'test-owner',
  version: 1,
  fields: PetFields(
    name: name,
    species: species,
    sex: sex,
    ageMonths: 12,
    size: PetSize.medium,
    traits: 'Dato de prueba',
  ),
);

// Compare values of every persisted entity field rather than object identity.
Object _snapshot(Pet p) => (
  p.id,
  p.ownerId,
  p.version,
  p.fields.name,
  p.fields.species,
  p.fields.sex,
  p.fields.ageMonths,
  p.fields.traits,
  p.fields.speciesDetail,
  p.fields.size,
  p.archivedAt,
  p.caseHistoryAt,
  p.activeCaseCount,
  p.coverUri,
);
