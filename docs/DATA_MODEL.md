# Coyhaique BaseCamp — DATA_MODEL

## 1. Estado

BORRADOR DE DISEÑO.

Este documento no constituye todavía el modelo físico definitivo.

El modelo debe cerrarse antes de implementar funcionalidades que dependan de persistencia real.

## 2. Principios

- PostgreSQL como fuente principal.
- RLS para tablas expuestas mediante Supabase Data API.
- UUID para identificadores cuando corresponda.
- Minimización de datos personales.
- Borrado lógico donde se necesite mantener trazabilidad.
- Separar información pública de información asociada a usuarios.
- No almacenar contraseñas manualmente; usar Supabase Auth.
- Mantener migraciones versionadas.

## 3. Entidades mínimas candidatas

Las siguientes entidades derivan del alcance congelado y deben validarse antes de crear tablas definitivas.

### category
Representa categorías turísticas.

Campos candidatos:
- id
- name_es
- name_en
- slug
- icon_reference
- is_active
- created_at
- updated_at

### attraction
Representa un atractivo o punto de interés.

Campos candidatos:
- id
- category_id
- name_es
- name_en
- description_es
- description_en
- latitude
- longitude
- address
- practical_information
- difficulty
- is_active
- created_at
- updated_at
- retired_at

### attraction_media
Recursos visuales asociados a un atractivo.

Campos candidatos:
- id
- attraction_id
- storage_path
- alt_text_es
- alt_text_en
- sort_order
- is_active

### profile
Información mínima adicional al usuario de Supabase Auth.

Campos candidatos:
- user_id
- preferred_language
- created_at
- updated_at

No duplicar correo o contraseña si no existe una justificación técnica.

### itinerary
Itinerario asociado a usuario cuando corresponda.

Campos candidatos:
- id
- user_id
- name
- created_at
- updated_at

### itinerary_item
Elementos de un itinerario.

Campos candidatos:
- id
- itinerary_id
- attraction_id
- sort_order
- planned_time
- notes

### admin_audit
Trazabilidad administrativa básica.

Campos candidatos:
- id
- actor_user_id
- entity_type
- entity_id
- action
- created_at
- metadata

## 4. Relaciones preliminares

```text
category
   1
   │
   └──────< attraction
                1
                │
                └──────< attraction_media


auth.users
   1
   │
   ├────── 1 profile
   │
   └──────< itinerary
               1
               │
               └──────< itinerary_item >────── 1 attraction
```

## 5. Información pública

Candidatos a lectura pública:
- categorías activas;
- atractivos activos;
- medios activos asociados a atractivos.

Debe validarse la política exacta mediante RLS.

## 6. Información privada

Debe restringirse por usuario:
- perfil;
- itinerarios;
- elementos de itinerario;
- cualquier preferencia personal persistida.

## 7. Información administrativa

Solo roles autorizados:
- altas de contenido;
- modificaciones;
- activación/desactivación;
- retiro;
- trazabilidad.

## 8. Offline

No se replica toda la base PostgreSQL.

SQLite local debe contener únicamente los datos necesarios para el contenido descargado.

Esquema local definitivo: pendiente de diseño después de cerrar el modelo remoto.

## 9. Pendientes antes de congelar este archivo

- validar tablas con las HU definitivas;
- decidir campos obligatorios;
- decidir estructura exacta de contenido bilingüe;
- decidir estrategia de roles administrativos;
- definir políticas RLS;
- definir borrado lógico;
- definir índices;
- definir restricciones;
- definir estrategia de sincronización offline;
- generar diagrama entidad-relación final.

No implementar migraciones finales hasta resolver estos puntos.
