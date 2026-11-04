# Coyhaique BaseCamp — ARCHITECTURE

## 1. Estado

Arquitectura Tecnológica V1.

Decisiones cerradas:
- Flutter + Dart para Android.
- Supabase como backend gestionado.
- PostgreSQL como base de datos.
- SQLite para persistencia local estructurada.
- Next.js + TypeScript para web.
- Vercel para despliegue web.
- GitHub como fuente de verdad técnica.

Decisión pendiente:
- proveedor cartográfico.

## 2. Vista general

```text
                         ┌─────────────────────────┐
                         │        Supabase         │
                         │ PostgreSQL / Auth / RLS │
                         │ Storage / Edge Functions│
                         └────────────┬────────────┘
                                      │
                    ┌─────────────────┴─────────────────┐
                    │                                   │
                    ▼                                   ▼
          Flutter Android                        Next.js Web
          aplicación turista                landing + /admin
                    │                                   │
                    ├─────────────┐                     │
                    │             │                     │
                    ▼             ▼                     │
                 SQLite      Servicios Android          │
                              GPS / conectividad        │
                    │                                   │
                    └──────────────┬────────────────────┘
                                   │
                                   ▼
                         Proveedor cartográfico
                         (por seleccionar)
```

## 3. Aplicación Flutter

Organización feature-first:

```text
apps/mobile/lib/
├── app/
│   ├── router/
│   ├── theme/
│   ├── config/
│   └── l10n/
├── core/
│   ├── errors/
│   ├── services/
│   ├── utils/
│   └── widgets/
└── features/
    ├── onboarding/
    ├── attractions/
    ├── categories/
    ├── location/
    ├── map/
    ├── routing/
    ├── itinerary/
    ├── authentication/
    ├── profile/
    ├── offline/
    └── settings/
```

Estructura interna sugerida por feature:

```text
feature/
├── presentation/
│   ├── views/
│   ├── view_models/
│   └── widgets/
├── domain/
└── data/
    ├── models/
    ├── repositories/
    └── services/
```

La capa `domain` no debe crearse de manera ceremonial en todas las features. Se utiliza cuando exista lógica de negocio que justifique casos de uso explícitos.

## 4. Flujo de datos

```text
View
  ↓
ViewModel
  ↓
Repository
  ├── Remote Service → Supabase
  └── Local Service  → SQLite
```

El Repository abstrae el origen de los datos.

## 5. Backend Supabase

Componentes:

- PostgreSQL: persistencia principal.
- Auth: registro, login, recuperación y sesión.
- Storage: imágenes y recursos administrados.
- RLS: autorización por fila.
- Edge Functions: solo operaciones privilegiadas o integraciones que requieran secretos.

### Regla de seguridad

Nunca exponer `service_role` ni secretos de backend en Flutter o JavaScript público.

Cliente público:

```text
Flutter / Next.js browser
        ↓
publishable key
        ↓
Supabase
        ↓
RLS
```

Operaciones privilegiadas:

```text
Cliente
  ↓
Edge Function / entorno servidor
  ↓
validación de identidad y autorización
  ↓
operación privilegiada
```

## 6. Persistencia offline

```text
UI
 ↓
ViewModel
 ↓
Repository
 ├── Supabase
 └── SQLite
```

No se descargará automáticamente toda la base de datos.

Solo se almacenará localmente el contenido definido para consulta offline.

## 7. Ubicación

La V1 contempla uso de ubicación en primer plano.

Estados que debe soportar:

- permiso no solicitado;
- permiso concedido;
- permiso rechazado;
- permiso bloqueado;
- GPS desactivado;
- ubicación disponible;
- ubicación manual.

No se implementará rastreo permanente en segundo plano.

## 8. Mapas y rutas

El proveedor cartográfico permanece pendiente.

Debe quedar desacoplado:

```text
MapRepository
  ↓
MapService
  ↓
Proveedor cartográfico
```

Rutas:

```text
RouteRepository
  ↓
RoutingService
  ↓
API de rutas
```

La selección debe considerar:

- SDK Flutter;
- mapas;
- routing;
- distancias;
- soporte offline;
- costos;
- cuotas;
- licencia;
- atribución;
- restricciones de API keys.

## 9. Web

Tecnologías:
- Next.js.
- TypeScript.
- Vercel.

Rutas mínimas:

```text
/
├── privacidad
├── terminos
├── eliminar-cuenta
└── admin
```

La landing y el panel administrativo comparten backend, no necesariamente lógica visual.

## 10. Panel administrativo

El panel administrativo se alojará en la aplicación web.

Debe permitir, dentro del alcance congelado:

- crear contenido;
- editar contenido;
- activar/desactivar;
- retirar contenido.

La autorización no puede depender únicamente de controles del navegador.

## 11. Repositorio

```text
coyhaique-basecamp/
├── apps/
│   ├── mobile/
│   └── web/
├── supabase/
│   ├── migrations/
│   ├── seed.sql
│   └── functions/
├── docs/
│   ├── PROJECT_CONTEXT.md
│   ├── ARCHITECTURE.md
│   ├── DATA_MODEL.md
│   ├── USER_FLOWS.md
│   ├── decisions/
│   └── evidence/
└── .github/
    └── workflows/
```

## 12. Despliegue

### Android

```text
GitHub
 ↓
CI
 ↓
Flutter build
 ↓
Android App Bundle (.aab)
 ↓
Google Play Internal Testing
 ↓
Google Play Production
```

### Web

```text
GitHub
 ↓
Vercel Preview
 ↓
Vercel Production
 ↓
Dominio público
```

### Backend

El esquema debe versionarse mediante migraciones en `supabase/migrations/`.

## 13. Decisiones que requieren ADR

Crear un ADR cuando se cierre o cambie:

- arquitectura base;
- proveedor cartográfico;
- modelo de autenticación;
- estrategia offline;
- decisiones importantes de seguridad;
- cambios que afecten varias capas.
