-- =====================================================================
-- 2026-10-31 · Cambios de estructura previos a los diagramas
-- Notion #60 (Supabase: aplicar cambios de estructura) y #50 (retiro de
-- pre_reservations). Aplicada en Supabase (proyecto BDD-CBC) como
-- migración «estructura_previa_diagramas».
--
-- 1. Respaldo en el esquema backup_20261031 de las tablas legacy que se
--    retiran (ninguna se usa en el código de la app al 31-10-2026).
-- 2. Retiro de pre_reservations, test_connection, places y categories.
--    Se conservan transport_services, transport_routes y destinations
--    (legacy, fuera de la app; se retiran en una tarea posterior).
-- 3. places_v2: nivel de verificación (HU-02, HU-12) y duración estimada
--    de la visita (HU-07, planificador).
-- 4. profiles: cada usuario ve y edita solo su perfil (RNF-09). Antes
--    cualquiera, incluso sin sesión, podía leer todos los perfiles.
-- 5. destinations: solo lectura (se quitan permisos de escritura).
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Respaldo
-- ---------------------------------------------------------------------
create schema if not exists backup_20261031;
revoke all on schema backup_20261031 from public, anon, authenticated;

create table backup_20261031.pre_reservations as table public.pre_reservations;
create table backup_20261031.test_connection as table public.test_connection;
create table backup_20261031.places as table public.places;
create table backup_20261031.categories as table public.categories;

alter table backup_20261031.pre_reservations enable row level security;
alter table backup_20261031.test_connection enable row level security;
alter table backup_20261031.places enable row level security;
alter table backup_20261031.categories enable row level security;

revoke all on all tables in schema backup_20261031 from public, anon, authenticated;

comment on schema backup_20261031 is
    'Respaldo de tablas legacy retiradas el 31-10-2026 (Notion #60 y #50). Sin acceso desde la app.';

-- ---------------------------------------------------------------------
-- 2. Retiro de tablas legacy
-- ---------------------------------------------------------------------
drop table public.pre_reservations;
drop table public.test_connection;
drop table public.places;
drop table public.categories;

-- ---------------------------------------------------------------------
-- 3. places_v2: verificación y duración estimada
-- ---------------------------------------------------------------------
alter table public.places_v2
    add column verification_level text
        check (verification_level is null
               or verification_level in ('establecimiento', 'fuente_publica')),
    add column estimated_visit_minutes smallint
        check (estimated_visit_minutes is null
               or estimated_visit_minutes between 5 and 720);

comment on column public.places_v2.verification_level is
    'establecimiento = verificado con el prestador (autorización archivada fuera de la app); fuente_publica = datos de fuente pública verificable; null = sin verificar. Fecha en last_verified_date.';
comment on column public.places_v2.estimated_visit_minutes is
    'Duración estimada de la visita para el planificador (HU-07). null = valor por defecto de la app (60 min lugar, 120 min actividad).';

-- ---------------------------------------------------------------------
-- 4. profiles: solo el propio perfil
-- ---------------------------------------------------------------------
drop policy if exists "Public can read profiles" on public.profiles;

create policy own_profile_select
    on public.profiles for select to authenticated
    using (id = (select auth.uid()));

create policy own_profile_insert
    on public.profiles for insert to authenticated
    with check (id = (select auth.uid()));

create policy own_profile_update
    on public.profiles for update to authenticated
    using (id = (select auth.uid()))
    with check (id = (select auth.uid()));

revoke all on public.profiles from anon;
revoke delete, truncate, references, trigger on public.profiles from authenticated;

-- ---------------------------------------------------------------------
-- 5. destinations: solo lectura
-- ---------------------------------------------------------------------
revoke insert, update, delete, truncate, references, trigger
    on public.destinations from anon, authenticated;
