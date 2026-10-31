-- =====================================================================
-- Coyhaique BaseCamp · Migración 2026-10-30
-- Jerarquía de categorías: 6 categorías principales + subcategorías
-- =====================================================================
--
-- Qué hace:
--   1. Agrega a categories_v2 las columnas parent_id (subcategoría → principal)
--      y sort_order (orden de presentación).
--   2. Crea o actualiza las 6 categorías principales. Su slug es igual a su
--      group_type (atractivo, actividad, gastronomia, alojamiento, transporte,
--      servicio), que es lo que la aplicación ya usa para abrir cada grupo.
--   3. Crea o actualiza 26 subcategorías, cada una con su principal.
--   4. Reasigna places_v2.category_id de las 50 categorías antiguas a la
--      subcategoría que corresponde (por nombre).
--   5. Desactiva (is_active = false, no borra) las categorías antiguas que
--      quedaron sin lugares. Si alguna antigua todavía tiene lugares, queda
--      activa y aparece en la consulta de verificación del final.
--
-- Cómo ejecutarla:
--   - Hacer antes un respaldo (Database → Backups, o exportar categories_v2 y
--     places_v2 a CSV).
--   - Pegar todo en Supabase → SQL Editor y ejecutar. Corre en una sola
--     transacción: si algo falla, no se aplica nada.
--   - Es idempotente: ejecutarla dos veces deja el mismo resultado.
--   - Usa tablas auxiliares normales en el esquema project_internal (no
--     tablas temporales), porque el SQL Editor de Supabase puede ejecutar
--     cada sentencia por separado; al final se eliminan.
--
-- Subcategorías nuevas sin lugares todavía (la aplicación las oculta hasta
-- que tengan al menos uno): Fuentes de soda y colaciones, Baños públicos.
-- =====================================================================

BEGIN;

-- ---------------------------------------------------------------------
-- 1. Estructura
-- ---------------------------------------------------------------------

ALTER TABLE public.categories_v2
    ADD COLUMN IF NOT EXISTS parent_id uuid
        REFERENCES public.categories_v2 (id) ON DELETE RESTRICT,
    ADD COLUMN IF NOT EXISTS sort_order integer NOT NULL DEFAULT 0;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'categories_v2_parent_not_self'
    ) THEN
        ALTER TABLE public.categories_v2
            ADD CONSTRAINT categories_v2_parent_not_self
            CHECK (parent_id IS NULL OR parent_id <> id);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS categories_v2_parent_id_idx
    ON public.categories_v2 (parent_id);

-- ---------------------------------------------------------------------
-- 2. Árbol nuevo (principales con parent_slug NULL)
-- ---------------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS project_internal;

DROP TABLE IF EXISTS project_internal.migr_cat_tree;

CREATE TABLE project_internal.migr_cat_tree (
    slug        text PRIMARY KEY,
    parent_slug text,
    name_es     text NOT NULL,
    name_en     text NOT NULL,
    group_type  text NOT NULL,
    sort_order  integer NOT NULL
);

INSERT INTO project_internal.migr_cat_tree (slug, parent_slug, name_es, name_en, group_type, sort_order) VALUES
-- Principales
('atractivo',   NULL, 'Atractivos',          'Attractions',          'atractivo',   1),
('actividad',   NULL, 'Actividades y tours', 'Activities and tours', 'actividad',   2),
('gastronomia', NULL, 'Gastronomía',         'Food and drink',       'gastronomia', 3),
('alojamiento', NULL, 'Alojamiento',         'Accommodation',        'alojamiento', 4),
('transporte',  NULL, 'Transporte',          'Transport',            'transporte',  5),
('servicio',    NULL, 'Servicios',           'Services',             'servicio',    6),
-- Atractivos
('naturaleza-areas-protegidas', 'atractivo', 'Naturaleza y áreas protegidas', 'Nature and protected areas', 'atractivo', 1),
('miradores',             'atractivo', 'Miradores',               'Viewpoints',             'atractivo', 2),
('museos-cultura',        'atractivo', 'Museos y cultura',        'Museums and culture',    'atractivo', 3),
('patrimonio-monumentos', 'atractivo', 'Patrimonio y monumentos', 'Heritage and monuments', 'atractivo', 4),
('plazas-parques',        'atractivo', 'Plazas y parques',        'Squares and parks',      'atractivo', 5),
('entretencion',          'atractivo', 'Entretención',            'Entertainment',          'atractivo', 6),
('turismo-industrial',    'atractivo', 'Turismo industrial',      'Industrial tourism',     'atractivo', 7),
-- Actividades y tours
('excursiones',            'actividad', 'Excursiones',               'Excursions',        'actividad', 1),
('aventura',               'actividad', 'Aventura',                  'Adventure',         'actividad', 2),
('kayak',                  'actividad', 'Kayak y navegación',        'Kayak and boating', 'actividad', 3),
('ciclismo',               'actividad', 'Ciclismo',                  'Cycling',           'actividad', 4),
('observacion-naturaleza', 'actividad', 'Observación de naturaleza', 'Nature watching',   'actividad', 5),
('pesca',                  'actividad', 'Pesca',                     'Fishing',           'actividad', 6),
-- Gastronomía
('cafeterias',         'gastronomia', 'Cafeterías',                      'Cafés',                           'gastronomia', 1),
('restaurantes',       'gastronomia', 'Restaurantes',                    'Restaurants',                     'gastronomia', 2),
('comida-tradicional', 'gastronomia', 'Comida tradicional y patagónica', 'Traditional and Patagonian food', 'gastronomia', 3),
('fuentes-de-soda',    'gastronomia', 'Fuentes de soda y colaciones',    'Diners and set lunches',          'gastronomia', 4),
-- Alojamiento
('hoteles',       'alojamiento', 'Hoteles',                  'Hotels',             'alojamiento', 1),
('cabanas',       'alojamiento', 'Cabañas',                  'Cabins',             'alojamiento', 2),
('departamentos', 'alojamiento', 'Departamentos turísticos', 'Holiday apartments', 'alojamiento', 3),
-- Transporte
('buses',      'transporte', 'Buses',      'Buses',      'transporte', 1),
('rent-a-car', 'transporte', 'Rent a car', 'Car rental', 'transporte', 2),
-- Servicios
('bencineras',        'servicio', 'Bencineras',        'Gas stations',     'servicio', 1),
('estacionamientos',  'servicio', 'Estacionamientos',  'Parking',          'servicio', 2),
('banos-publicos',    'servicio', 'Baños públicos',    'Public restrooms', 'servicio', 3),
('agencias-de-viaje', 'servicio', 'Agencias de viaje', 'Travel agencies',  'servicio', 4);

-- Crea o actualiza cada categoría del árbol (por slug).
INSERT INTO public.categories_v2 (slug, name_es, name_en, group_type, sort_order, is_active)
SELECT slug, name_es, name_en, group_type, sort_order, true
FROM project_internal.migr_cat_tree
ON CONFLICT (slug) DO UPDATE SET
    name_es    = EXCLUDED.name_es,
    name_en    = EXCLUDED.name_en,
    group_type = EXCLUDED.group_type,
    sort_order = EXCLUDED.sort_order,
    is_active  = true;

-- Enlaza cada subcategoría con su principal; las principales quedan sin padre.
UPDATE public.categories_v2 c
SET parent_id = p.id
FROM project_internal.migr_cat_tree t
JOIN public.categories_v2 p ON p.slug = t.parent_slug
WHERE c.slug = t.slug
  AND t.parent_slug IS NOT NULL
  AND c.parent_id IS DISTINCT FROM p.id;

UPDATE public.categories_v2 c
SET parent_id = NULL
FROM project_internal.migr_cat_tree t
WHERE c.slug = t.slug
  AND t.parent_slug IS NULL
  AND c.parent_id IS NOT NULL;

-- ---------------------------------------------------------------------
-- 3. Equivalencias: categoría antigua (por nombre) → subcategoría nueva
-- ---------------------------------------------------------------------

DROP TABLE IF EXISTS project_internal.migr_cat_map;

CREATE TABLE project_internal.migr_cat_map (
    old_name text PRIMARY KEY,
    new_slug text NOT NULL
);

INSERT INTO project_internal.migr_cat_map (old_name, new_slug) VALUES
-- Atractivos
('Área Silvestre Protegida',            'naturaleza-areas-protegidas'),
('Reserva',                             'naturaleza-areas-protegidas'),
('Atractivo Natural',                   'naturaleza-areas-protegidas'),
('Atractivo Natural / Lago',            'naturaleza-areas-protegidas'),
('Mirador',                             'miradores'),
('Museo',                               'museos-cultura'),
('Institución Cultural',                'museos-cultura'),
('Institución / Espacio Cultural',      'museos-cultura'),
('Monumento Histórico',                 'patrimonio-monumentos'),
('Monumento / Atractivo Urbano',        'patrimonio-monumentos'),
('Plaza',                               'plazas-parques'),
('Parque Urbano / Recreación',          'plazas-parques'),
('Centro de Entretención / Casino',     'entretencion'),
('Turismo Gastronómico / Industrial',   'turismo-industrial'),
('Turismo Gastronómico',                'turismo-industrial'),
-- Actividades y tours
('Tour / Excursión',                    'excursiones'),
('Tour Operador',                       'excursiones'),
('Recorridos',                          'excursiones'),
('Actividad / Aventura',                'aventura'),
('Tour / Turismo Aventura',             'aventura'),
('Tour / Kayak',                        'kayak'),
('Tour / Ciclismo',                     'ciclismo'),
('Ciclismo',                            'ciclismo'),
('Tour / Observación de Naturaleza',    'observacion-naturaleza'),
('Pesca',                               'pesca'),
-- Gastronomía
('Cafetería',                                 'cafeterias'),
('Cafetería / Chocolatería',                  'cafeterias'),
('Cafetería / Desayunos',                     'cafeterias'),
('Cafetería / Pastelería Alemana',            'cafeterias'),
('Cafetería / Repostería',                    'cafeterias'),
('Cafetería de Especialidad',                 'cafeterias'),
('Restaurante / Bar',                         'restaurantes'),
('Restaurante / Cocina Fusión',               'restaurantes'),
('Restaurante / Comida Japonesa y Mexicana',  'restaurantes'),
('Restaurante / Sushi y Fusión',              'restaurantes'),
('Restaurante / Pizzería y Comida Regional',  'restaurantes'),
('Restaurante / Comida Casera y Tradicional', 'comida-tradicional'),
('Restaurante / Comida Chilena y Fusión',     'comida-tradicional'),
('Restaurante / Comida Típica y Parrilladas', 'comida-tradicional'),
('Restaurante de Gastronomía Patagónica',     'comida-tradicional'),
-- Alojamiento
('Hotel',                    'hoteles'),
('Hotel Boutique',           'hoteles'),
('Lodge / Hotel',            'hoteles'),
('Cabañas',                  'cabanas'),
('Departamentos Turísticos', 'departamentos'),
-- Transporte
('Transporte / Bus interurbano',         'buses'),
('Transporte / Bus Rural e Interurbano', 'buses'),
('Transporte / Rent a Car',              'rent-a-car'),
-- Servicios
('Servicios Básicos / Estación de Servicio',  'bencineras'),
('Infraestructura / Estacionamiento Privado', 'estacionamientos'),
('Receptivo y emisivo',                       'agencias-de-viaje');

-- ---------------------------------------------------------------------
-- 4. Reasignar lugares y actividades
-- ---------------------------------------------------------------------

UPDATE public.places_v2 p
SET category_id = n.id
FROM public.categories_v2 o
JOIN project_internal.migr_cat_map m ON lower(trim(o.name_es)) = lower(trim(m.old_name))
JOIN public.categories_v2 n ON n.slug = m.new_slug
WHERE p.category_id = o.id
  AND o.id <> n.id
  AND o.slug NOT IN (SELECT slug FROM project_internal.migr_cat_tree);

-- ---------------------------------------------------------------------
-- 5. Desactivar las categorías antiguas que quedaron sin lugares
-- ---------------------------------------------------------------------

UPDATE public.categories_v2 c
SET is_active = false
WHERE c.slug NOT IN (SELECT slug FROM project_internal.migr_cat_tree)
  AND c.is_active
  AND NOT EXISTS (
      SELECT 1 FROM public.places_v2 p WHERE p.category_id = c.id
  );

-- Tablas auxiliares de la migración.
DROP TABLE project_internal.migr_cat_map;
DROP TABLE project_internal.migr_cat_tree;

COMMIT;

-- =====================================================================
-- Verificación (ejecutar después; solo lectura)
-- =====================================================================

-- a) Árbol activo con cantidad de lugares por subcategoría.
SELECT
    coalesce(parent.name_es, c.name_es)            AS principal,
    CASE WHEN parent.id IS NULL THEN '—' ELSE c.name_es END AS subcategoria,
    count(p.id) FILTER (WHERE p.is_active AND p.retired_at IS NULL) AS lugares
FROM public.categories_v2 c
LEFT JOIN public.categories_v2 parent ON parent.id = c.parent_id
LEFT JOIN public.places_v2 p ON p.category_id = c.id
WHERE c.is_active
GROUP BY parent.id, parent.name_es, parent.sort_order, c.id, c.name_es, c.sort_order
ORDER BY coalesce(parent.sort_order, c.sort_order), parent.id NULLS FIRST, c.sort_order;

-- b) Debe devolver 0 filas: categorías antiguas que siguen con lugares
--    (su nombre no coincidió con ninguna equivalencia; agregarla a project_internal.migr_cat_map).
SELECT c.id, c.name_es, count(p.id) AS lugares
FROM public.categories_v2 c
JOIN public.places_v2 p ON p.category_id = c.id
WHERE c.parent_id IS NULL
  AND c.slug NOT IN ('atractivo', 'actividad', 'gastronomia',
                     'alojamiento', 'transporte', 'servicio')
GROUP BY c.id, c.name_es;
