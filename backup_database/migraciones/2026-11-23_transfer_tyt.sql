-- 2026-11-23 · Carga de Transfer T&T en transport_services_v2 (a pedido de Diego Del Río).
-- Validación hecha el 23-11-2026 con fuentes públicas:
--   · Sitio oficial https://transfertyt.com/ : traslado Coyhaique ↔ aeropuerto de Balmaceda en ambos sentidos,
--     +56 9 9312 3939, reservas@transfertyt.com, «Transfer TyT es parte de TRANSPORTES SERRAER LTDA.».
--   · Guías del aeropuerto (aeropuertosdelmundo.net, act. 28-03-2025; airportsdata.net) la listan como empresa de transfer de BBA.
-- No verificado: inscripción en el Registro Nacional de Transporte (MTT), tarifa vigente y medios de pago.
-- Decisión del equipo: visible con verification_level = 'fuente_publica'; la falta de confirmación MTT queda en authorization_source y se declara en el informe.
insert into public.transport_services_v2
(service_type,name,description_es,description_en,origin_es,origin_en,phone,website_url,whatsapp_number,
 reference_fare_clp,fare_notes_es,fare_notes_en,accepts_cash,accepts_card,schedule_es,schedule_en,
 verification_level,qr_enabled,last_verified_date,sort_order,is_active,
 is_authorized_verified,authorization_verified_date,authorization_source,serves_to_airport,serves_from_airport)
values
('airport_transfer','Transfer T&T',
 'Traslado entre Coyhaique y el aeropuerto de Balmaceda, en ambos sentidos. Empresa de Transportes Serraer Ltda. Reserva por teléfono o correo (reservas@transfertyt.com).',
 'Transfer between Coyhaique and Balmaceda Airport, both ways. Operated by Transportes Serraer Ltda. Book by phone or email (reservas@transfertyt.com).',
 'Aeropuerto de Balmaceda','Balmaceda Airport','56993123939','https://transfertyt.com/',null,
 null,'Tarifa y medios de pago por confirmar con la empresa.','Fare and payment methods to be confirmed with the company.',true,false,
 'Según horarios de vuelos; reservar con anticipación.','According to flight schedules; book in advance.',
 'fuente_publica',false,'2026-11-23',1,true,
 true,'2026-11-23','Sitio oficial transfertyt.com (Transportes Serraer Ltda.) y guías del aeropuerto de Balmaceda. Inscripción en el Registro Nacional de Transporte (MTT) pendiente de confirmar.',true,true);

-- El registro de ejemplo (WhatsApp real, sin verificar; hallazgo T-01) se desactiva.
update public.transport_services_v2 set is_active=false, updated_at=now() where id='25e6f9c6-1063-4a96-8e83-6d88528faa17';
