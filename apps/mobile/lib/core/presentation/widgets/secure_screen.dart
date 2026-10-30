import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Render sensitive content only after Android acknowledges FLAG_SECURE.
/// Hide the underlying content while another route (such as Profile) is on top.
class SecureScreen extends StatefulWidget {
  const SecureScreen({required this.child, super.key});
  final Widget child;
  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> {
  static const _channel = MethodChannel('entrehuellas/screen_privacy');
  bool? _requested;
  bool _ready = false;
  int _generation = 0;
  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void _sync(bool enabled) {
    if (!_android || _requested == enabled) return;
    _requested = enabled;
    _ready = false;
    final generation = ++_generation;
    _channel
        .invokeMethod<void>('setSecure', {'enabled': enabled})
        .then(
          (_) {
            if (mounted && generation == _generation) {
              setState(() => _ready = enabled);
            }
          },
          onError: (Object _) {
            // Fail closed: do not display sensitive data if protection failed.
          },
        );
  }

  @override
  void dispose() {
    _generation++;
    if (_android) {
      _channel
          .invokeMethod<void>('setSecure', {'enabled': false})
          .catchError((Object _) {});
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = ModalRoute.isCurrentOf(context) ?? true;
    _sync(current);
    if (!_android) return widget.child;
    return current && _ready ? widget.child : const SizedBox.shrink();
  }
}
