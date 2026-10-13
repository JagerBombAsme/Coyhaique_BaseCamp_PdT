# ADR-001 — Arquitectura tecnológica base

## Estado

Aceptado para V1.

## Contexto

Coyhaique BaseCamp requiere una aplicación móvil turística, backend, almacenamiento, capacidades offline, una presencia web pública y administración básica de contenidos.

El desarrollo debe mantenerse viable para una implementación individual acelerada y evitar infraestructura innecesariamente compleja.

## Decisión

Se adopta:

- Flutter + Dart para la aplicación Android.
- Arquitectura feature-first inspirada en MVVM.
- Supabase como backend gestionado.
- PostgreSQL como base de datos.
- Supabase Auth para autenticación.
- Supabase Storage para recursos.
- RLS para autorización de datos.
- SQLite para persistencia local/offline.
- Next.js + TypeScript para web.
- Vercel para hosting web.
- GitHub como fuente de verdad técnica.
- GitHub Actions para automatización gradual.

El proveedor cartográfico se mantiene desacoplado y pendiente de un ADR específico.

## Consecuencias

Positivas:
- menor cantidad de infraestructura propia;
- stack acotado;
- separación clara entre móvil, web y backend;
- posibilidad de compartir backend;
- versionamiento de migraciones;
- soporte para autenticación, Storage y RLS.

Riesgos:
- dependencia de Supabase;
- necesidad de diseñar correctamente políticas RLS;
- necesidad de administrar sincronización offline;
- dependencia futura del proveedor cartográfico seleccionado.

## Regla de cambio

Modificar esta arquitectura requiere un nuevo ADR o una actualización explícita de esta decisión.
