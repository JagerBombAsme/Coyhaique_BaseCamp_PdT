-- HU-18: empresas de transporte verificadas y habilitadas (2026-11-22).
--
-- Agrega a transport_services_v2 el registro de que el equipo verificó que la
-- empresa está habilitada para transporte de pasajeros, los sentidos que
-- atiende (hacia / desde el aeropuerto) y sus enlaces de contacto.
-- La app solo muestra las filas con is_authorized_verified = true.
--
-- No borra ni modifica filas: las columnas nuevas parten en false / null, así
-- que la ficha de ejemplo existente deja de mostrarse en la app.
-- Requiere aprobación del equipo antes de ejecutarse en producción.

alter table public.transport_services_v2
  add column if not exists is_authorized_verified boolean not null default false,
  add column if not exists authorization_verified_date date,
  add column if not exists authorization_source text,
  add column if not exists serves_to_airport boolean not null default true,
  add column if not exists serves_from_airport boolean not null default true,
  add column if not exists phone text,
  add column if not exists website_url text;

alter table public.transport_services_v2
  add constraint transport_services_v2_phone_check
    check (phone is null or phone ~ '^[0-9]{8,15}$'),
  add constraint transport_services_v2_website_url_check
    check (website_url is null or (website_url ~ '^https://[^[:space:]]+$' and length(website_url) <= 300)),
  add constraint transport_services_v2_authorization_source_check
    check (authorization_source is null or (length(btrim(authorization_source)) between 3 and 300)),
  add constraint transport_services_v2_direction_check
    check (serves_to_airport or serves_from_airport),
  -- Una empresa solo puede quedar verificada con fecha, fuente, un medio de
  -- contacto y un nivel de verificación distinto de 'pendiente'.
  add constraint transport_services_v2_verified_requires_evidence_check
    check (
      not is_authorized_verified
      or (
        authorization_verified_date is not null
        and authorization_source is not null
        and verification_level <> 'pendiente'
        and (whatsapp_number is not null or phone is not null or website_url is not null)
      )
    );

comment on column public.transport_services_v2.is_authorized_verified is
  'El equipo verificó que la empresa está habilitada para transporte de pasajeros. Solo estas filas se muestran en la app. Exige fecha, fuente y un contacto.';
comment on column public.transport_services_v2.authorization_verified_date is
  'Fecha en que se verificó la habilitación de la empresa.';
comment on column public.transport_services_v2.authorization_source is
  'Documento o registro consultado para verificar la habilitación (texto breve, sin datos personales).';
comment on column public.transport_services_v2.serves_to_airport is
  'La empresa atiende viajes hacia el aeropuerto de Balmaceda.';
comment on column public.transport_services_v2.serves_from_airport is
  'La empresa atiende viajes desde el aeropuerto de Balmaceda.';
comment on column public.transport_services_v2.phone is
  'Teléfono de la empresa: solo dígitos con código de país (ej. 569XXXXXXXX). Enlace tel: de la app.';
comment on column public.transport_services_v2.website_url is
  'Sitio web de la empresa (https). Enlace de contacto de la app.';
