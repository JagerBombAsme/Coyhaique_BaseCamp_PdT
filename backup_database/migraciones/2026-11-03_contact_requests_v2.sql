-- Aplicado en Supabase el 03-11-2026 (migración create_contact_requests_v2).
-- Solicitudes del formulario de la landing page (HU-24, RNF-10, SLA-09, SLA-10 y SLA-11).
-- Sin nombre ni teléfono (minimización). La clave pública solo puede insertar.

create table public.contact_requests_v2 (
    id uuid primary key default gen_random_uuid(),
    request_type text not null
        check (request_type in (
            'incorporacion_prestador',
            'correccion',
            'retiro_ficha',
            'reporte_error',
            'eliminacion_cuenta',
            'otro'
        )),
    email text not null
        check (
            length(email) between 6 and 254
            and email ~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'
        ),
    message text not null
        check (length(btrim(message)) between 1 and 1000),
    place_id uuid references public.places_v2 (id) on delete set null,
    consent boolean not null check (consent = true),
    status text not null default 'nuevo'
        check (status in ('nuevo', 'en_revision', 'cerrado')),
    created_at timestamptz not null default now(),
    closed_at timestamptz,
    constraint contact_requests_v2_closed_consistent
        check ((status = 'cerrado') = (closed_at is not null)),
    constraint contact_requests_v2_closed_after_created
        check (closed_at is null or closed_at >= created_at)
);

comment on table public.contact_requests_v2 is
    'Solicitudes de la landing page. Inserción pública; lectura y gestión solo para administradores. Retención: 90 días desde el cierre.';
comment on column public.contact_requests_v2.email is
    'Correo para responder la solicitud. Dato personal: no se copia a la auditoría.';

create index contact_requests_v2_status_created_idx
    on public.contact_requests_v2 (status, created_at);
create index contact_requests_v2_place_id_idx
    on public.contact_requests_v2 (place_id);
create index contact_requests_v2_closed_at_idx
    on public.contact_requests_v2 (closed_at)
    where closed_at is not null;

alter table public.contact_requests_v2 enable row level security;

-- Supabase otorga permisos amplios por defecto: se reemplazan por los mínimos.
revoke all on table public.contact_requests_v2 from anon, authenticated;
grant insert (request_type, email, message, place_id, consent)
    on table public.contact_requests_v2 to anon, authenticated;
grant select, delete on table public.contact_requests_v2 to authenticated;
grant update (status, closed_at) on table public.contact_requests_v2 to authenticated;

create policy public_insert_contact_requests
    on public.contact_requests_v2
    for insert
    to anon, authenticated
    with check (consent = true and status = 'nuevo' and closed_at is null);

create policy admin_read_contact_requests
    on public.contact_requests_v2
    for select
    to authenticated
    using ((select project_internal.is_admin()));

create policy admin_update_contact_requests
    on public.contact_requests_v2
    for update
    to authenticated
    using ((select project_internal.is_admin()))
    with check ((select project_internal.is_admin()));

create policy admin_delete_contact_requests
    on public.contact_requests_v2
    for delete
    to authenticated
    using ((select project_internal.is_admin()));

-- Retención: elimina las solicitudes cerradas hace más de 90 días.
create function project_internal.purge_closed_contact_requests()
returns integer
language plpgsql
security definer
set search_path to ''
as $$
declare
    v_deleted integer;
begin
    delete from public.contact_requests_v2
    where closed_at is not null
      and closed_at < now() - interval '90 days';
    get diagnostics v_deleted = row_count;
    return v_deleted;
end;
$$;

revoke all on function project_internal.purge_closed_contact_requests() from public, anon, authenticated;
