# Lectura local recuperable ante archivo alterado

Fecha: 30/10/2026. Alcance: ítem 5 del examen tipo 4.

Se añade OfflinePetReadResult con lista y mensaje opcional. OfflinePetStorage y OfflinePets ofrecen readResult, manteniendo read para los consumidores que solo necesitan la lista. La fuente real captura fallos de lectura, descifrado, autenticación y formato, y devuelve una lista vacía con «Datos locales no disponibles, conéctese para actualizar». No elimina el archivo dañado automáticamente, no genera una clave al leer y no devuelve datos parciales. El caso de uso conserva la validación de cuenta y filtro; esos fallos no se convierten en autorización local.

El ViewModel de la lista obtiene el resultado detallado cuando falla la consulta remota. Conserva el mensaje en el aviso de presentación y la pantalla lo muestra mediante el toast superior existente con acción de actualizar. La lista vacía sin archivo no lleva aviso; un fallo al guardar o borrar sigue siendo un error, no un éxito simulado.

FakeLocalCipher incorpora el estado explícito keyExists y el contador deleteKeyCalls. Al guardar existe la clave simulada; al borrarla se elimina ese estado y también la asociación entre tokens y texto. Es un reemplazo en memoria para pruebas, no criptografía real. MemoryOfflinePetFiles elimina sus entradas al borrar, de modo que el archivo queda sin contenido al desaparecer.

Las dos pruebas de offline_pet_recovery_test.dart usan el caso de uso y la fuente reales con ambos adaptadores simulados:

1. Guarda un registro válido y altera un byte de su archivo simulado. El descifrado falla, pero readResult finaliza sin excepción, devuelve lista vacía y el mensaje literal exigido. También read devuelve lista vacía.
2. Guarda un registro y verifica datos/clave presentes. Ejecuta deleteAll y comprueba archivo ausente/sin contenido, keyExists=false y una llamada a deleteKey. El token anterior ya no puede descifrarse y una lectura posterior devuelve lista vacía sin mensaje de corrupción.

Validación: flutter test --no-pub --reporter expanded test/offline_pet_recovery_test.dart, +2 All tests passed. Flutter analyze sin incidencias; 27 pruebas seleccionadas aprobadas, incluidas las tres del ítem 4. Evidencia textual real en output/examen-item-5/pruebas-terminal.txt. No se necesita ni se modifica emulador, archivos reales, clave real, cuenta ni backend para estas pruebas. No se afirma validación nueva de un archivo alterado en Android: este ítem solicita pruebas unitarias con reemplazos simulados.
