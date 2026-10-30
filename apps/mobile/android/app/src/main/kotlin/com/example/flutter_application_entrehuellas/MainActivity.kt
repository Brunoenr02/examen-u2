package com.example.flutter_application_entrehuellas

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Build
import android.view.WindowManager

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val cipher = OfflinePetsCipher()
        // Recent tasks never receive an app snapshot, even on unprotected routes.
        if (Build.VERSION.SDK_INT >= 33) setRecentsScreenshotEnabled(false)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "entrehuellas/screen_privacy")
            .setMethodCallHandler { call, result ->
                if (call.method != "setSecure") {
                    result.notImplemented()
                } else {
                    if (call.argument<Boolean>("enabled") == true) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "entrehuellas/offline_pets_cipher")
            .setMethodCallHandler { call, result ->
                if (call.method == "deleteKey") {
                    try {
                        cipher.deleteKey()
                        result.success(null)
                    } catch (_: Exception) {
                        result.error("LOCAL_DELETE_FAILED", "No se pudo borrar la clave local", null)
                    }
                    return@setMethodCallHandler
                }
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
