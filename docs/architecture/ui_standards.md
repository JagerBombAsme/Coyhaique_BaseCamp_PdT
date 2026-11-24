# Estándares de interfaz — Coyhaique BaseCamp

Reglas para pantallas y componentes nuevos. Nacen de los defectos de la auditoría del 23-11-2026 (`docs/quality/ui_ux_audit.md`).

## 1. Tokens y componentes

- Colores, tipografía, radios y espacios salen de `basecamp_tokens.dart` (`BcColors`, `BcText`, `BcRadius`, `BcSpace`). No se escriben colores ni tamaños a mano.
- Antes de crear un componente, revisa `bc_widgets.dart`, `bc_scroll_back_bar.dart` y `bc_motion.dart`. Si ya existe uno parecido, se mejora ese.
- Las pantallas nuevas no usan el estilo Material por defecto (por ejemplo `AppBar` verde azulado o `ListTile` sin tokens).

## 2. Áreas seguras y elementos fijos

- **Botones fijos sobre contenido que se desplaza** (arriba o abajo): siempre llevan un fondo color niebla que se desvanece. En el inicio es `_TopScrim`; en la planificación, `_BottomActions`. El contenido nunca pasa visible por debajo de un botón ni de la hora del sistema.
- **Espacio para la barra de navegación:** el contenido de las pestañas usa `MediaQuery.paddingOf(context).bottom`, que con `extendBody` ya incluye la barra. No se usan números fijos para esa altura.
- **Hojas inferiores desde una pestaña:** se abren con `useRootNavigator: true`. Sin eso, la barra de navegación flotante queda encima de la hoja.
- **Diálogos:** usan `showDialog`, que por defecto ya usa el navegador raíz.

## 3. Barra de estado

- Una pantalla con foto de cabecera declara íconos claros (`SystemUiOverlayStyle.light`).
- Cuando aparece una barra blanca encima, como `BcScrollBackBar`, esa barra declara íconos oscuros. No se deja texto ni íconos blancos sobre fondo blanco.

## 4. Volver

- Toda pantalla secundaria tiene una salida visible: el botón de esquina sobre la foto y, al bajar, `BcBackOnScroll` o `BcScrollBackBar`.
- Se respeta el botón Atrás de Android.
- Si al salir se pierden cambios, se pide confirmación con `PopScope` o un diálogo.

## 5. Texto y tamaño

- No se esconde un desborde con `ClipRect`, `FittedBox` ni `TextOverflow.ellipsis` en textos que el usuario necesita leer. Se corrige la causa, por ejemplo con más ancho o con el ícono sobre el texto.
- Un componente que puede quedar angosto (menos de 200 dp) tiene un modo compacto, como `BcWideInfoTile.compact`.
- **No usar `LayoutBuilder` dentro de `IntrinsicHeight` ni de `IntrinsicWidth`**: falla en tiempo de ejecución. Para esos casos, el ancho se calcula afuera y se pasa como parámetro.
- Tamaño mínimo de texto: 12 sp para textos secundarios.
- Cada componente nuevo se prueba con letra de 1×, 1,3× y 2× en 320 y 411 dp de ancho.

## 6. Toques y accesibilidad

- Área táctil mínima de 48 × 48 dp, aunque el elemento visible sea más chico.
- Todo `IconButton` lleva `tooltip`. Los controles propios llevan `Semantics(button: true, label: …)` y, si aplica, `selected`.
- Los íconos decorativos van en `ExcludeSemantics`.
- Un estado (elegido, error, excedido) nunca se comunica solo con color: también con ícono o texto.
- Contraste mínimo de 4,5:1 para texto normal y 3:1 para texto grande e íconos. Los colores de `BcColors` ya cumplen sobre fondo niebla y blanco.
- Las animaciones respetan `MediaQuery.disableAnimationsOf` (duración 0) y duran como máximo 300 ms.

## 7. Contenido

- No se afirma más de lo que dicen los datos. Si un registro es `fuente_publica`, la interfaz dice «fuente pública» y no «habilitada».
- Horarios, traslados y precios se rotulan como estimados o referenciales.
- Todo texto nuevo va en español y en inglés.

## 8. Antes de hacer commit

```
dart format lib test
flutter analyze
flutter test
```

Revisa la pantalla en un teléfono: arriba del todo, desplazada, con el teclado abierto si tiene campos, y con letra grande.
