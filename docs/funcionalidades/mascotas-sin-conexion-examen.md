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

## Ítem 3 Respaldo pantalla y borrado

Implementado para Android según [ADR-173](../decisiones/173-proteccion-y-borrado-copia-local-mascotas.md). Las evidencias de los ítems 1 y 2 están preservadas. AndroidManifest declara allowBackup=false; backup_rules.xml y data_extraction_rules.xml excluyen todos los dominios de datos tanto del respaldo como de la transferencia entre dispositivos.

La sección Mis mascotas usa SecureScreen y el canal entrehuellas/screen_privacy para activar FLAG_SECURE antes de mostrar la lista. Al abrir Perfil la lista se oculta y se libera la bandera; al regresar se vuelve a proteger. Android 13+ deshabilita además las miniaturas de recientes para la actividad. El botón Borrar datos de este teléfono en Perfil elimina los JSON de mascotas (activas, archivadas y temporales de todas las cuentas) y el alias de AndroidKeyStore. La clave es de instalación. No borra mascotas del servidor, sesión ni borradores de reportes.

Para repetir: con conexión cargar la lista y pulsar Guardar sin conexión; activar modo avión, apagar Wi-Fi y verificar la consulta local. Intentar una captura: sale negra. Abrir recientes y capturar la tarjeta negra. Volver y abrir Perfil; pulsar Borrar datos de este teléfono y capturar la confirmación. Repetir ls files y cat del ítem 1: el archivo no debe aparecer y cat devuelve No such file or directory. El borrado fue ejecutado durante la validación; el emulador quedó en Perfil y sin esa copia local.

Archivos para capturar el código: AndroidManifest.xml, res/xml/backup_rules.xml, res/xml/data_extraction_rules.xml, MainActivity.kt (FLAG_SECURE y recientes), lib/core/presentation/widgets/secure_screen.dart (protección antes de mostrar), OfflinePetsCipher.kt (deleteKey), offline_pet_file_source.dart (deleteAll) y el ViewModel local_data_deletion_view_model.dart de Perfil.

Validación: flutter analyze sin incidencias; 22 pruebas aprobadas, incluyendo dos regresiones de protección; APK debug compilado e instalado. En el paquete instalado ALLOW_BACKUP está ausente; no se ejecutó una restauración en otro dispositivo. Captura directa negra y tarjeta negra de recientes comprobadas. Perfil capturable y borrado real confirmado: archivo ausente, clave eliminada con containsAlias=false antes del éxito nativo. Evidencias reales: output/examen-item-3/recientes-protegidos.png, lista-protegida.png, perfil-datos-borrados.png y terminal-borrado.txt. No se implementan los ítems 4 y 5.

Límite de validación adicional: una ejecución de profile_overview_test, profile_navigation_test y home_test terminó con 8 casos aprobados y 5 timeouts de pumpAndSettle en el arranque inicial de Inicio, antes de entrar a mascotas/perfil. Se conserva ese resultado como pendiente de navegación, sin cambiar las animaciones generales fuera del ítem 3.

## Ítem 4 Tres pruebas unitarias del guardado

Implementado según [ADR-174](../decisiones/174-adaptadores-pruebas-guardado-local.md). El guardado real recibe contratos LocalCipher y OfflinePetFiles. En producción conserva AndroidKeystoreCipher y NativeOfflinePetFiles; las pruebas inyectan versiones en memoria. La ausencia de archivo devuelve ahora lista vacía, en lugar de null, para cumplir el caso (c). Esto también aplica al fallback de la lista en la app si no existe copia; los errores de descifrado quedan para el ítem 5.

Pruebas: apps/mobile/test/offline_pet_storage_test.dart. Simulados: apps/mobile/test/support/fake_offline_pet_adapters.dart. El cifrado simulado usa tokens opacos asociados al original en memoria; no es cifrado real y nunca se usa en la app. El archivo simulado almacena copias de bytes en un mapa, sin crear archivos de dispositivo ni del equipo.

(a) Cliente Prueba no aparece en el contenido guardado; se comprueba además que el archivo contiene los bytes obtenidos del cifrado. (b) Tres mascotas se guardan, se reabre el almacenamiento y se recuperan con el mismo orden y valores. (c) Sin archivo guardado, devuelve una lista vacía sin error ni llamadas al descifrado.

En PowerShell, sin emulador ni conexión:

```powershell
cd C:\QWERTY\entrehuellas\apps\mobile
flutter test --no-pub --reporter expanded test/offline_pet_storage_test.dart
```

Resultado ejecutado: +3: All tests passed! Salida real conservada en output/examen-item-4/pruebas-terminal.txt. Para evidencia de terminal, ejecutar el comando y capturar el comando y los tres casos aprobados. Para evidencia de código, abrir el archivo de pruebas y el de simulados en el editor y capturar sus bloques legibles.

Validación adicional: flutter analyze sin incidencias; 25 pruebas seleccionadas aprobadas (estas tres más arquitectura, mascotas, actualización y protección). No se modifica el estado del emulador ni se implementa el ítem 5.
