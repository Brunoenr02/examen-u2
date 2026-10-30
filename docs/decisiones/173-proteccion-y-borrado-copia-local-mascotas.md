# Protección y borrado de la copia local de mascotas

Estado: implementado para Android. Fecha: 30/10/2026. Alcance: exclusivamente ítem 3 del examen tipo 4, aplicado al archivo de mascotas de los ítems 1 y 2.

## Decisión

AndroidManifest declara allowBackup=false. Las reglas fullBackupContent (Android 11 o anterior) y dataExtractionRules (Android 12 o posterior) excluyen todas las rutas de datos de los dominios root, file, database, sharedpref, external y sus variantes device disponibles. Las exclusiones se aplican tanto a cloud-backup como a device-transfer. No se modifica el cifrado del ítem 2.

SecureScreen, componente compartido de presentación, encapsula el canal nativo de protección y envuelve exclusivamente el contenido Mis mascotas de HomeScreen. No muestra datos hasta recibir confirmación de FLAG_SECURE. Al abrir otra ruta oculta la lista subyacente antes de liberar la protección, y al volver espera una nueva confirmación antes de mostrarla. Al salir de la sección libera la bandera. Si falla la protección permanece sin datos visibles. En Android 13 o superior MainActivity usa también setRecentsScreenshotEnabled(false), evitando miniaturas incluso al abrir Perfil. En versiones anteriores FLAG_SECURE protege las miniaturas de la lista.

El botón Borrar datos de este teléfono está en Perfil, fuera de la lista protegida. Su ViewModel consume el caso de uso OfflinePets.deleteAll mediante providers declarativos. La fuente elimina solo los archivos pets_<cuenta>_<active|archived>.json y sus temporales en soporte privado, de todas las cuentas, porque comparten una clave de instalación. Finalmente solicita deleteKey al adaptador nativo; Android elimina el alias y comprueba containsAlias=false antes de confirmar. No se exporta la clave. Las operaciones de lectura, guardado y borrado están serializadas para que un guardado pendiente no vuelva a escribir después de un borrado confirmado. Un error no se presenta como éxito y permite reintentar.

La notificación de cambio invalida la lista retenida de la cuenta actual. El borrado afecta la copia sin conexión del examen y su clave; no elimina la cuenta, las mascotas del servidor, la sesión ni los borradores de reportes de otras funcionalidades. Esas funcionalidades no se amplían con este ítem.

## Validación

Flutter analyze sin incidencias, APK debug compilado e instalado y 22 pruebas aprobadas: 20 regresiones existentes más dos pruebas de protección de pantalla. Estas últimas verifican espera de confirmación, ocultación de la lista y liberación al abrir Perfil, reprotección al volver, liberación al desmontar y no revelar datos si falla el canal. No son las pruebas de almacenamiento exigidas por los ítems 4 y 5.

En emulator-5554: sesión conservada con instalación -r, lista descifrada en modo avión, FLAG_SECURE confirmado mediante dumpsys window. Captura directa negra y tarjeta negra en recientes; capturas reales en output/examen-item-3. Perfil permite capturas. Se pulsó Borrar datos de este teléfono; apareció confirmación de archivo y clave eliminados. ls files ya no muestra pets_*.json y cat de la ruta anterior devuelve No such file or directory. El éxito del canal verifica la ausencia del alias dentro de AndroidKeyStore; no existe un comando de exportación de clave.

El paquete instalado no tiene ALLOW_BACKUP en sus flags. Esto verifica la configuración instalada y las exclusiones versionadas; no se afirma haber realizado un ciclo de respaldo/restauración en un segundo dispositivo. Android es el alcance de la prueba, no iOS.

Referencias oficiales: https://developer.android.com/identity/data/autobackup y https://developer.android.com/security/fraud-prevention/activities y https://developer.android.com/reference/android/app/Activity#setRecentsScreenshotEnabled(boolean).

Revisión adicional: profile_overview_test.dart, profile_navigation_test.dart y home_test.dart completaron 8 casos y tuvieron 5 timeouts de pumpAndSettle en el arranque de Inicio (home_test.dart:252 y profile_navigation_test.dart:117), antes de navegar a las pantallas modificadas. No se alteraron las animaciones generales para este ítem. La suite seleccionada de 22 casos de arquitectura/mascotas/protección sí pasa.
