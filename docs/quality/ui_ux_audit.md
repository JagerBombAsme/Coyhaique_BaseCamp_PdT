# Auditoría de interfaces y accesibilidad — Coyhaique BaseCamp

- **Fecha:** 23-11-2026, de 21:20 a 21:40.
- **Versión:** Versión 1.0, en mantenimiento correctivo (posterior al corte del 17-11).
- **Ejecutó:** Claude, a pedido de Diego Del Río.
- **Dispositivo:** Samsung SM-A505G, Android, 411 × 846 dp, escala de texto del sistema 1,1×. La app corría en modo debug con `flutter run`, reflejada en el computador con scrcpy.

## 1. Cómo se hizo y límites

La revisión combinó tres fuentes:

- **Ejecución real.** Se recorrió la app en el teléfono con capturas de scrcpy, tocando y deslizando como un usuario.
- **Errores de ejecución.** El log de la app se leyó con el Dart Tooling Daemon (`get_runtime_errors`) antes y después de cada corrección.
- **Lectura del código** de las pantallas y componentes afectados.

Cada corrección se aplicó con *hot reload* y se volvió a capturar la pantalla.

**Lo que NO se validó.** No se declara como probado nada de esta lista:

- Otros anchos de pantalla (320, 360, 390, 430, 600 y 768 dp). Solo se probó 411 dp.
- Escalas de texto de 1,3×, 1,5× y 2×. La app limita la escala a 1,15× en `main.dart` (ver R-01).
- TalkBack.
- Orientación horizontal.
- Modo sin conexión durante esta sesión.
- Sesión iniciada: edición de perfil, guardar itinerario e intereses con cuenta.
- La corrección de la brújula y del logo de Mapbox (UI-02). Requiere volver a crear el mapa (*hot restart* o reabrir la pantalla); se aplicó en el código, pero no se vio en pantalla.
- `flutter test` y `dart format`. Este entorno no tiene terminal en el computador; deben ejecutarse localmente (ver §6).

**Trabajo en paralelo.** Durante la auditoría otra sesión modificaba los mismos archivos (`planificacion_screen.dart`, `home_screen.dart`, `place_detail_screen.dart`, `bc_scroll_back_bar.dart`). Una de mis correcciones (UI-05) fue sobrescrita y hubo que aplicarla de nuevo. Antes de hacer commit conviene revisar el diff completo.

## 2. Inventario de pantallas

| Pantalla | Revisada en el teléfono | Resultado |
|---|---|---|
| Inicio | Sí, arriba y desplazada | UI-01 y UI-03 corregidos |
| Mapa, modo navegación | Sí | UI-02 corregido en código, sin validar en pantalla |
| Planificación: propuesta, calendario y línea de tiempo | Sí | UI-05 corregido |
| Planificación: hoja «Agregar lugar» | Sí | UI-05 corregido y validado |
| Perfil (invitado) | Sí | Sin defectos bloqueantes |
| Antes de tu viaje | Sí | P3: estilo Material por defecto (ver R-04) |
| Categoría «Atractivos» | Sí | Sin defectos |
| Ficha de lugar | Sí | UI-04 (barra de estado) corregido en el componente compartido |
| Transfer al aeropuerto | Sí | UI-04 y UI-06 corregidos y validados |
| Inicio de sesión, con teclado abierto | Sí | Sin defectos: el botón queda visible |
| Mis itinerarios (sin sesión) | Sí | P3: estilo Material por defecto (ver R-04) |

**Revisadas solo en código o no revisadas:** registro, recuperar contraseña, editar perfil, intereses, idioma, bienvenida, ubicación inicial, rutas, solicitud y código de transfer.

## 3. Defectos encontrados y corregidos

| ID | Sev. | Pantalla | Defecto | Causa raíz | Solución | Archivos | Evidencia |
|---|---|---|---|---|---|---|---|
| UI-01 | P1 | Inicio | Al desplazar, el contenido pasaba bajo la barra de estado y bajo los botones fijos de Perfil, Guardar e Info. El texto quedaba encima de la hora y los chips de EXPLORAR quedaban tapados. | Los botones se dibujan fijos en un `Stack` sobre un `SingleChildScrollView`, sin fondo debajo. | Franja fija `_TopScrim` color niebla bajo la barra de estado y los botones, con borde que se desvanece. No recibe toques. | `home_screen.dart` | Captura antes y después, 21:24 y 21:31 |
| UI-02 | P1 | Mapa, navegación | La brújula de Mapbox quedaba tapada por la barra de la maniobra. El logo y la atribución de Mapbox quedaban bajo la barra de navegación (son condición de uso de Mapbox). | La brújula estaba a `top + 130` dp, pero la barra con maniobra llega a unos 205 dp. El margen del logo usaba `padding.bottom`, que al crear el mapa no incluye la barra flotante. | Brújula a `top + 230`. Logo y atribución a `_bottomPanelOffset − 28` (entre la barra y el panel). | `map_screen.dart` | Captura «antes», 21:24. No validado después (requiere reabrir el mapa). |
| UI-03 | P1 | Inicio | `RenderFlex overflowed by 26 pixels` en «Disponible sin conexión»: el subtítulo ocupaba 5 líneas y el botón «^» tapaba el título. | Con dos tarjetas lado a lado (~175 dp), el ícono al costado dejaba 88,7 dp al texto (dato del log). | `BcWideInfoTile` recibe `compact`: el ícono va sobre el texto. El inicio lo activa si cada tarjeta mide menos de 200 dp. Se usa un parámetro y no `LayoutBuilder` porque la tarjeta va dentro de `IntrinsicHeight`. | `bc_widgets.dart`, `home_screen.dart`, prueba nueva | Log antes: overflow. Log después: «No runtime errors». Capturas a las 21:31. |
| UI-03b | P1 | Inicio | El botón «Ocultar tarjetas» tenía un área táctil de 40 × 40 dp. | Tamaño fijo bajo el mínimo. | 48 × 48 dp. El círculo visible no cambia. | `home_screen.dart` | Código |
| UI-04 | P2 | Ficha de lugar y Transfer | Al bajar, la barra «Volver» blanca dejaba los íconos de la barra de estado blancos sobre blanco. | La pantalla fija íconos claros para la foto, y nadie los cambiaba al aparecer la barra blanca. | `BcScrollBackBar` declara íconos oscuros mientras se ve y claros mientras está oculta. Corrige de una vez todas las pantallas que la usan. | `bc_scroll_back_bar.dart` | Captura «antes» a las 21:25 (ficha); «después» a las 21:33 (Transfer) |
| UI-05 | P1 | Planificación | La hoja «Agregar lugar» se abría bajo la barra de navegación flotante, que tapaba los últimos lugares. | `showModalBottomSheet` usaba el navegador de la pestaña; la barra pertenece al `Scaffold` del shell, que está por encima. | `useRootNavigator: true`. | `planificacion_screen.dart` | Capturas antes (21:34) y después (21:36) |
| UI-06 | P1 (contenido) | Transfer | La tarjeta de Transfer T&T decía «VERIFICADA · Y HABILITADA» y «Habilitación verificada», pero la misma tarjeta indica que la inscripción en el MTT está pendiente. Contradicción con información de habilitación (Ley 21.787). | La etiqueta no distinguía el nivel de verificación `fuente_publica`. | Con `fuente_publica`: «VERIFICADA · FUENTE PÚBLICA» y «Datos revisados en fuentes públicas el …». El subtítulo de la sección ya no afirma «Habilitadas»: dice «Revisadas por el equipo; cada tarjeta indica cómo y cuándo». | `transfers_screen.dart` | Capturas antes (21:32) y después (21:33) |

La propuesta de planificación también mostraba los botones fijos encima del contenido, sin fondo. Lo corrigió la otra sesión con `_BottomActions`, y se verificó en el teléfono a las 21:35.

## 4. Riesgos pendientes (no corregidos hoy)

| ID | Sev. | Riesgo | Por qué no se corrigió | Recomendación |
|---|---|---|---|---|
| R-01 | P1 | `main.dart` limita la escala de texto del sistema a 1,15×. Va contra WCAG 1.4.4 y contra la regla «no reducir artificialmente la escala de texto». | Quitar el límite afecta a todas las pantallas. Sin probarlas a 1,3× y 2× es arriesgado a un día de la entrega. | Subir el límite a 1,3× y probar todas las pantallas. Luego quitarlo. Declararlo en el informe como limitación conocida. |
| R-02 | P2 | Dato «Ver disponibilidad en la recinto» (error de concordancia) en la ficha de la Biblioteca Regional. | Es un dato de Supabase. La auditoría no modifica la base. | Corregirlo en `places_v2` con aprobación. |
| R-03 | P2 | Un lugar del catálogo puede quedar como primera parada a 5 min del propio punto de partida (Plaza de Armas). | Es comportamiento del algoritmo, no de la interfaz. | Evaluarlo como mejora del planificador. |
| R-04 | P3 | «Antes de tu viaje» y «Mis itinerarios» usan el estilo Material por defecto (verde azulado, otra tipografía), no los tokens de BaseCamp. | Rediseño fuera del alcance de hoy. | Migrarlas a `BcColors` y `BcText`. |
| R-05 | P2 | En el inicio, la fila de chips de EXPLORAR corta el último chip sin una señal de que se puede deslizar. | Mejora de diseño, no un defecto bloqueante. | Agregar un desvanecido en el borde derecho. |
| R-06 | — | No se probaron anchos de 320 a 768 dp, TalkBack ni el estado con sesión iniciada. | Tiempo y entorno. | Ver §1. |

## 5. Prevención

- **Componente compartido corregido una vez.** `BcScrollBackBar` decide el estilo de la barra de estado; `BcWideInfoTile` tiene un modo compacto.
- **Prueba nueva:** `test/bc_wide_info_tile_test.dart`. Verifica que la tarjeta no se desborde a 160 dp con letra de 1×, 1,15×, 1,3× y 2×, ni a 360 dp con 1,3×. También verifica el área táctil con `androidTapTargetGuideline`.
- **Estándares para pantallas futuras:** `docs/architecture/ui_standards.md`.

## 6. Pruebas

| Prueba | Resultado |
|---|---|
| Analizador de Dart (MCP) sobre `lib` y la prueba nueva | Sin errores |
| Errores en ejecución después de las correcciones | Sin errores (DTD, 21:31) |
| `flutter test` | **No ejecutado aquí.** Ejecutar: `flutter test` |
| `dart format` | **No ejecutado aquí.** Ejecutar: `dart format lib test` |

---

## Addendum — revisión estática y refactor de componentes (23-11-2026)

**Origen:** ZIP de la rama `main`, commit base indicado por el archivo ZIP `b01a33b8f8ed4213035caa696386fe21a54f1a44`. Esta revisión no reemplaza las evidencias de la sesión anterior. No se ejecutó la app en un dispositivo en esta intervención.

| ID | Prioridad | Área | Causa encontrada en código | Cambio aplicado |
|---|---|---|---|---|
| BC-R01 | P1 | Botones comunes, perfil | Altura fija y etiquetas con elipsis | Altura mínima, padding vertical y etiquetas multilínea; feedback y foco en componentes BaseCamp. |
| BC-R02 | P1 | Fichas y transfers | Volver dentro de hero y barra condicionada a umbral de scroll | `BcPinnedBackLayout` reserva espacio real y mantiene la acción visible; actualización de ficha en barra fija. |
| BC-R03 | P1 | Categorías e intereses | Volver dentro del contenido; algunos estados de carga sin salida | Barra fija también en carga/error de categorías, navegación de retorno con fallback y listado de categorías de altura natural. |
| BC-R04 | P1 | Planificación | Footer sobrepuesto con padding compensatorio fijo | Layout que reserva la altura real; acciones apiladas con poco ancho; fallback desplazable para poca altura. |
| BC-R05 | P1 | Hoja de lugares | Altura mínima independiente del teclado; encabezado fijo | Altura ajustada al teclado y contenido desplazable mediante slivers, manteniendo construcción diferida de lugares. |
| BC-R06 | P1 | Accesibilidad | Límite global de escala de texto 1,15× | Se elimina el límite global; los controles intervenidos se adaptan, otros requieren validación. |
| BC-R07 | P1 | Navegación principal | Etiqueta activa compite por ancho con los iconos; gestos sin foco estándar | Cuatro acciones de ancho equivalente, botones Material, estados seleccionados, tooltips y modo compacto. |
| BC-R08 | P2 | Timeline | Arrastre como vía principal de reordenamiento; columna horaria fija | Acciones de menú arriba/abajo con los índices de `reorder`; ancho de hora adaptable y tarjeta compacta. |
| BC-R09 | P2 | Intereses y chips | Grid de altura fija; chips sin espacio para texto grande | Listado adaptable a ancho/escala con altura natural y filas horizontales de chips dimensionadas según fuente. |
| BC-R10 | P2 | Transporte en mapa | Volver dentro del scroll; nota ocupa espacio fijo | Control de salida fuera del scroll y nota dentro del contenido. |

### Inventario y alcance real

- Cambios directos: navegación inferior compartida, componentes BaseCamp, inicio (chips), categorías, ficha de lugar, transfer al aeropuerto, selector de transporte, planificador, timeline, selector de días, hoja de lugares, intereses, botón compartido de perfil y raíz de aplicación.
- Inspección parcial sin refactor específico: autenticación, perfil/edición, información de viaje, guardados, mapa nativo, rutas, solicitud/código de transfer. Sus funcionalidades y datos no se alteraron intencionalmente.
- No se modificaron algoritmos de generación, providers, contratos de Supabase, rutas del router, dependencias ni persistencia.
- Esta entrega es una **fase de corrección estructural**, no una certificación completa de WCAG ni una revisión visual exhaustiva de todas las pantallas.

### Verificación realizada

- Inspección del código fuente y de referencias a los componentes reemplazados.
- Verificación del balance de delimitadores mediante análisis léxico auxiliar; no sustituye al compilador Dart.
- `git diff --check` para whitespace y revisión de diferencias.
- Se agrega `test/ui_accessibility_regression_test.dart` con casos para botones, barra Volver, chips/avisos y navegación compacta; **no ejecutado**.
- `dart format`, `flutter analyze`, `flutter test`, instalación en Android, pruebas de TalkBack y validación visual: **pendientes**; el entorno de edición no contiene Flutter ni Dart.

### Validación prioritaria en dispositivo

1. Ejecutar `flutter pub get`, `dart format lib test`, `flutter analyze`, `flutter test` con el SDK indicado en `pubspec.yaml` y el workflow.
2. Probar anchos de 320, 360, 390, 430, 600 y 768 dp; escalas 100%, 130%, 150% y 200%; español e inglés. La orientación de producción sigue siendo vertical.
3. Verificar navegación desde inicio a todas las categorías, detalle, transfers, perfil/intereses y mapa; desplazar hasta el final y usar Volver; probar retroceso nativo.
4. Generar propuesta, añadir lugar con teclado activo, reordenar por arrastre y menú, eliminar/deshacer, añadir días, alternar calendario, guardar y retomar después de autenticación.
5. Probar sesión iniciada, permisos rechazados, conexión ausente, nombres largos y carga/error. Comprobar foco y semántica con TalkBack.
6. Riesgo residual: la eliminación del tope de texto puede revelar defectos en pantallas no intervenidas (especialmente mapa nativo, tarjetas fotográficas, onboarding y formularios). Registrar capturas y logs; corregir layouts específicos, no restablecer el tope global como solución final.
