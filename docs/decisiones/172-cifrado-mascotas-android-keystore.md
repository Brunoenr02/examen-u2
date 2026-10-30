# Cifrado del archivo de mascotas con Android Keystore

Estado: implementado para Android, ítem 2 del examen tipo 4. Fecha: 30/10/2026.

## Decisión

OfflinePetFileSource conserva la serialización y la carpeta privada del ítem 1, pero cifra en memoria antes de escribir. Tanto el archivo final como el temporal contienen únicamente bytes cifrados. Se mantiene el nombre .json para repetir el mismo comando de revisión, aunque su contenido ahora es binario.

core/platform/AndroidKeystoreCipher encapsula el transporte MethodChannel y no contiene reglas del producto. La fuente de datos lo consume; dominio, proveedores y presentación no dependen de Flutter services ni de Kotlin. MainActivity registra el canal y delega las operaciones a OfflinePetsCipher, sin acceso al negocio.

Android genera una clave AES de 256 bits mediante KeyGenerator con proveedor AndroidKeyStore, autorizada solo para GCM y sin padding. El alias es un nombre, no una clave. El código nunca obtiene key.encoded ni guarda material de clave en archivos, preferencias o Dart. No se afirma respaldo por hardware en el emulador.

Cada cifrado crea un Cipher nuevo y deja que Android genere el IV aleatorio de 12 bytes. Se exige cifrado aleatorizado. El formato es versión de un byte (1), IV de 12 bytes y ciphertext con etiqueta GCM de 16 bytes. El contexto autenticado vincula versión, cuenta y filtro de lista; una copia entre cuentas/filtros no puede descifrarse correctamente. La lectura usa la clave existente y no genera otra si falta.

## Alcance y consecuencias

La reinstalación limpia exigida por el examen elimina el archivo en claro y la sesión anterior. No se permite una lectura alternativa de JSON en claro. La evidencia del ítem 1 permanece en output/examen-item-1. El puente implementado corresponde a Android; no se afirma disponibilidad de este guardado cifrado en iOS.

No se modifican respaldos, capturas, recientes ni se añade borrado de archivo/clave; esas operaciones son del ítem 3. Tampoco se implementan las pruebas solicitadas por los ítems 4 y 5.

Referencia: https://developer.android.com/reference/android/security/keystore/KeyGenParameterSpec
