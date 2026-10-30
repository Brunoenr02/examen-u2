import 'dart:typed_data';

/// Byte operations supplied by the system keystore adapter in production.
abstract interface class LocalCipher {
  Future<Uint8List> encrypt(Uint8List bytes, String context);
  Future<Uint8List> decrypt(Uint8List bytes, String context);
  Future<void> deleteKey();
}
