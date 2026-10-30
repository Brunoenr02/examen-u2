import 'dart:typed_data';
import 'package:flutter_application_entrehuellas/core/platform/local_cipher.dart';
import 'package:flutter_application_entrehuellas/features/pets/data/data_sources/offline_pet_files.dart';

/// Test file system: copies bytes in memory; never uses disk or path_provider.
class MemoryOfflinePetFiles implements OfflinePetFiles {
  final contents = <String, Uint8List>{};
  @override
  Future<void> writeAtomic(String name, Uint8List bytes) async {
    contents[name] = Uint8List.fromList(bytes);
  }

  @override
  Future<Uint8List?> read(String name) async {
    final bytes = contents[name];
    return bytes == null ? null : Uint8List.fromList(bytes);
  }

  @override
  Future<void> deleteAll() async => contents.clear();
}

/// Simulation only, NOT cryptography: opaque tokens refer to bytes in memory.
/// Real AES-GCM and AndroidKeyStore remain in the production native adapter.
class FakeLocalCipher implements LocalCipher {
  final _values = <String, ({Uint8List plaintext, String context})>{};
  int encryptCalls = 0;
  int decryptCalls = 0;
  Uint8List? lastEncrypted;

  @override
  Future<Uint8List> encrypt(Uint8List bytes, String context) async {
    final token = Uint8List.fromList([0xff, ++encryptCalls]);
    _values[token.join(',')] = (
      plaintext: Uint8List.fromList(bytes),
      context: context,
    );
    lastEncrypted = token;
    return Uint8List.fromList(token);
  }

  @override
  Future<Uint8List> decrypt(Uint8List bytes, String context) async {
    decryptCalls++;
    final value = _values[bytes.join(',')];
    if (value == null || value.context != context) {
      throw StateError('Unknown test token or context');
    }
    return Uint8List.fromList(value.plaintext);
  }

  @override
  Future<void> deleteKey() async => _values.clear();
}
