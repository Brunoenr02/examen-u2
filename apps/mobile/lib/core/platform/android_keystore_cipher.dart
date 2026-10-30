import 'package:flutter/services.dart';

/// Android performs AES-GCM; the non-exportable key never crosses this channel.
class AndroidKeystoreCipher {
  static const _channel = MethodChannel('entrehuellas/offline_pets_cipher');

  Future<void> deleteKey() => _channel.invokeMethod<void>('deleteKey');

  Future<Uint8List> encrypt(Uint8List bytes, String context) =>
      _invoke('encrypt', bytes, context);
  Future<Uint8List> decrypt(Uint8List bytes, String context) =>
      _invoke('decrypt', bytes, context);

  Future<Uint8List> _invoke(
    String method,
    Uint8List bytes,
    String context,
  ) async {
    final result = await _channel.invokeMethod<Uint8List>(method, {
      'bytes': bytes,
      'context': context,
    });
    if (result == null) throw StateError('Local cryptography unavailable');
    return result;
  }
}
