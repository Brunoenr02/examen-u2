# Adaptadores sustituibles del guardado sin conexión

Fecha: 30/10/2026. Alcance: ítem 4 del examen tipo 4.

OfflinePetFileSource conserva la serialización, los nombres por cuenta/filtro y la cola que serializa lecturas, guardados y borrados. Recibe dos dependencias opcionales: OfflinePetFiles y LocalCipher. Por defecto usa NativeOfflinePetFiles (soporte privado, escritura temporal cifrada y rename) y AndroidKeystoreCipher (AES-GCM/AndroidKeyStore del ítem 2). Main no necesita cambiar su composición. El contrato de cifrado solo depende de bytes Dart; no introduce dependencias de Flutter en dominio ni usa los simulados en producción.

La lectura de un archivo inexistente devuelve ahora una lista vacía sin error, como exige el ítem 4. Antes devolvía null. En la app, ante fallo remoto y ausencia de copia, esta fuente ofrece una lista vacía; no acredita una consulta remota exitosa. No cambia el tratamiento de un archivo alterado: corresponde al ítem 5.

Las pruebas inyectan MemoryOfflinePetFiles y FakeLocalCipher. El primero mantiene copias de bytes en un mapa; el segundo reemplaza cifrado/descifrado con tokens opacos asociados a bytes y contexto en memoria. Es una simulación explícita, no un algoritmo criptográfico ni una validación de la seguridad de AES. No usa emulador, AndroidKeyStore, MethodChannel, path_provider, disco real, backend o red.

Tres pruebas ejecutan OfflinePets con OfflinePetFileSource real:

1. Guarda Cliente Prueba; comprueba que se llamó al cifrado, que se escribieron los bytes devueltos y que el archivo no está vacío ni contiene el nombre en claro.
2. Guarda tres mascotas con campos distintos y abre una nueva instancia del almacenamiento. Verifica cantidad, orden y valores de todos los campos de las entidades del ejemplo tras la lectura/descifrado.
3. Sin archivo, devuelve lista vacía y no intenta descifrar.

Validación: tres pruebas aprobadas con flutter test --no-pub --reporter expanded test/offline_pet_storage_test.dart. Análisis sin incidencias y suite seleccionada de arquitectura, mascotas, protección y estas pruebas: 25 aprobadas. No se implementan las dos pruebas del ítem 5 ni se cambian pantallas, backend o el estado del emulador en esta tarea.
