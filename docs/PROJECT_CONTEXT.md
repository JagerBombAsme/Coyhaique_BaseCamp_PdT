# Coyhaique BaseCamp — PROJECT_CONTEXT

## 1. Propósito

Este documento define el contexto maestro de desarrollo de Coyhaique BaseCamp y debe ser leído antes de implementar cambios relevantes en el repositorio.

Coyhaique BaseCamp es una solución tecnológica orientada al turismo en Coyhaique y la Región de Aysén. La V1 considera una aplicación móvil Android, una landing page, backend, base de datos, autenticación opcional, información turística, geolocalización, mapas, rutas, itinerarios, administración restringida, soporte bilingüe y capacidades offline.

## 2. Regla principal de alcance

El alcance funcional V1 está congelado.

No se deben incorporar nuevas funcionalidades durante la implementación.

Cualquier nueva idea debe registrarse como:

> TRABAJO FUTURO — no implementar en V1.

Una referencia visual, una sugerencia de IA o una idea encontrada durante el desarrollo no constituye automáticamente un requerimiento.

## 3. Fuente de verdad

- GitHub: estado técnico real del proyecto.
- Trello: seguimiento del trabajo.
- RDP: registro de decisiones y cambios relevantes.
- Evidencias: pruebas, capturas y resultados verificables.
- Documentación en `docs/`: arquitectura, modelo de datos, flujos y decisiones técnicas.

## 4. Stack V1

### Aplicación móvil
- Lenguaje: Dart.
- Framework: Flutter.
- Plataforma objetivo inicial: Android.
- Arquitectura: feature-first, por capas, inspirada en MVVM.

### Backend
- Supabase.
- PostgreSQL.
- Supabase Auth.
- Supabase Storage.
- Row Level Security (RLS).
- Edge Functions solo cuando una operación privilegiada lo justifique.

### Persistencia local
- SQLite para datos offline y caché estructurada.
- Almacenamiento key-value para configuración simple.

### Web
- Next.js.
- TypeScript.
- Vercel.

### Control de versiones
- Git.
- GitHub.
- GitHub Actions para análisis, pruebas y builds automatizados.

## 5. Funcionalidades V1 congeladas

### Información turística
- Listado de atractivos.
- Detalle de atractivo.
- Categorías.
- Filtros.

### Ubicación y orientación
- Solicitud y manejo de permiso de ubicación.
- Alternativa de ubicación manual.
- Visualización de mapa.
- Puntos cercanos.
- Distancias.
- Ruta origen-destino.

### Planificación
- Propuesta básica de itinerario.
- Edición del itinerario.

### Administración
- Crear contenido.
- Editar contenido.
- Activar/desactivar contenido.
- Retirar contenido manteniendo trazabilidad.

### Cuenta y persistencia
- Registro opcional.
- Login/logout.
- Recuperación de acceso cuando corresponda.
- Persistencia autorizada asociada al usuario.

### Offline
- Descarga de contenido definido.
- Consulta de contenido sin conexión.

### Idioma
- Español.
- Inglés.

### Web
- Landing pública.
- Política de privacidad.
- Términos.
- Eliminación de cuenta.
- Área administrativa protegida.

## 6. Orden obligatorio de implementación

No iniciar una etapa si sus dependencias no están terminadas.

1. Congelamiento de alcance.
2. Arquitectura.
3. Modelo de datos.
4. Modelo de autorización y RLS.
5. Selección de proveedor cartográfico.
6. Mapa definitivo de navegación.
7. Estructura del repositorio.
8. Proyecto Flutter base.
9. Navegación.
10. Tema y componentes base.
11. Supabase y datos iniciales.
12. HU-01 — Listado de atractivos.
13. HU-02 — Detalle de atractivo.
14. HU-03 — Filtros.
15. HU-05 — Geolocalización.
16. HU-06 — Mapa y cercanos.
17. HU-07 — Distancia.
18. HU-08 — Ruta.
19. HU-04 — Propuesta de itinerario.
20. HU-13 — Edición de itinerario.
21. HU-17 — Administración: crear.
22. HU-18 — Administración: editar.
23. HU-19 — Administración: activar/desactivar.
24. HU-20 — Administración: retirar.
25. HU-21 — Registro.
26. HU-22 — Login/logout.
27. HU-29 — Persistencia autorizada.
28. HU-15 — Offline.
29. HU-30 — Español/inglés.
30. Integración.
31. Pruebas.
32. Congelamiento funcional.
33. Despliegue.
34. Evidencias y cierre.

## 7. Regla de dependencia de pantallas

Si una pantalla B depende de una pantalla A, A debe existir y navegar correctamente antes de implementar B.

Ejemplo:

```text
Listado
  ↓
Detalle
```

Para orientación territorial:

```text
Geolocalización
  ↓
Mapa
  ↓
Cercanos
  ↓
Distancia
  ↓
Ruta
```

## 8. Definición de terminado

Una historia no está terminada solo porque la pantalla se visualiza.

Debe cumplir, según corresponda:

- criterios de aceptación;
- navegación funcional;
- datos correctos;
- estados loading/success/empty/error;
- manejo de permisos;
- control de acceso;
- manejo de errores;
- pruebas;
- análisis estático;
- commit en GitHub;
- evidencia.

## 9. Reglas para asistentes de IA

Antes de realizar cambios:

1. Leer este archivo.
2. Revisar el estado actual del repositorio.
3. Revisar `ARCHITECTURE.md`.
4. Revisar `DATA_MODEL.md` si la tarea utiliza datos.
5. Revisar `USER_FLOWS.md` si la tarea afecta pantallas o navegación.
6. Revisar ADR relacionados.
7. No agregar funcionalidades no congeladas.
8. No cambiar arquitectura silenciosamente.
9. No exponer secretos.
10. No adelantarse a dependencias no resueltas.

Si aparece una contradicción, debe señalarse antes de realizar un cambio arquitectónico.
