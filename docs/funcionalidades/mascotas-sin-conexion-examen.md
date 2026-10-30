# Guardado de mascotas sin conexión para el ítem 1

Alcance: exclusivamente el ítem 1 del examen tipo 4. En la sección Mis mascotas de la pantalla principal, «Guardar sin conexión» guarda la lista visible (activas o archivadas) en JSON de texto claro dentro del soporte privado de Android. Cada cuenta y filtro usa su propio archivo. No se guardan fotos ni URLs firmadas.

El ViewModel usa OfflinePets y el contrato OfflinePetStorage; main inyecta OfflinePetFileSource. Al fallar la consulta remota con unavailable, se lee el archivo de la cuenta y filtro actuales. Sin archivo se conserva el error remoto. Errores de acceso no habilitan la lectura local. El guardado confirma éxito mediante el toast compartido y evita envíos dobles.

## Repetición en el emulador

1. Con conexión y sesión iniciada, abrir Mis mascotas. Usar registros de prueba; para esta verificación se registró Luna_Prueba, perro mediano, 12 meses, rasgos «Pelaje pardo dato de prueba».
2. Pulsar Guardar sin conexión.
3. Desde PowerShell ejecutar (si adb no está en PATH, usar C:\Users\HP\AppData\Local\Android\Sdk\platform-tools\adb.exe):

```powershell
adb shell run-as com.example.flutter_application_entrehuellas ls files
adb shell run-as com.example.flutter_application_entrehuellas cat files/pets_MDFmMTRhNjctNjU5OS00NmZiLTkyYzYtN2JhM2U5YzY4OWE0_active.json
```

El nombre codifica el identificador de la cuenta; usar el que aparezca en ls si se prueba con otra cuenta. run-as requiere la versión de depuración y demuestra lectura desde el shell con la identidad de la app; no significa que otras apps tengan acceso normal a esa carpeta privada.

4. Activar modo avión y desactivar Wi-Fi. Cerrar completamente la app, abrirla y volver a Mis mascotas. La lista debe recuperarse del archivo al fallar la consulta remota.

Validación: flutter analyze sin incidencias; 20 pruebas existentes de arquitectura, mascotas y actualización aprobadas; APK debug compilado e instalado. Lectura real con run-as confirmó Luna_Prueba y sus campos en texto claro. La salida se conserva en output/examen-item-1/terminal.txt.

No se implementan en esta etapa AES-GCM, claves seguras, cambios de respaldo, bloqueo de capturas, borrado ni las pruebas pedidas por los ítems 4 y 5.

Verificación nativa completada: modo avión=1, Wi-Fi desactivado, force-stop y nueva apertura; Mis mascotas volvió a mostrar Luna_Prueba / Perro. Captura real: output/examen-item-1/lista-modo-avion.png; jerarquía UI: lista-modo-avion.xml. Emulador conservado en modo avión para revisión.

## Ítem 2 Cifrado con clave custodiada por Android

Este apartado sustituye el guardado en claro anterior. La evidencia del ítem 1 queda como antecedente. OfflinePetFileSource serializa en memoria y solicita AES-256-GCM mediante core/platform/android_keystore_cipher.dart; Android ejecuta el cifrado/descifrado en OfflinePetsCipher.kt con clave no exportable de AndroidKeyStore. La clave se crea al primer guardado y se reutiliza por alias; cada guardado obtiene un IV aleatorio nuevo del sistema. Se autentica también el identificador de cuenta y el filtro activas/archivadas.

El archivo conserva el nombre .json para repetir exactamente la revisión, pero contiene bytes: versión 1, IV de 12 bytes, ciphertext y etiqueta GCM de 16 bytes. Ningún temporal se escribe en claro. No se guardan ni descargan fotos. No existe lectura alternativa del archivo en claro anterior.

Cambios del ítem 2: android/app/src/main/kotlin/com/example/flutter_application_entrehuellas/OfflinePetsCipher.kt y MainActivity.kt, lib/core/platform/android_keystore_cipher.dart y lib/features/pets/data/data_sources/offline_pet_file_source.dart. [Decisión técnica](../decisiones/172-cifrado-mascotas-android-keystore.md).

Validación local: flutter analyze sin incidencias, 20 pruebas existentes aprobadas y APK debug compilado. Se desinstaló la app mediante adb uninstall y se instaló la versión cifrada; ls files confirmó que no existía el archivo anterior. Registro en output/examen-item-2/reinstalacion.txt. Después del inicio de sesión del usuario se verificó el guardado cifrado nativo, dos IV diferentes, ausencia del texto Luna_Prueba en el archivo y recuperación de Luna_Prueba / Perro tras force-stop y apertura nueva en modo avión con Wi-Fi apagado. Captura real en output/examen-item-2/lista-cifrada-modo-avion.png y salida en terminal.txt.

Para revisar después de guardar, repetir ls files y cat del ítem 1. El resultado de cat ahora es binario, no JSON legible. Para mostrarlo claramente puede usarse:

```powershell
adb shell run-as com.example.flutter_application_entrehuellas od -An -tx1 files/pets_MDFmMTRhNjctNjU5OS00NmZiLTkyYzYtN2JhM2U5YzY4OWE0_active.json
```

La comprobación de dos guardados debe mostrar IV distintos (bytes 1 a 12 después del byte de versión). Tras guardar y reiniciar la app sin red, Mis mascotas debe volver a mostrar Luna_Prueba; eso verifica que la clave persiste y la app puede autenticar y descifrar el archivo. El puente de este incremento es Android; iOS requiere su propio adaptador seguro, fuera del alcance de esta tarea.
