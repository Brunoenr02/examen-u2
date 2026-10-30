package com.example.flutter_application_entrehuellas

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/** Key material stays in AndroidKeyStore. Only IV + ciphertext + tag leave here. */
class OfflinePetsCipher {
    private val alias = "entrehuellas.offline.pets.v1"
    private val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }

    private fun existingKey(): SecretKey? = keyStore.getKey(alias, null) as? SecretKey

    private fun encryptionKey(): SecretKey = existingKey() ?: KeyGenerator.getInstance(
        KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore"
    ).apply {
        init(KeyGenParameterSpec.Builder(
            alias, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
        ).setKeySize(256)
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .setRandomizedEncryptionRequired(true)
            .build())
    }.generateKey()

    @Synchronized
    fun encrypt(plaintext: ByteArray, context: String): ByteArray {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        // Android generates a fresh random IV; never supply a fixed IV here.
        cipher.init(Cipher.ENCRYPT_MODE, encryptionKey())
        cipher.updateAAD(context.toByteArray(Charsets.UTF_8))
        val ciphertextAndTag = cipher.doFinal(plaintext)
        check(cipher.iv.size == 12)
        return byteArrayOf(1) + cipher.iv + ciphertextAndTag
    }

    @Synchronized
    fun decrypt(envelope: ByteArray, context: String): ByteArray {
        require(envelope.size >= 29 && envelope[0] == 1.toByte())
        // Missing keys must not be replaced while trying to read old data.
        val key = checkNotNull(existingKey()) { "Local key unavailable" }
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(128, envelope.copyOfRange(1, 13)))
        cipher.updateAAD(context.toByteArray(Charsets.UTF_8))
        return cipher.doFinal(envelope.copyOfRange(13, envelope.size))
    }
}
