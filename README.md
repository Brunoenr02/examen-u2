# Examen práctico de la Unidad II

**Curso:** SI-988 Soluciones Móviles II

**Tipo de examen:** 4

**Proyecto móvil:** Entre Huellas, aplicación Flutter para Android.

El desarrollo se aplica a la lista real de **Mis mascotas**. El usuario puede guardar esa lista para consultarla sin conexión, proteger su contenido y eliminar la copia local del teléfono.

## Cambios implementados

| Ítem | Cambios realizados |
| --- | --- |
| 1. Guardado sin conexión y revisión externa | Se añadió el botón **Guardar sin conexión** en Mis mascotas. La lista se guarda en soporte privado, separada por cuenta y filtro de activas/archivadas, y se recupera cuando falla la consulta al backend. En esta etapa se comprobó con `adb shell run-as` que el JSON era legible en texto claro. |
| 2. Cifrado con clave del sistema | Se sustituyó el guardado en claro por **AES-256-GCM**, con IV aleatorio nuevo en cada guardado y clave generada y custodiada en **Android Keystore**. La clave no se escribe en el código ni se exporta a Dart. Se desinstaló y reinstaló la app para eliminar el archivo anterior; se verificaron contenido cifrado y consulta sin conexión después de reiniciar. |
| 3. Respaldo, pantalla y borrado | Se deshabilitó el respaldo y se añadieron exclusiones para nube y transferencia entre dispositivos. Mis mascotas activa **FLAG_SECURE** antes de mostrar la lista; Android 13 o superior también deshabilita la miniatura de recientes. En Perfil se añadió **Borrar datos de este teléfono**, que elimina las copias locales de mascotas, sus temporales y la clave de instalación. El borrado se confirma únicamente tras completar ambas operaciones. |
| 4. Tres pruebas del guardado | Se incorporaron adaptadores simulados de archivo y cifrado. Las pruebas comprueban que el archivo no contenga **Cliente Prueba**, que tres registros se recuperen iguales y que la lectura sin archivo devuelva una lista vacía sin error. |
| 5. Dos pruebas de archivo dañado y borrado | Se añadió un resultado de lectura con lista y mensaje. Un fallo de lectura, descifrado o formato devuelve una lista vacía con **Datos locales no disponibles, conéctese para actualizar**. Las pruebas alteran un archivo simulado y verifican la recuperación sin excepción; también comprueban que el borrado elimine su contenido y la clave simulada. |

El estado final guarda únicamente el archivo cifrado. El nombre conserva la extensión `.json`, pero su contenido es binario. Las evidencias del archivo en claro corresponden a la etapa inicial del ítem 1. El borrado afecta la copia sin conexión del examen y su clave; las mascotas del servidor y la cuenta se conservan.

## Archivos del proyecto móvil afectados

Todas las rutas siguientes son relativas a `apps/mobile/`.

### Android

| Archivo | Cambio |
| --- | --- |
| `android/app/src/main/AndroidManifest.xml` | Deshabilita respaldo y referencia las reglas de extracción. |
| `android/app/src/main/res/xml/backup_rules.xml` | Excluye los datos del respaldo en Android 11 o anterior. |
| `android/app/src/main/res/xml/data_extraction_rules.xml` | Excluye datos de nube y transferencia entre dispositivos en Android 12 o posterior. |
| `android/app/src/main/kotlin/com/example/flutter_application_entrehuellas/MainActivity.kt` | Registra los canales nativos de cifrado, borrado de clave y protección de pantalla; deshabilita miniaturas de recientes en Android 13 o superior. |
| `android/app/src/main/kotlin/com/example/flutter_application_entrehuellas/OfflinePetsCipher.kt` | Genera/consulta la clave en Android Keystore, cifra y descifra con AES-GCM, genera el IV y elimina la clave. |

### Aplicación Flutter

| Archivo | Cambio |
| --- | --- |
| `lib/main.dart` | Inyecta el almacenamiento local en la aplicación. |
| `lib/core/platform/local_cipher.dart` | Define el contrato sustituible de cifrado, descifrado y borrado de clave. |
| `lib/core/platform/android_keystore_cipher.dart` | Conecta Dart con el cifrado y borrado nativos sin recibir el material de la clave. |
| `lib/core/presentation/widgets/secure_screen.dart` | Espera la confirmación de protección antes de mostrar la lista y oculta su contenido al abrir otra ruta. |
| `lib/features/home/presentation/screens/home_screen.dart` | Aplica la protección a Mis mascotas. |
| `lib/features/pets/providers/pet_providers.dart` | Declara el almacenamiento local y su caso de uso. |
| `lib/features/pets/domain/repositories/offline_pet_storage.dart` | Define las operaciones de guardado, lectura y borrado local. |
| `lib/features/pets/domain/use_cases/offline_pets.dart` | Expone las operaciones locales y valida cuenta y filtro de los registros recuperados. |
| `lib/features/pets/domain/entities/offline_pet_read_result.dart` | Contiene la lista recuperada y el mensaje opcional de datos locales no disponibles. |
| `lib/features/pets/data/data_sources/offline_pet_file_source.dart` | Serializa y recupera mascotas, coordina cifrado y archivo, serializa operaciones y devuelve un resultado recuperable ante corrupción. |
| `lib/features/pets/data/data_sources/offline_pet_files.dart` | Implementa archivos privados, escritura temporal y reemplazo del archivo cifrado; elimina archivos y temporales. |
| `lib/features/pets/data/data_sources/offline_pet_file_source_stub.dart` | Conserva el adaptador para destinos sin acceso nativo al archivo. |
| `lib/features/pets/presentation/view_models/pet_list_view_model.dart` | Guarda la lista visible y usa la copia local cuando falla el backend; comunica el mensaje de recuperación. |
| `lib/features/pets/presentation/widgets/pets_section.dart` | Añade el botón de guardado y los avisos de resultado/error. |
| `lib/features/profile/presentation/view_models/local_data_deletion_view_model.dart` | Ejecuta el borrado, controla su estado e invalida la lista retenida. |
| `lib/features/profile/presentation/screens/profile_screen.dart` | Añade el botón de borrado y su confirmación fuera de la pantalla protegida. |

### Pruebas

| Archivo | Cambio |
| --- | --- |
| `test/support/fake_offline_pet_adapters.dart` | Simula archivo y cifrado en memoria, incluido el estado de la clave y su eliminación. |
| `test/offline_pet_storage_test.dart` | Contiene las tres pruebas unitarias del ítem 4. |
| `test/offline_pet_recovery_test.dart` | Contiene las dos pruebas unitarias del ítem 5. |
| `test/secure_screen_test.dart` | Verifica la espera de protección, la navegación y la ocultación de datos si falla el canal. |

## Ejecución de las pruebas del examen

Desde la raíz del repositorio, abrir PowerShell y ejecutar:

```powershell
cd apps/mobile

# Ítem 4: tres pruebas
flutter test --no-pub --reporter expanded test/offline_pet_storage_test.dart

# Ítem 5: dos pruebas
flutter test --no-pub --reporter expanded test/offline_pet_recovery_test.dart
```

**Resultados obtenidos:** ítem 4, `+3: All tests passed!`; ítem 5, `+2: All tests passed!`. Las pruebas usan la fuente real de almacenamiento con reemplazos de archivo y cifrado en memoria; no necesitan emulador, internet ni datos reales. El cifrado simulado no es un algoritmo de seguridad y no se usa en producción.

El análisis con `flutter analyze --no-pub` finalizó sin incidencias. La suite seleccionada de almacenamiento, recuperación, arquitectura, mascotas y protección completó 27 pruebas aprobadas. Las verificaciones nativas de los ítems 1 a 3 se realizaron en el emulador Android. La configuración de respaldo se comprobó en el paquete instalado; no se ejecutó una restauración en otro dispositivo.
