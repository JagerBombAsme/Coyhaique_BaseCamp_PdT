-- =====================================================================
-- 2026-10-30 · HU-18 · Transfer desde el aeropuerto de Balmaceda
-- Aplicada en Supabase (proyecto BDD-CBC) como migración
-- «transport_services_v2_transfer_aeropuerto».
--
-- Ficha de solo lectura para la app. No guarda datos de pasajeros:
-- el QR se arma en el teléfono y abre WhatsApp con el viaje escrito.
-- Las tablas legacy transport_services, transport_routes y
-- pre_reservations no se tocan aquí (su retiro es la tarea #50).
-- =====================================================================

create table public.transport_services_v2 (
    id uuid primary key default gen_random_uuid(),
    service_type text not null default 'airport_transfer'
        check (service_type in ('airport_transfer')),
    name text not null check (length(btrim(name)) between 2 and 120),
    description_es text,
    description_en text,
    origin_es text not null default 'Aeropuerto de Balmaceda',
    origin_en text not null default 'Balmaceda Airport',
    stand_location_es text,
    stand_location_en text,
    whatsapp_number text
        check (whatsapp_number is null or whatsapp_number ~ '^[0-9]{8,15}$'),
    reference_fare_clp integer check (reference_fare_clp is null or reference_fare_clp > 0),
    fare_notes_es text,
    fare_notes_en text,
    capacity smallint check (capacity is null or capacity between 1 and 20),
    accepts_cash boolean not null default false,
    accepts_card boolean not null default false,
    schedule_es text,
    schedule_en text,
    image_url text,
    verification_level text not null default 'pendiente'
        check (verification_level in ('establecimiento', 'fuente_publica', 'pendiente')),
    qr_enabled boolean not null default false,
    last_verified_date date,
    sort_order integer not null default 0,
    is_active boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    retired_at timestamptz,
    constraint transport_services_v2_qr_needs_whatsapp
        check (not qr_enabled or whatsapp_number is not null),
    constraint transport_services_v2_payment_declared
        check (accepts_cash or accepts_card)
);

comment on table public.transport_services_v2 is
    'HU-18: fichas de transfer (aeropuerto de Balmaceda). Información referencial; sin reservas, pagos ni datos de pasajeros.';
comment on column public.transport_services_v2.whatsapp_number is
    'Número de la empresa, solo dígitos con código de país (ej. 569XXXXXXXX). Destino del enlace wa.me del QR.';
comment on column public.transport_services_v2.qr_enabled is
    'La empresa aceptó recibir viajes por QR. Requiere whatsapp_number.';

create index transport_services_v2_active_idx
    on public.transport_services_v2 (service_type, sort_order)
    where is_active and retired_at is null;

create trigger transport_services_v2_set_updated_at
    before update on public.transport_services_v2
    for each row execute function project_internal.set_updated_at();

create trigger audit_transport_services_v2
    after insert or update on public.transport_services_v2
    for each row execute function project_internal.audit_content_change();

alter table public.transport_services_v2 enable row level security;

create policy public_read_active_transport
    on public.transport_services_v2 for select to anon, authenticated
    using (is_active = true and retired_at is null);

create policy admin_read_all_transport
    on public.transport_services_v2 for select to authenticated
    using ((select project_internal.is_admin()));

create policy admin_insert_transport
    on public.transport_services_v2 for insert to authenticated
    with check ((select project_internal.is_admin()));

create policy admin_update_transport
    on public.transport_services_v2 for update to authenticated
    using ((select project_internal.is_admin()))
    with check ((select project_internal.is_admin()));

revoke all on public.transport_services_v2 from anon, authenticated;
grant select on public.transport_services_v2 to anon;
grant select, insert, update on public.transport_services_v2 to authenticated;

-- Ficha de ejemplo para pruebas. Reemplazar con los datos autorizados por
-- la empresa (o desactivarla con is_active = false antes de publicar).
insert into public.transport_services_v2 (
    name, description_es, description_en, stand_location_es, stand_location_en,
    whatsapp_number, reference_fare_clp, fare_notes_es, fare_notes_en, capacity,
    accepts_cash, accepts_card, schedule_es, schedule_en,
    verification_level, qr_enabled, last_verified_date, sort_order, is_active
) values (
    '[PENDIENTE DE VALIDACIÓN] Transfer de ejemplo',
    'Ficha de prueba. Se reemplaza con los datos autorizados por la empresa.',
    'Test listing. To be replaced with data authorized by the company.',
    'Puesto [N.º], hall de llegada', 'Stand [No.], arrivals hall',
    '56900000000', null,
    'Tarifa por confirmar con la empresa.', 'Fare to be confirmed with the company.',
    8, true, true,
    'Vuelos de llegada [POR CONFIRMAR]', 'Arriving flights [TO BE CONFIRMED]',
    'pendiente', true, null, 0, true
);

-- Cuando la empresa autorice, por ejemplo:
-- update public.transport_services_v2
--    set name = '<NOMBRE>', whatsapp_number = '569XXXXXXXX',
--        reference_fare_clp = <MONTO>, capacity = <N>,
--        verification_level = 'establecimiento', last_verified_date = current_date
--  where name like '[PENDIENTE DE VALIDACIÓN]%';
