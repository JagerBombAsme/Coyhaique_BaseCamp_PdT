# Cambios de interfaz — 23-11-2026

## Refactor UI/UX y accesibilidad (candidato para rama de pruebas)

- Botones adaptables a texto multilínea, selección y feedback más coherentes.
- Barra de retroceso persistente para fichas, categorías, transfers e intereses; salida fija en el selector de transporte.
- Navegación inferior de ancho equitativo con modo compacto y etiquetas accesibles.
- Acciones del planificador integradas al layout sin superposición fija; hoja de lugares ajustada al teclado.
- Reordenamiento del itinerario mediante acciones de menú además del arrastre.
- Intereses y categorías con altura adaptable; chips dimensionados según la escala de texto.
- Eliminación del límite global de escala de texto (requiere validación de pantallas no intervenidas).
- Nuevas pruebas de regresión y actualización de documentación, conservando el registro histórico.

## Estado de validación

Revisión estática y verificación de diferencias realizadas. Flutter/Dart y el emulador no están disponibles en el entorno de edición; compilación, análisis, formateo oficial, widget tests y pruebas visuales quedan pendientes. Revisar `docs/quality/ui_ux_audit.md` para el alcance exacto y la matriz de pruebas.
