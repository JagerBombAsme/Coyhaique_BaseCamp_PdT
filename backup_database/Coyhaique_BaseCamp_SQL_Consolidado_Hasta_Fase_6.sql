/*
===============================================================================
 COYHAIQUE BASECAMP
 CONSOLIDADO SQL — AUDITORÍA, STAGING, NORMALIZACIÓN, MIGRACIÓN Y SEGURIDAD
 Fecha de consolidación: 2026-10-13

 OBJETIVO
 -------
 Este archivo reúne el SQL utilizado durante el análisis y preparación de la
 base de datos de Coyhaique BaseCamp.

 IMPORTANTE
 ----------
 1) NO ejecutar todo este archivo de una sola vez.
 2) Está dividido en fases.
 3) Las fases 0 y 1 contienen principalmente consultas de diagnóstico.
 4) La Fase 2 crea staging.
 5) La Fase 3 crea el modelo V2 normalizado.
 6) La Fase 4 migra datos desde staging a V2.
 7) La Fase 5 configura permisos, RLS y auditoría.
 8) La Fase 6 verifica el resultado.
 9) Aún NO se incluye el corte definitivo de tablas legacy -> nombres finales.
10) Aún NO se eliminan pre_reservations, test_connection ni tablas históricas.
11) Las tablas de transporte históricas tampoco se migran aquí todavía.
===============================================================================
*/

-- ============================================================================
-- FASE 0 — INVENTARIO Y AUDITORÍA DE LA BASE HISTÓRICA
-- SOLO LECTURA
-- ============================================================================

SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

SELECT
    table_name,
    ordinal_position,
    column_name,
    data_type,
    udt_name,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
ORDER BY table_name, ordinal_position;

SELECT
    tc.table_name,
    kcu.column_name,
    tc.constraint_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
   AND tc.table_schema = kcu.table_schema
WHERE tc.constraint_type = 'PRIMARY KEY'
  AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.ordinal_position;

SELECT
    tc.table_name AS tabla_origen,
    kcu.column_name AS columna_origen,
    ccu.table_name AS tabla_destino,
    ccu.column_name AS columna_destino,
    tc.constraint_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
   AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage ccu
    ON ccu.constraint_name = tc.constraint_name
   AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;

SELECT
    tc.table_schema,
    tc.table_name,
    tc.constraint_type,
    tc.constraint_name,
    kcu.column_name,
    ccu.table_schema AS referenced_schema,
    ccu.table_name AS referenced_table,
    ccu.column_name AS referenced_column
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
   AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.constraint_column_usage ccu
    ON tc.constraint_name = ccu.constraint_name
   AND tc.table_schema = ccu.table_schema
WHERE tc.table_schema = 'public'
ORDER BY
    tc.table_name,
    tc.constraint_type,
    tc.constraint_name,
    kcu.ordinal_position;

SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

SELECT 'categories' AS tabla, COUNT(*) AS registros FROM public.categories
UNION ALL
SELECT 'destinations', COUNT(*) FROM public.destinations
UNION ALL
SELECT 'places', COUNT(*) FROM public.places
UNION ALL
SELECT 'pre_reservations', COUNT(*) FROM public.pre_reservations
UNION ALL
SELECT 'profiles', COUNT(*) FROM public.profiles
UNION ALL
SELECT 'test_connection', COUNT(*) FROM public.test_connection
UNION ALL
SELECT 'transport_routes', COUNT(*) FROM public.transport_routes
UNION ALL
SELECT 'transport_services', COUNT(*) FROM public.transport_services
ORDER BY tabla;

-- ============================================================================
-- FASE 1 — RESPALDO LÓGICO / CONSULTA DE DATOS HISTÓRICOS
-- SOLO LECTURA
-- ============================================================================

SELECT * FROM public.categories ORDER BY id;
SELECT * FROM public.destinations ORDER BY id;
SELECT * FROM public.places ORDER BY id;
SELECT * FROM public.pre_reservations ORDER BY id;
SELECT * FROM public.profiles ORDER BY id;
SELECT * FROM public.test_connection ORDER BY id;
SELECT * FROM public.transport_routes ORDER BY id;
SELECT * FROM public.transport_services ORDER BY id;

-- ============================================================================
-- FASE 2 — STAGING DE LA BASE FUENTE VÁLIDA
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS staging_import;
REVOKE ALL ON SCHEMA staging_import FROM anon, authenticated;

CREATE TABLE IF NOT EXISTS staging_import.categories_source (
    id uuid PRIMARY KEY,
    name varchar NOT NULL,
    type varchar NOT NULL
);

CREATE TABLE IF NOT EXISTS staging_import.places_source (
    id uuid PRIMARY KEY,
    category_id uuid,
    name varchar NOT NULL,
    description_es text,
    description_en text,
    physical_address text,
    latitude double precision,
    longitude double precision,
    schedule text,
    reference_price text,
    contact_info text,
    website_url text,
    image_url text,
    image_author varchar,
    image_license varchar,
    last_verified_date date,
    completeness_status varchar,
    translation_status varchar,
    created_at timestamptz
);

CREATE TABLE IF NOT EXISTS staging_import.informational_content_source (
    id uuid PRIMARY KEY,
    content_type varchar NOT NULL,
    title varchar NOT NULL,
    category varchar,
    description_es text,
    description_en text,
    reference_url text,
    schedule text,
    reference_price text,
    contact_info text,
    created_at timestamptz
);

CREATE TABLE IF NOT EXISTS staging_import.tours_and_activities_source (
    id uuid PRIMARY KEY,
    name varchar NOT NULL,
    category varchar,
    description_es text,
    description_en text,
    meeting_point text,
    latitude double precision,
    longitude double precision,
    schedule text,
    reference_price text,
    contact_info text,
    website_url text,
    image_url text,
    last_verified_date date,
    created_at timestamptz
);

CREATE TABLE IF NOT EXISTS staging_import.legal_compliance_source (
    id uuid PRIMARY KEY,
    rule_name varchar NOT NULL,
    regulatory_body varchar,
    regulated_topic text,
    project_relationship text,
    source_url text,
    last_verified_date date
);

SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'staging_import'
ORDER BY table_name;

-- Validaciones de staging
SELECT 'categories_source' AS tabla, COUNT(*) AS registros
FROM staging_import.categories_source
UNION ALL
SELECT 'informational_content_source', COUNT(*)
FROM staging_import.informational_content_source
UNION ALL
SELECT 'legal_compliance_source', COUNT(*)
FROM staging_import.legal_compliance_source
UNION ALL
SELECT 'places_source', COUNT(*)
FROM staging_import.places_source
UNION ALL
SELECT 'tours_and_activities_source', COUNT(*)
FROM staging_import.tours_and_activities_source
ORDER BY tabla;

SELECT
    (SELECT COUNT(*) FROM staging_import.categories_source)
  + (SELECT COUNT(*) FROM staging_import.informational_content_source)
  + (SELECT COUNT(*) FROM staging_import.legal_compliance_source)
  + (SELECT COUNT(*) FROM staging_import.places_source)
  + (SELECT COUNT(*) FROM staging_import.tours_and_activities_source)
  AS total_registros_fuente;

SELECT id, COUNT(*) FROM staging_import.categories_source GROUP BY id HAVING COUNT(*) > 1;
SELECT id, COUNT(*) FROM staging_import.places_source GROUP BY id HAVING COUNT(*) > 1;
SELECT id, COUNT(*) FROM staging_import.informational_content_source GROUP BY id HAVING COUNT(*) > 1;
SELECT id, COUNT(*) FROM staging_import.tours_and_activities_source GROUP BY id HAVING COUNT(*) > 1;

SELECT
    p.id,
    p.name,
    p.category_id
FROM staging_import.places_source p
LEFT JOIN staging_import.categories_source c
    ON c.id = p.category_id
WHERE p.category_id IS NOT NULL
  AND c.id IS NULL;

SELECT id, name, latitude, longitude
FROM staging_import.places_source
WHERE
    (latitude IS NOT NULL AND (latitude < -90 OR latitude > 90))
 OR (longitude IS NOT NULL AND (longitude < -180 OR longitude > 180));

SELECT id, name, latitude, longitude
FROM staging_import.tours_and_activities_source
WHERE
    (latitude IS NOT NULL AND (latitude < -90 OR latitude > 90))
 OR (longitude IS NOT NULL AND (longitude < -180 OR longitude > 180));

SELECT * FROM staging_import.categories_source
WHERE name IS NULL OR trim(name) = '';

SELECT * FROM staging_import.places_source
WHERE name IS NULL OR trim(name) = '';

SELECT * FROM staging_import.tours_and_activities_source
WHERE name IS NULL OR trim(name) = '';

SELECT
    id,
    name,
    type
FROM staging_import.categories_source
ORDER BY type, name;

SELECT
    c.name AS categoria,
    COUNT(p.id) AS lugares
FROM staging_import.categories_source c
LEFT JOIN staging_import.places_source p
    ON p.category_id = c.id
GROUP BY c.id, c.name
ORDER BY c.name;

SELECT id, COUNT(*)
FROM (
    SELECT id FROM staging_import.places_source
    UNION ALL
    SELECT id FROM staging_import.tours_and_activities_source
) x
GROUP BY id
HAVING COUNT(*) > 1;

SELECT id, name, category
FROM staging_import.tours_and_activities_source
WHERE category IS NULL
   OR trim(category) = '';

-- ============================================================================
-- FASE 3 — MODELO NORMALIZADO V2
-- ============================================================================

BEGIN;

CREATE SCHEMA IF NOT EXISTS project_internal;
REVOKE ALL ON SCHEMA project_internal FROM anon, authenticated;

CREATE OR REPLACE FUNCTION project_internal.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

CREATE TABLE IF NOT EXISTS public.categories_v2 (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    slug text NOT NULL UNIQUE,
    name_es text NOT NULL,
    name_en text,
    description_es text,
    description_en text,
    group_type text,
    image_url text,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT categories_v2_slug_not_empty
        CHECK (length(trim(slug)) > 0),
    CONSTRAINT categories_v2_name_es_not_empty
        CHECK (length(trim(name_es)) > 0)
);

CREATE TRIGGER categories_v2_set_updated_at
BEFORE UPDATE ON public.categories_v2
FOR EACH ROW
EXECUTE FUNCTION project_internal.set_updated_at();

CREATE TABLE IF NOT EXISTS public.places_v2 (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    category_id uuid NOT NULL,
    kind text NOT NULL DEFAULT 'place',
    name_es text NOT NULL,
    name_en text,
    description_es text,
    description_en text,
    address text,
    meeting_point text,
    latitude double precision,
    longitude double precision,
    schedule text,
    reference_price text,
    contact_info text,
    website_url text,
    last_verified_date date,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    retired_at timestamptz,
    CONSTRAINT places_v2_category_fk
        FOREIGN KEY (category_id)
        REFERENCES public.categories_v2(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT places_v2_kind_check
        CHECK (kind IN ('place', 'activity')),
    CONSTRAINT places_v2_name_es_not_empty
        CHECK (length(trim(name_es)) > 0),
    CONSTRAINT places_v2_latitude_check
        CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),
    CONSTRAINT places_v2_longitude_check
        CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180),
    CONSTRAINT places_v2_coordinates_pair
        CHECK (
            (latitude IS NULL AND longitude IS NULL)
            OR
            (latitude IS NOT NULL AND longitude IS NOT NULL)
        )
);

CREATE INDEX IF NOT EXISTS idx_places_v2_category_id
ON public.places_v2(category_id);

CREATE INDEX IF NOT EXISTS idx_places_v2_active
ON public.places_v2(is_active);

CREATE INDEX IF NOT EXISTS idx_places_v2_kind
ON public.places_v2(kind);

CREATE TRIGGER places_v2_set_updated_at
BEFORE UPDATE ON public.places_v2
FOR EACH ROW
EXECUTE FUNCTION project_internal.set_updated_at();

CREATE TABLE IF NOT EXISTS public.place_media_v2 (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    place_id uuid NOT NULL,
    storage_path text,
    external_url text,
    author text,
    license text,
    alt_text_es text,
    alt_text_en text,
    sort_order integer NOT NULL DEFAULT 0,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT place_media_v2_place_fk
        FOREIGN KEY (place_id)
        REFERENCES public.places_v2(id)
        ON DELETE CASCADE,
    CONSTRAINT place_media_v2_source_check
        CHECK (
            storage_path IS NOT NULL
            OR external_url IS NOT NULL
        ),
    CONSTRAINT place_media_v2_sort_order_check
        CHECK (sort_order >= 0)
);

CREATE INDEX IF NOT EXISTS idx_place_media_v2_place_id
ON public.place_media_v2(place_id);

CREATE TABLE IF NOT EXISTS public.informational_content_v2 (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    content_type text NOT NULL,
    title_es text NOT NULL,
    title_en text,
    category text,
    description_es text,
    description_en text,
    reference_url text,
    schedule text,
    reference_price text,
    contact_info text,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT informational_content_v2_type_not_empty
        CHECK (length(trim(content_type)) > 0),
    CONSTRAINT informational_content_v2_title_not_empty
        CHECK (length(trim(title_es)) > 0)
);

CREATE TRIGGER informational_content_v2_set_updated_at
BEFORE UPDATE ON public.informational_content_v2
FOR EACH ROW
EXECUTE FUNCTION project_internal.set_updated_at();

CREATE TABLE IF NOT EXISTS public.profiles_v2 (
    user_id uuid PRIMARY KEY,
    full_name text,
    preferred_language varchar(2) NOT NULL DEFAULT 'es',
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT profiles_v2_user_fk
        FOREIGN KEY (user_id)
        REFERENCES auth.users(id)
        ON DELETE CASCADE,
    CONSTRAINT profiles_v2_language_check
        CHECK (preferred_language IN ('es', 'en'))
);

CREATE TRIGGER profiles_v2_set_updated_at
BEFORE UPDATE ON public.profiles_v2
FOR EACH ROW
EXECUTE FUNCTION project_internal.set_updated_at();

CREATE TABLE IF NOT EXISTS public.itineraries_v2 (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    name text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT itineraries_v2_user_fk
        FOREIGN KEY (user_id)
        REFERENCES auth.users(id)
        ON DELETE CASCADE,
    CONSTRAINT itineraries_v2_name_not_empty
        CHECK (length(trim(name)) > 0)
);

CREATE INDEX IF NOT EXISTS idx_itineraries_v2_user_id
ON public.itineraries_v2(user_id);

CREATE TRIGGER itineraries_v2_set_updated_at
BEFORE UPDATE ON public.itineraries_v2
FOR EACH ROW
EXECUTE FUNCTION project_internal.set_updated_at();

CREATE TABLE IF NOT EXISTS public.itinerary_items_v2 (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    itinerary_id uuid NOT NULL,
    place_id uuid NOT NULL,
    position integer NOT NULL,
    planned_time time,
    notes text,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT itinerary_items_v2_itinerary_fk
        FOREIGN KEY (itinerary_id)
        REFERENCES public.itineraries_v2(id)
        ON DELETE CASCADE,
    CONSTRAINT itinerary_items_v2_place_fk
        FOREIGN KEY (place_id)
        REFERENCES public.places_v2(id)
        ON DELETE RESTRICT,
    CONSTRAINT itinerary_items_v2_position_check
        CHECK (position >= 0),
    CONSTRAINT itinerary_items_v2_unique_position
        UNIQUE (itinerary_id, position)
);

CREATE INDEX IF NOT EXISTS idx_itinerary_items_v2_itinerary
ON public.itinerary_items_v2(itinerary_id);

CREATE INDEX IF NOT EXISTS idx_itinerary_items_v2_place
ON public.itinerary_items_v2(place_id);

CREATE TABLE IF NOT EXISTS public.admin_audit_v2 (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_user_id uuid,
    entity_type text NOT NULL,
    entity_id uuid NOT NULL,
    action text NOT NULL,
    metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT admin_audit_v2_actor_fk
        FOREIGN KEY (actor_user_id)
        REFERENCES auth.users(id)
        ON DELETE SET NULL,
    CONSTRAINT admin_audit_v2_action_check
        CHECK (
            action IN (
                'create',
                'update',
                'activate',
                'deactivate',
                'retire'
            )
        )
);

CREATE INDEX IF NOT EXISTS idx_admin_audit_v2_entity
ON public.admin_audit_v2(entity_type, entity_id);

CREATE INDEX IF NOT EXISTS idx_admin_audit_v2_actor
ON public.admin_audit_v2(actor_user_id);

CREATE TABLE IF NOT EXISTS project_internal.legal_compliance (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_name text NOT NULL,
    regulatory_body text,
    regulated_topic text,
    project_relationship text,
    source_url text,
    last_verified_date date,
    created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.categories_v2 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.places_v2 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.place_media_v2 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.informational_content_v2 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles_v2 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.itineraries_v2 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.itinerary_items_v2 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_audit_v2 ENABLE ROW LEVEL SECURITY;

COMMIT;

-- Verificación de estructura V2
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_name LIKE '%_v2'
ORDER BY table_schema, table_name;

SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_schema = 'project_internal'
ORDER BY table_name;

SELECT
    tc.table_name AS tabla_origen,
    kcu.column_name AS columna_origen,
    ccu.table_schema AS esquema_destino,
    ccu.table_name AS tabla_destino,
    ccu.column_name AS columna_destino
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
   AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage ccu
    ON tc.constraint_name = ccu.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name LIKE '%_v2'
ORDER BY tc.table_name, kcu.column_name;

SELECT 'categories_v2' tabla, COUNT(*) registros FROM public.categories_v2
UNION ALL
SELECT 'places_v2', COUNT(*) FROM public.places_v2
UNION ALL
SELECT 'place_media_v2', COUNT(*) FROM public.place_media_v2
UNION ALL
SELECT 'informational_content_v2', COUNT(*) FROM public.informational_content_v2
UNION ALL
SELECT 'profiles_v2', COUNT(*) FROM public.profiles_v2
UNION ALL
SELECT 'itineraries_v2', COUNT(*) FROM public.itineraries_v2
UNION ALL
SELECT 'itinerary_items_v2', COUNT(*) FROM public.itinerary_items_v2
UNION ALL
SELECT 'admin_audit_v2', COUNT(*) FROM public.admin_audit_v2;

-- ============================================================================
-- FASE 4 — MIGRACIÓN DE DATOS REALES DESDE STAGING A V2
-- ============================================================================

INSERT INTO public.categories_v2 (
    id,
    slug,
    name_es,
    name_en,
    group_type,
    is_active,
    created_at,
    updated_at
)
SELECT
    id,
    trim(
        both '-' from
        regexp_replace(
            translate(
                lower(trim(name)),
                'áéíóúüñ',
                'aeiouun'
            ),
            '[^a-z0-9]+',
            '-',
            'g'
        )
    ) AS slug,
    trim(name) AS name_es,
    NULL AS name_en,
    type AS group_type,
    true,
    now(),
    now()
FROM staging_import.categories_source
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.categories_v2 (
    slug,
    name_es,
    name_en,
    group_type,
    is_active
)
SELECT DISTINCT
    trim(
        both '-' from
        regexp_replace(
            translate(
                lower(trim(t.category)),
                'áéíóúüñ',
                'aeiouun'
            ),
            '[^a-z0-9]+',
            '-',
            'g'
        )
    ) AS slug,
    trim(t.category),
    NULL,
    'activity',
    true
FROM staging_import.tours_and_activities_source t
WHERE t.category IS NOT NULL
  AND trim(t.category) <> ''
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.places_v2 (
    id,
    category_id,
    kind,
    name_es,
    name_en,
    description_es,
    description_en,
    address,
    latitude,
    longitude,
    schedule,
    reference_price,
    contact_info,
    website_url,
    last_verified_date,
    is_active,
    created_at,
    updated_at
)
SELECT
    p.id,
    p.category_id,
    'place',
    p.name,
    NULL,
    p.description_es,
    p.description_en,
    p.physical_address,
    p.latitude,
    p.longitude,
    p.schedule,
    p.reference_price,
    p.contact_info,
    p.website_url,
    p.last_verified_date,
    true,
    COALESCE(p.created_at, now()),
    now()
FROM staging_import.places_source p
JOIN public.categories_v2 c
    ON c.id = p.category_id
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.places_v2 (
    id,
    category_id,
    kind,
    name_es,
    name_en,
    description_es,
    description_en,
    meeting_point,
    latitude,
    longitude,
    schedule,
    reference_price,
    contact_info,
    website_url,
    last_verified_date,
    is_active,
    created_at,
    updated_at
)
SELECT
    t.id,
    c.id,
    'activity',
    t.name,
    NULL,
    t.description_es,
    t.description_en,
    t.meeting_point,
    t.latitude,
    t.longitude,
    t.schedule,
    t.reference_price,
    t.contact_info,
    t.website_url,
    t.last_verified_date,
    true,
    COALESCE(t.created_at, now()),
    now()
FROM staging_import.tours_and_activities_source t
JOIN public.categories_v2 c
    ON c.slug =
        trim(
            both '-' from
            regexp_replace(
                translate(
                    lower(trim(t.category)),
                    'áéíóúüñ',
                    'aeiouun'
                ),
                '[^a-z0-9]+',
                '-',
                'g'
            )
        )
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.place_media_v2 (
    place_id,
    external_url,
    author,
    license,
    sort_order,
    is_active
)
SELECT
    p.id,
    p.image_url,
    p.image_author,
    p.image_license,
    0,
    true
FROM staging_import.places_source p
WHERE p.image_url IS NOT NULL
  AND trim(p.image_url) <> '';

INSERT INTO public.place_media_v2 (
    place_id,
    external_url,
    sort_order,
    is_active
)
SELECT
    t.id,
    t.image_url,
    0,
    true
FROM staging_import.tours_and_activities_source t
WHERE t.image_url IS NOT NULL
  AND trim(t.image_url) <> '';

INSERT INTO public.informational_content_v2 (
    id,
    content_type,
    title_es,
    title_en,
    category,
    description_es,
    description_en,
    reference_url,
    schedule,
    reference_price,
    contact_info,
    is_active,
    created_at,
    updated_at
)
SELECT
    id,
    content_type,
    title,
    NULL,
    category,
    description_es,
    description_en,
    reference_url,
    schedule,
    reference_price,
    contact_info,
    true,
    COALESCE(created_at, now()),
    now()
FROM staging_import.informational_content_source
ON CONFLICT (id) DO NOTHING;

INSERT INTO project_internal.legal_compliance (
    id,
    rule_name,
    regulatory_body,
    regulated_topic,
    project_relationship,
    source_url,
    last_verified_date
)
SELECT
    id,
    rule_name,
    regulatory_body,
    regulated_topic,
    project_relationship,
    source_url,
    last_verified_date
FROM staging_import.legal_compliance_source
ON CONFLICT (id) DO NOTHING;

-- Validación post-migración
SELECT kind, COUNT(*) AS registros
FROM public.places_v2
GROUP BY kind
ORDER BY kind;

SELECT pm.*
FROM public.place_media_v2 pm
LEFT JOIN public.places_v2 p
    ON p.id = pm.place_id
WHERE p.id IS NULL;

SELECT 'categories_v2' AS tabla, COUNT(*) registros FROM public.categories_v2
UNION ALL
SELECT 'places_v2', COUNT(*) FROM public.places_v2
UNION ALL
SELECT 'place_media_v2', COUNT(*) FROM public.place_media_v2
UNION ALL
SELECT 'informational_content_v2', COUNT(*) FROM public.informational_content_v2
UNION ALL
SELECT 'legal_compliance', COUNT(*) FROM project_internal.legal_compliance
ORDER BY tabla;

SELECT
    p.id,
    p.name_es,
    p.category_id
FROM public.places_v2 p
LEFT JOIN public.categories_v2 c
    ON c.id = p.category_id
WHERE c.id IS NULL;

SELECT
    p.kind,
    p.name_es,
    c.name_es AS categoria,
    p.latitude,
    p.longitude,
    p.is_active
FROM public.places_v2 p
JOIN public.categories_v2 c
    ON c.id = p.category_id
ORDER BY p.kind, c.name_es, p.name_es;

-- ============================================================================
-- FASE 5 — PERMISOS, RLS Y AUDITORÍA
-- ============================================================================

CREATE TABLE IF NOT EXISTS project_internal.user_roles (
    user_id uuid PRIMARY KEY,
    role text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT user_roles_user_fk
        FOREIGN KEY (user_id)
        REFERENCES auth.users(id)
        ON DELETE CASCADE,
    CONSTRAINT user_roles_role_check
        CHECK (role IN ('admin'))
);

REVOKE ALL
ON project_internal.user_roles
FROM anon, authenticated;

-- Necesario para poder invocar project_internal.is_admin() desde RLS.
-- No otorga acceso a tablas internas.
GRANT USAGE
ON SCHEMA project_internal
TO authenticated;

CREATE OR REPLACE FUNCTION project_internal.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM project_internal.user_roles ur
        WHERE ur.user_id = (SELECT auth.uid())
          AND ur.role = 'admin'
    );
$$;

REVOKE ALL
ON FUNCTION project_internal.is_admin()
FROM PUBLIC;

GRANT EXECUTE
ON FUNCTION project_internal.is_admin()
TO authenticated;

REVOKE ALL ON public.categories_v2 FROM anon, authenticated;
REVOKE ALL ON public.places_v2 FROM anon, authenticated;
REVOKE ALL ON public.place_media_v2 FROM anon, authenticated;
REVOKE ALL ON public.informational_content_v2 FROM anon, authenticated;
REVOKE ALL ON public.profiles_v2 FROM anon, authenticated;
REVOKE ALL ON public.itineraries_v2 FROM anon, authenticated;
REVOKE ALL ON public.itinerary_items_v2 FROM anon, authenticated;
REVOKE ALL ON public.admin_audit_v2 FROM anon, authenticated;

GRANT SELECT
ON public.categories_v2,
   public.places_v2,
   public.place_media_v2,
   public.informational_content_v2
TO anon;

GRANT SELECT
ON public.categories_v2,
   public.places_v2,
   public.place_media_v2,
   public.informational_content_v2
TO authenticated;

GRANT INSERT, UPDATE
ON public.categories_v2,
   public.places_v2,
   public.place_media_v2,
   public.informational_content_v2
TO authenticated;

-- Categorías
CREATE POLICY "public_read_active_categories"
ON public.categories_v2
FOR SELECT
TO anon, authenticated
USING (is_active = true);

CREATE POLICY "admin_read_all_categories"
ON public.categories_v2
FOR SELECT
TO authenticated
USING ((SELECT project_internal.is_admin()));

CREATE POLICY "admin_insert_categories"
ON public.categories_v2
FOR INSERT
TO authenticated
WITH CHECK ((SELECT project_internal.is_admin()));

CREATE POLICY "admin_update_categories"
ON public.categories_v2
FOR UPDATE
TO authenticated
USING ((SELECT project_internal.is_admin()))
WITH CHECK ((SELECT project_internal.is_admin()));

-- Lugares / actividades
CREATE POLICY "public_read_active_places"
ON public.places_v2
FOR SELECT
TO anon, authenticated
USING (
    is_active = true
    AND retired_at IS NULL
);

CREATE POLICY "admin_read_all_places"
ON public.places_v2
FOR SELECT
TO authenticated
USING ((SELECT project_internal.is_admin()));

CREATE POLICY "admin_insert_places"
ON public.places_v2
FOR INSERT
TO authenticated
WITH CHECK ((SELECT project_internal.is_admin()));

CREATE POLICY "admin_update_places"
ON public.places_v2
FOR UPDATE
TO authenticated
USING ((SELECT project_internal.is_admin()))
WITH CHECK ((SELECT project_internal.is_admin()));

-- Medios / imágenes
CREATE POLICY "public_read_active_place_media"
ON public.place_media_v2
FOR SELECT
TO anon, authenticated
USING (
    is_active = true
    AND EXISTS (
        SELECT 1
        FROM public.places_v2 p
        WHERE p.id = place_media_v2.place_id
          AND p.is_active = true
          AND p.retired_at IS NULL
    )
);

CREATE POLICY "admin_read_all_place_media"
ON public.place_media_v2
FOR SELECT
TO authenticated
USING ((SELECT project_internal.is_admin()));

CREATE POLICY "admin_insert_place_media"
ON public.place_media_v2
FOR INSERT
TO authenticated
WITH CHECK ((SELECT project_internal.is_admin()));

CREATE POLICY "admin_update_place_media"
ON public.place_media_v2
FOR UPDATE
TO authenticated
USING ((SELECT project_internal.is_admin()))
WITH CHECK ((SELECT project_internal.is_admin()));

-- Contenido informativo
CREATE POLICY "public_read_active_information"
ON public.informational_content_v2
FOR SELECT
TO anon, authenticated
USING (is_active = true);

CREATE POLICY "admin_read_all_information"
ON public.informational_content_v2
FOR SELECT
TO authenticated
USING ((SELECT project_internal.is_admin()));

CREATE POLICY "admin_insert_information"
ON public.informational_content_v2
FOR INSERT
TO authenticated
WITH CHECK ((SELECT project_internal.is_admin()));

CREATE POLICY "admin_update_information"
ON public.informational_content_v2
FOR UPDATE
TO authenticated
USING ((SELECT project_internal.is_admin()))
WITH CHECK ((SELECT project_internal.is_admin()));

-- Perfiles
GRANT SELECT, INSERT, UPDATE
ON public.profiles_v2
TO authenticated;

CREATE POLICY "user_read_own_profile"
ON public.profiles_v2
FOR SELECT
TO authenticated
USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "user_create_own_profile"
ON public.profiles_v2
FOR INSERT
TO authenticated
WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "user_update_own_profile"
ON public.profiles_v2
FOR UPDATE
TO authenticated
USING ((SELECT auth.uid()) = user_id)
WITH CHECK ((SELECT auth.uid()) = user_id);

-- Itinerarios
GRANT SELECT, INSERT, UPDATE, DELETE
ON public.itineraries_v2
TO authenticated;

CREATE POLICY "user_read_own_itineraries"
ON public.itineraries_v2
FOR SELECT
TO authenticated
USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "user_create_own_itineraries"
ON public.itineraries_v2
FOR INSERT
TO authenticated
WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "user_update_own_itineraries"
ON public.itineraries_v2
FOR UPDATE
TO authenticated
USING ((SELECT auth.uid()) = user_id)
WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "user_delete_own_itineraries"
ON public.itineraries_v2
FOR DELETE
TO authenticated
USING ((SELECT auth.uid()) = user_id);

-- Ítems de itinerario
GRANT SELECT, INSERT, UPDATE, DELETE
ON public.itinerary_items_v2
TO authenticated;

CREATE POLICY "user_read_own_itinerary_items"
ON public.itinerary_items_v2
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.itineraries_v2 i
        WHERE i.id = itinerary_items_v2.itinerary_id
          AND i.user_id = (SELECT auth.uid())
    )
);

CREATE POLICY "user_create_own_itinerary_items"
ON public.itinerary_items_v2
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.itineraries_v2 i
        WHERE i.id = itinerary_items_v2.itinerary_id
          AND i.user_id = (SELECT auth.uid())
    )
);

CREATE POLICY "user_update_own_itinerary_items"
ON public.itinerary_items_v2
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.itineraries_v2 i
        WHERE i.id = itinerary_items_v2.itinerary_id
          AND i.user_id = (SELECT auth.uid())
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.itineraries_v2 i
        WHERE i.id = itinerary_items_v2.itinerary_id
          AND i.user_id = (SELECT auth.uid())
    )
);

CREATE POLICY "user_delete_own_itinerary_items"
ON public.itinerary_items_v2
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.itineraries_v2 i
        WHERE i.id = itinerary_items_v2.itinerary_id
          AND i.user_id = (SELECT auth.uid())
    )
);

-- Auditoría automática administrativa
CREATE OR REPLACE FUNCTION project_internal.audit_content_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
    v_action text;
    v_entity_id uuid;
    v_old jsonb;
    v_new jsonb;
BEGIN
    IF TG_OP = 'INSERT' THEN
        v_action := 'create';
        v_new := to_jsonb(NEW);
        v_entity_id := (v_new ->> 'id')::uuid;

    ELSIF TG_OP = 'UPDATE' THEN
        v_old := to_jsonb(OLD);
        v_new := to_jsonb(NEW);
        v_entity_id := (v_new ->> 'id')::uuid;

        IF
            v_new ? 'retired_at'
            AND v_new ->> 'retired_at' IS NOT NULL
            AND (
                NOT (v_old ? 'retired_at')
                OR v_old ->> 'retired_at' IS NULL
            )
        THEN
            v_action := 'retire';

        ELSIF
            (v_old ->> 'is_active')::boolean = true
            AND (v_new ->> 'is_active')::boolean = false
        THEN
            v_action := 'deactivate';

        ELSIF
            (v_old ->> 'is_active')::boolean = false
            AND (v_new ->> 'is_active')::boolean = true
        THEN
            v_action := 'activate';

        ELSE
            v_action := 'update';
        END IF;

    ELSE
        RETURN NEW;
    END IF;

    INSERT INTO public.admin_audit_v2 (
        actor_user_id,
        entity_type,
        entity_id,
        action,
        metadata
    )
    VALUES (
        (SELECT auth.uid()),
        TG_TABLE_NAME,
        v_entity_id,
        v_action,
        jsonb_build_object(
            'old', v_old,
            'new', v_new
        )
    );

    RETURN NEW;
END;
$$;

REVOKE ALL
ON FUNCTION project_internal.audit_content_change()
FROM PUBLIC, anon, authenticated;

CREATE TRIGGER audit_categories_v2
AFTER INSERT OR UPDATE
ON public.categories_v2
FOR EACH ROW
EXECUTE FUNCTION project_internal.audit_content_change();

CREATE TRIGGER audit_places_v2
AFTER INSERT OR UPDATE
ON public.places_v2
FOR EACH ROW
EXECUTE FUNCTION project_internal.audit_content_change();

CREATE TRIGGER audit_information_v2
AFTER INSERT OR UPDATE
ON public.informational_content_v2
FOR EACH ROW
EXECUTE FUNCTION project_internal.audit_content_change();

GRANT SELECT
ON public.admin_audit_v2
TO authenticated;

CREATE POLICY "admins_read_audit"
ON public.admin_audit_v2
FOR SELECT
TO authenticated
USING ((SELECT project_internal.is_admin()));

-- Designación del primer administrador:
-- 1) buscar UUID real
SELECT id, email, created_at
FROM auth.users
ORDER BY created_at;

-- 2) reemplazar el UUID antes de ejecutar:
-- INSERT INTO project_internal.user_roles (user_id, role)
-- VALUES ('UUID_DE_TU_USUARIO', 'admin')
-- ON CONFLICT (user_id)
-- DO UPDATE SET role = EXCLUDED.role;

SELECT *
FROM project_internal.user_roles;

-- ============================================================================
-- FASE 6 — VERIFICACIONES FINALES HASTA ESTE PUNTO
-- ============================================================================

SELECT
    tablename,
    rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename LIKE '%_v2'
ORDER BY tablename;

SELECT
    tablename,
    policyname,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename LIKE '%_v2'
ORDER BY tablename, policyname;

SELECT
    table_name,
    grantee,
    privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND table_name LIKE '%_v2'
  AND grantee IN ('anon', 'authenticated')
ORDER BY table_name, grantee, privilege_type;

/*
===============================================================================
 ESTADO ACTUAL

 LEGACY AÚN CONSERVADO
 ---------------------
 public.categories
 public.destinations
 public.places
 public.pre_reservations
 public.profiles
 public.test_connection
 public.transport_routes
 public.transport_services

 STAGING
 -------
 staging_import.categories_source
 staging_import.places_source
 staging_import.informational_content_source
 staging_import.tours_and_activities_source
 staging_import.legal_compliance_source

 V2
 --
 public.categories_v2
 public.places_v2
 public.place_media_v2
 public.informational_content_v2
 public.profiles_v2
 public.itineraries_v2
 public.itinerary_items_v2
 public.admin_audit_v2

 INTERNO
 -------
 project_internal.legal_compliance
 project_internal.user_roles
 project_internal.set_updated_at()
 project_internal.is_admin()
 project_internal.audit_content_change()

 PENDIENTE
 ---------
 1) probar acceso real como anon, authenticated y admin;
 2) decidir y normalizar el módulo histórico de transporte;
 3) hacer el corte definitivo de *_v2 a nombres productivos;
 4) mantener legacy y staging hasta verificar Flutter y rollback;
 5) generar migración formal versionada del esquema final.
===============================================================================
*/
