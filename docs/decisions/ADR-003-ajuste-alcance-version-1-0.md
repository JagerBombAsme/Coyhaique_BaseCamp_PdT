# ADR-003 — Ajuste del alcance de la Versión 1.0

## Estado

Aceptado. Decisiones del 26-10-2026, alineadas con la Evaluación 1 el 27-10-2026 y ampliadas el 30-10-2026 (transfer desde el aeropuerto).

Modifica el ADR-002: el alcance de la Versión 1.0 se reabre formalmente solo en los puntos indicados aquí. Todo lo demás sigue congelado.

## Contexto

Al preparar la Evaluación 2 se revisó el alcance real del código y de la base de datos frente a lo declarado en la Evaluación 1 (E1). Había funcionalidades a medio construir (favoritos, valoraciones, edición por prestadores, reservas de transporte) y tablas legacy en uso.

El profesor guía fijó dos reglas:

1. Solo se implementa lo declarado en la E1. Lo excluido o no declarado queda como trabajo futuro.
2. Se pueden agregar funcionalidades nuevas siempre que se justifiquen y queden registradas.

Además, la retroalimentación de la E1 exigió nombrar el motor de almacenamiento local (comentario 8).

## Decisiones

| ID | Tema | Decisión | Base |
|---|---|---|---|
| D1 | Favoritos | Fuera de la Versión 1.0. Trabajo futuro. | No declarado en la E1. |
| D1 | Valoraciones de 1 a 5 | Fuera de la Versión 1.0 y del diseño de la E2. Trabajo futuro. | La E1 excluye las evaluaciones de usuarios. |
| D1 | Prestador edita su ficha | Fuera de la Versión 1.0. Trabajo futuro. Se mantiene HU-12 (ficha con datos del prestador validados por el equipo). | La E1 excluye la autoadministración de prestadores. |
| D2 | Rutas e itinerarios | Ambos dentro de la Versión 1.0. Rutas con Mapbox Directions; el planificador usa `itineraries_v2` e `itinerary_items_v2` en vez de `destinations`. | HU-07, HU-08 y HU-20 declaradas en la E1. |
| D3 | Transporte | Se migra al modelo V2 (`transport_services_v2`). Se retiran las reservas (`pre_reservations`): la app no maneja datos personales de pasajeros. Información referencial con fecha de verificación, sin precios ni asientos en tiempo real. | HU-18 (sube a prioridad Alta en la E2). |
| D4 | Uso sin conexión | Catálogo descargado en sqflite, de solo lectura y con fecha de descarga; Supabase es la fuente oficial. Preferencias en shared_preferences y caché de imágenes. Los mapas completos sin conexión quedan como trabajo futuro. | HU-09, HU-10 y RNF-04 de la E1. Revierte la decisión inicial del 26-10 («sin catálogo sin conexión»). |
| D5 | Administración de contenidos | Desde el panel de Supabase, con acceso restringido a miembros del proyecto, roles, RLS y auditoría. Sin pantallas de administración en la app. | HU-13, HU-14 y HU-17. |
| D6 | Recomendaciones | Por reglas según los intereses declarados, sin inteligencia artificial. | HU-21. |
| D7 | Transfer desde el aeropuerto con código QR | Funcionalidad nueva dentro de HU-18. Ver la sección siguiente. | Regla 2 del profesor. |

## D7 — Transfer desde el aeropuerto con código QR

### Problema observado

En el aeropuerto de Balmaceda hay tres puestos de transfer. El pasajero coordina destino, número de personas y medio de pago en persona, y el conductor anota los datos a mano en un cuaderno. Eso genera errores al dictar direcciones y no deja un registro ordenado de los viajes.

### Solución

1. El pasajero elige una empresa en la app, su destino (alojamiento del catálogo, centro, terminal u otra localidad), los pasajeros, si lleva equipaje grande y el medio de pago. Todo con botones; no se escribe texto.
2. La app genera en el teléfono un código QR con un enlace de WhatsApp a la empresa y el viaje ya redactado.
3. El conductor lo escanea con la cámara, sin instalar nada. Al enviar el mensaje, el viaje queda registrado en el chat de la empresa con fecha y hora.
4. Sin señal, el conductor lee los mismos datos en la pantalla del pasajero.

### Límites

- No es una reserva. El código no confirma el viaje: el conductor debe leerlo y aceptarlo. La app lo dice en la pantalla del código.
- No se piden ni se guardan datos personales: ni nombre, ni teléfono, ni correo, ni dirección particular, ni ubicación. El QR no pasa por ningún servidor.
- La app no cobra. La tarifa es referencial y la confirma el conductor.
- Piloto con un solo prestador, con autorización escrita archivada fuera de la app. Sumar más empresas es cargar contenido, no programar.

### Implementación

- Tabla `transport_services_v2` con RLS de solo lectura, auditoría y nivel de verificación (`backup_database/migraciones/2026-10-30_transport_services_v2.sql`).
- Pantallas en `lib/features/transport/`: lista de transfers, «Tu traslado» y código para el conductor.
- Copia local de las fichas para usarlas al bajar del avión sin señal.
- Accesos desde la categoría Transporte y desde «¿Desde dónde partes?» («¿Estás en el aeropuerto?» y ruta del aeropuerto al centro para quien viaja en transporte propio).

### Trabajo futuro

- Registro en una planilla de la empresa con el resumen diario por medio de pago.
- Incorporar las demás empresas del aeropuerto.

## Cambios de base de datos asociados (31-10-2026)

Migración `backup_database/migraciones/2026-10-31_estructura_previa_diagramas.sql`:

- Respaldo en `backup_20261031` y retiro de `pre_reservations`, `test_connection`, `places` y `categories`, que ya no usa la app.
- `places_v2` suma `verification_level` (establecimiento o fuente pública) y `estimated_visit_minutes` (planificador).
- `profiles`: cada usuario ve y edita solo su perfil. Antes cualquiera podía leer todos los perfiles.
- `destinations` queda de solo lectura hasta su retiro.

## Consecuencias

- Las funcionalidades fuera de alcance se describen en el informe como trabajo futuro, sin resultados de prueba.
- El transfer con QR se reporta como funcionalidad nueva justificada, con su prueba con un conductor como evidencia de validación.
- La dependencia `qr_flutter` se conserva (la tarea de limpieza del build se ajusta).
- KPI-02 se mide sobre 25 HU, con meta de al menos 23 entregadas.
- El producto se denomina «Versión 1.0» en toda la documentación.
