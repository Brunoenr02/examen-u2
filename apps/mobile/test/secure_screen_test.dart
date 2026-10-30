import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_entrehuellas/core/presentation/widgets/secure_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('entrehuellas/screen_privacy');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets(
    'Sensitive content waits for protection; Profile releases it and return restores it',
    (tester) async {
      final acknowledgement = Completer<void>();
      final requests = <bool>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            final enabled = (call.arguments as Map)['enabled'] as bool;
            requests.add(enabled);
            if (requests.length == 1) await acknowledgement.future;
            return null;
          });
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: const Scaffold(body: SecureScreen(child: Text('Private list'))),
        ),
      );
      expect(find.text('Private list'), findsNothing);
      acknowledgement.complete();
      await tester.pumpAndSettle();
      expect(find.text('Private list'), findsOneWidget);
      unawaited(
        navigator.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Profile')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(requests.last, false);
      expect(find.text('Private list', skipOffstage: false), findsNothing);
      expect(find.text('Profile'), findsOneWidget);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(requests.last, true);
      expect(find.text('Private list'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(requests.last, false);
    },
  );

  testWidgets('Failed protection never reveals the list', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (_) async => throw PlatformException(code: 'unavailable'),
        );
    await tester.pumpWidget(
      const MaterialApp(home: SecureScreen(child: Text('Private list'))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Private list'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
