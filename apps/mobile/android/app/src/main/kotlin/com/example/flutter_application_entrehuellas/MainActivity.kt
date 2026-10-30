package com.example.flutter_application_entrehuellas

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val cipher = OfflinePetsCipher()
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "entrehuellas/offline_pets_cipher")
            .setMethodCallHandler { call, result ->
                if (call.method != "encrypt" && call.method != "decrypt") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    val bytes = requireNotNull(call.argument<ByteArray>("bytes"))
                    val context = requireNotNull(call.argument<String>("context"))
                    result.success(if (call.method == "encrypt") cipher.encrypt(bytes, context)
                        else cipher.decrypt(bytes, context))
                } catch (_: Exception) {
                    // Do not expose key handles, plaintext or cryptographic details to logs/UI.
                    result.error("LOCAL_CRYPTO_UNAVAILABLE", "Datos locales no disponibles", null)
                }
            }
    }
}
