-- 2026-11-23 · Carga del control de verificación de lugares (Notion → places_v2)
-- Fuente: base de Notion «Control de Verificación Supabase Lugares» (exportación del 23-11-2026, 63 filas).
-- Solicitado por: Diego Del Río (jefe de proyecto). Ejecutado en producción el 23-11-2026 vía MCP de Supabase.
-- Alcance: filas con Activo = Yes y Estado de revisión = Verificado (54), menos Buses Don Carlos
--   (su nota dice «Se deja desactivado» y su contacto es un enlace de búsqueda): 53 filas.
-- Reglas: dirección, horario, contacto, sitio web y precio solo se reemplazan si el valor de Notion es válido
--   (no vacío, no «null», no un enlace en lugar de dirección); last_verified_date = «Última verificación»;
--   source_es = «Fuente de verificación» (o el enlace de Sernatur si no hay otra);
--   verification_level = 'fuente_publica' solo cuando hay fuente registrada; is_active = true.
-- Respaldo previo: project_internal.places_v2_respaldo_20261123 (copia completa de places_v2, 63 filas, con RLS).
-- Reversión: update public.places_v2 p set (address, schedule, contact_info, website_url, reference_price,
--   last_verified_date, source_es, verification_level, is_active, updated_at) =
--   (r.address, r.schedule, r.contact_info, r.website_url, r.reference_price, r.last_verified_date,
--    r.source_es, r.verification_level, r.is_active, r.updated_at)
--   from project_internal.places_v2_respaldo_20261123 r where r.id = p.id;

create table project_internal.places_v2_respaldo_20261123 as select * from public.places_v2;
alter table project_internal.places_v2_respaldo_20261123 enable row level security;

with n(id,address,schedule,contact_info,website_url,reference_price,last_verified_date,source_es,verification_level) as (values
('58aa08ee-264e-4dcc-a856-5de010b16440'::uuid,'Gral. Baquedano 9, Coyhaique, Aysén','domingo 1–9 p.m. lunes a sábado, 5 p.m.–1 a.m.','+56942760745','https://www.instagram.com/casaadobecoyhaique?igsh=YzE5OWx5YWtpbXJ3','$10,000-35,000','2026-11-05'::date,'https://www.tripadvisor.cl/Restaurant_Review-g317798-d7714364-Reviews-Adobe_Coyhaique-Coyhaique_Aisen_Region.html','fuente_publica'),
('a79791da-6227-4e32-958c-c2f4f5a9f3f0'::uuid,'Lord Cochrane 233, Coyhaique, Aysén','Lunes a viernes 9am - 6pm Sabado 10am - 2pm Domingos Cerrado',' +56672232433 (mesón) / +56672240713 (dirección) / E-mail: contacto.bra@bibliotecaspublicas.gob.cl / gloria.carrillo@serpat.gob.cl','https://www.bibliotecaregionalaysen.gob.cl/','Ver disponibilidad en la recinto.','2026-11-05'::date,'https://www.bibliotecaspublicas.gob.cl/biblioteca-regional-de-aysen','fuente_publica'),
('3f2ff697-3d8e-45fa-b25e-ff7d251e4ef7'::uuid,'Campo Alegre S/N, Coyhaique, Aysén','Lunes a Sábado 13:00 a 23:00 Hrs.
Domingos 13:00 a 22:00 Hrs.','+56957009324','https://borek19.com/','Ver menú en el local o en la pagina web','2026-11-05'::date,'https://www.instagram.com/borek_restaurante/?hl=en','fuente_publica'),
('72e16a7f-6231-4a37-8cc4-3e87779cf2c6'::uuid,'Av. Norte Sur/Las Violetas, Terminal de Coyhaique, Of. N°2','Lun-Vie 06:30–19:00 / Sábado 08:00–19:00 / Domingo 08:00–19:30','+56 67 221 2639 / suray.ltda@gmail.com','https://www.suray.cl','Ver disponibilidad en el sitio web.','2026-11-05'::date,'https://www.instagram.com/buses.suray.cargo/','fuente_publica'),
('e22e91d3-0d0a-4f64-b67c-0c21fcd4e6fb'::uuid,'Lautaro 109, Of. G, Coyhaique (Terminal de Buses de Coyhaique)','Frecuencias diarias según calendario de salidas a la zona sur','+56 67 2 232067','https://www.recorrido.cl/es/bus/buses-transaustral-pasajes','Ver disponibilidad en el sitio web.','2026-11-05'::date,'https://kupos.cl/es/pasajes/bus/transaustral','fuente_publica'),
('fc0353ae-1daf-4423-a687-44838a67ad65'::uuid,'Dussen 135, Coyhaique (a solo dos cuadras de la plaza principal)','Ver disponibilidad y horarios de recepción en el sitio web.','+56 9 9623 1554 / dussen.coyhaique@gmail.com','https://www.cabanasdussencoyhaique.cl','Ver disponibilidad en el sitio web.','2026-11-05'::date,'https://www.instagram.com/cabanasdussencoyhaique/','fuente_publica'),
('05d9049e-dbf4-4efb-9a23-e0c6b6d9ecac'::uuid,NULL,'Ver disponibilidad y horarios de recepción en el sitio web.','+56 9 3226 5815 / gonzalezgarcia.eirl@gmail.com','https://www.entresauces.com/','Ver disponibilidad en el sitio web.','2026-11-05'::date,'https://www.instagram.com/cabanas_entresauces/','fuente_publica'),
('f0a763b4-ca4f-492e-80d7-be550b454b2b'::uuid,'Veintiuno de Mayo 543, Coyhaique, Aysén','Ver disponibilidad en su perfil oficial.','+56 67 223 2000','https://www.instagram.com/cafede_mayo/','$5,000-15,000','2026-11-05'::date,'https://www.tripadvisor.cl/Restaurant_Review-g317798-d6022285-Reviews-Cafe_de_Mayo-Coyhaique_Aisen_Region.html','fuente_publica'),
('25bb1710-3003-4482-b4cc-4bbcc021980a'::uuid,'Magallanes 670, Coyhaique, Aysén','lunes a viernes 8 a.m.–4 p.m.','+56 9 4135 6409','https://www.facebook.com/cafeperegrinocoyhaique','$5,000-10,000.','2026-11-05'::date,'https://www.instagram.com/cafeperegrinocoyhaique/?hl=en','fuente_publica'),
('be50457f-8776-4581-a278-7f8291be20c6'::uuid,'Carlos Condell 297, Piso 1, Coyhaique, Aysén','Lunes a Sabado 09:00 AM - 22:00 PM','+56 9 3437 8494 / turismo@grupocalafate.com','https://lacompaniacafeteria.cl/es/','$5,000-10,000.','2026-11-05'::date,'https://www.instagram.com/lacompaniacafeteria/?hl=en','fuente_publica'),
('6104ead0-728d-4c4b-85c7-f27d7916773c'::uuid,'José de Moraleda 599, Coyhaique, Aysén','lunes a sábado, 9:30 a.m.–8 p.m.','N/A','https://www.minube.com/rincon/cafeteria-la-ovejita-a3675728','Ver menú en el local.','2026-11-05'::date,'https://datalux.cl/empresa/76330189-3-cafeteria-la-ovejita-ltda/','fuente_publica'),
('f44fa370-943a-433a-96bb-7a101c79c3ae'::uuid,'Cerro Divisadero / Cordón Divisadero, Coyhaique, Región de Aysén','Ver disponibilidad con el operador.','+56 9 7268 2282 / contacto@patagonaexcursiones.cl','https://patagonaexcursiones.cl/producto/full-4x4-y-trekking-cordon-divisadero-cerro-el-fraile/','$55.000','2026-11-06'::date,NULL,NULL),
('775442d9-4d26-4829-b269-3598c0456669'::uuid,'Gral. Baquedano 444, Coyhaique, Aysén','LUN-JUE 12:30 a 22:00 VIE- SAB de 12:30 a 22:30 DOM 12:30 a 19:00','+56 9 6775 6636 / info@casacipres.cl','https://www.instagram.com/casacipres.cl?igshid=ZjA0NjI3M2I%3D','$20,000-45,000.','2026-11-06'::date,'https://www.tripadvisor.cl/Restaurant_Review-g317798-d24986048-Reviews-Casa_Cipres_Restaurante-Coyhaique_Aisen_Region.html','fuente_publica'),
('fefcff77-b763-408e-bcd0-96c2bff7b154'::uuid,'Próxima apertura en: Almirante Barroso 553','lunes a domingo, 11:30 a.m.–9:30 p.m.','+56672231437','https://www.tripadvisor.cl/Restaurant_Review-g317798-d1017110-Reviews-Casino_Bomberos-Coyhaique_Aisen_Region.html','$10,000-15,000','2026-11-06'::date,'https://vientopatagon.com/noticia/actualidad/2026/11/03/el-casino-de-bomberos-renace-en-coyhaique-la-picada-que-el-fuego-no-pudo-apagar','fuente_publica'),
('37ff3739-6ad6-4b9b-81d5-66ed96156aac'::uuid,'Magallanes 131, Coyhaique.','Ver disponibilidad en el sitio web.','600 424 0000','https://coyhaique.dreams.cl','Ver disponibilidad en el sitio web','2026-11-06'::date,'https://www.instagram.com/dreamscoyhaiqueoficial/?hl=en','fuente_publica'),
('df1570b1-9437-491a-9bab-c946bd6f2556'::uuid,'Veintiuno de Mayo 655,Coyhaique, Aysén','Domingo Cerrado
Lunes, Martes, Miercoles, Jueves, Viernes y Sabado Del 12:30 al 14:30Del 19:30 al 22:00','+56956574181','https://www.tripadvisor.cl/Restaurant_Review-g317798-d15356624-Reviews-CB_Gastronomia_Patagonia-Coyhaique_Aisen_Region.html','$30,000-$50,000','2026-11-06'::date,'https://www.instagram.com/cb_gastronomiapatagonia/?hl=en','fuente_publica'),
('ed9bbd80-f2a2-43fa-b299-24997fa90b29'::uuid,'Eusebio Lillo #23, Coyhaique, Region de Aysen','Lun/Vie 8:30 - 17:30 | Sab 9:00 - 13:00 / 15:00 - 19:00','contacto@coyhaiquecultura.cl','https://www.coyhaiquecultura.cl','Ver disponibilidad en el sitio web.','2026-11-06'::date,'https://www.instagram.com/culturacoyhaique/','fuente_publica'),
('e2f9463b-ea7e-45a4-a5d2-feb88d1c2707'::uuid,'Av. Baquedano 1895, Coyhaique','Lun/Sáb 12:30 pm a 1 am
Domingos 12:30 pm a 7 pm','+56 9 7381 2369 / contacto@dolbek.cl','https://www.dolbek.cl/','$15,000-$20,000','2026-11-06'::date,'https://www.instagram.com/cerveza_dolbek/?hl=en','fuente_publica'),
('33c5a99b-2e8b-449b-856d-9a1bb53b9d1e'::uuid,'Camino a Coyhaique Alto - Km. 3, Coyhaique, Aysén','Martes a viernes: 10:00 a 19:00 horas
Sábados: 15:00 a 19:00 horas
Lunes, domingos y festivos: Cerrado','+56 67 257 6800 / +56 9 4526 7721','https://www.museoregionalaysen.gob.cl/','El Ingreso es Gratuito $0','2026-11-08'::date,'https://www.monumentos.gob.cl/monumentos/monumentos-historicos/las-construcciones-de-la-sociedad-industrial-de-aisen','fuente_publica'),
('57c84804-eb55-40b1-a0f4-eecc41a3726d'::uuid,'Ignacio Serrano N° 858, Coyhaique, Región de Aysén','Consultas: Lunes a Domingo de 09:00 a 21:00 horas
Si ya es huesped: 24 horas abierto','+56 9 9640 0688
Nro respaldo: +56 9 9933 7805
reservas@rutakaiken.cl','https://www.rutakaiken.cl/','$60.000-$100.000','2026-11-10'::date,'https://www.instagram.com/rutakaiken/','fuente_publica'),
('c401fa8b-bbae-4360-9989-d7a6ce6ddc09'::uuid,'Calle José Manuel Balmaceda N° 455, Coyhaique, Región de Aysén','Lunes a Domingo, 24 horas','+ 56 9 3460 4429','https://ww2.copec.cl/personas/estaciones-de-servicio','Consultar tarifas en el recinto.','2026-11-20'::date,'https://prontocopec.cl/tiendas/pronto-express-balmaceda-ii/','fuente_publica'),
('6a3ab0e9-5365-430b-aabd-dd1cd4c98aee'::uuid,'Gral. Baquedano N°1578, Coyhaique, Aysén','Lunes a Domingo, 24 horas','Teléfono Central Corporativo. +56 800 200 354
Teléfono Red de Estaciones. +56 600 200 0202','https://ww2.copec.cl/personas/estaciones-de-servicio','Consultar tarifas en el recinto.','2026-11-20'::date,'https://prontocopec.cl/tiendas/pronto-express-baquedano/','fuente_publica'),
('d6e589c0-82f5-4af1-b8c3-5c09df735f21'::uuid,'Ogana N° 1157, 5950000 Coyhaique, Aysén','Lunes a Domingo, 24 horas','+ 56 9 3460 4429','https://ww2.copec.cl/personas/estaciones-de-servicio','Consultar tarifas en el recinto.','2026-11-20'::date,'https://prontocopec.cl/tiendas/pronto-express-ogana/','fuente_publica'),
('799ebf78-cff9-4d16-afc4-a122c70e92c5'::uuid,'Calle José Miguel Carrera N° 330 (esquina Calle Arturo Prat), Coyhaique','Lunes a Domingo, 24 horas','600 350 2000','https://find.shell.com/cl/fuel/10127724-shell/es_CL','Consultar tarifas en el recinto.','2026-11-20'::date,NULL,NULL),
('15237fe9-8ab2-4130-bc7c-a30d889dd543'::uuid,'Sargento Aldea 1902, Puerto Aysén','Lunes a Domingo, 24 horas','600 350 2000','https://www.bencinaenlinea.cl/#/busqueda_estaciones','Consultar tarifas en el recinto.','2026-11-20'::date,NULL,NULL),
('a850ecc4-86cb-4aa3-8d49-988673170682'::uuid,'Ramón Freire 248, Coyhaique, Aysén','lunes a viernes de 9:00 a 19:00','+56 9 9640 7415',NULL,'Consultar tarifas en el recinto.','2026-11-20'::date,NULL,NULL),
('057c0825-0584-427a-9fcc-337b75ab7210'::uuid,'Diego Portales 74, Coyhaique, Aysén','lunes a viernes de 7:30 a 20:00','+56 9 7308 9345',NULL,'Consultar tarifas en el recinto.','2026-11-20'::date,NULL,NULL),
('56d13757-98b7-4c20-9b62-af6e555d838d'::uuid,'Ogana 1320, Coyhaique, Aysén','Horarios de ingreso y salida. Check-in a partir de las 15:00 horas y Check-out hasta las 12:00 horas.
Ingreso Huespedes 24/7','Teléfono Fijo Recepción Local. +56 67 221 5200 / +56 67 221 5201.
recepcion-gxq@dahoteles.com','https://www.dahoteles.com/es/da-coyhaique','Ver disponibilidad en el sitio web.','2026-11-20'::date,'https://www.tripadvisor.cl/Hotel_Review-g317798-d2445368-Reviews-Diego_de_Almagro_Coyhaique-Coyhaique_Aisen_Region.html','fuente_publica'),
('fdd42ef4-421a-430d-9a07-db0fe7b128f8'::uuid,'Gral. Baquedano 828, Coyhaique, Aysén','Horarios de ingreso y salida. Check-in a partir de las 14:00 horas y Check-out hasta las 11:00 horas
Ingreso Huespedes 24/7','Teléfono Fijo Recepción. +56 67 223 1108.
reservas@elrelojhotel.com','https://elrelojhotel.com/','Ver disponibilidad en el sitio web.','2026-11-20'::date,'https://www.tripadvisor.cl/Hotel_Review-g317798-d641559-Reviews-El_Reloj_Hotel-Coyhaique_Aisen_Region.html','fuente_publica'),
('ac7aee67-6b48-4d6d-9d6b-cce0d9341589'::uuid,'Gral. Baquedano 84, Coyhaique, Aysén','Ver disponibilidad y horarios de recepción en el sitio web.','+569 65060706/ reservas@hotelnomades.cl','https://www.hotelnomades.cl/','Ver disponibilidad en el sitio web.','2026-11-20'::date,'https://www.instagram.com/hotelnomadesboutique/?hl=en','fuente_publica'),
('3215fddf-5652-4645-92dd-e1983d1eeea0'::uuid,'Quinta 18 de Julio, Campo Alegre S/N, Coyhaique','Ver disponibilidad y horarios de recepción en el sitio web.','+56 67 221 1488 / ventas@salvajecorazon.com','https://www.patagonia-house.com/','Ver disponibilidad en el sitio web.','2026-11-20'::date,'https://www.instagram.com/hotelpatagoniahousecl/?hl=en','fuente_publica'),
('25524050-a1b3-4791-ae6f-4b2ed110ba7b'::uuid,'Calle Veintiuno de Mayo N° 427, Coyhaique','lunes a viernes, 8 a.m.–7 p.m. sábado, 10 a.m.–7 p.m.','+56956685207 / cafeteriainquieto@gmail.com','https://www.instagram.com/inquietocafeteria','$5,000-10,000','2026-11-20'::date,'https://www.thebestcoffeeshopschile.cl/the-best/inquieto-cafeteria-de-especialidad-2/','fuente_publica'),
('61ffc9e1-ec81-4a0c-9bff-19644cbcc0ca'::uuid,'Calle Arturo Prat N° 653, Coyhaique','Lunes. 12:30 a 22:00 horas.
Martes a Sábado. 12:30 a 22:40 horas.
Domingos. 13:00 a 17:00 horas','Teléfonos Fijos Locales. +56 67 252 5888, +56 67 221 4676 y +56 67 221 1191
contacto@kosushipatagonia.cl','https://kosushipatagonia.cl/','$10,000-35,000.','2026-11-20'::date,'https://www.instagram.com/kosushipatagonia.cl/','fuente_publica'),
('88fe5781-07b0-410f-8072-d7c52ee5b328'::uuid,'Calle Almirante Simpson N° 232, Coyhaique','Lunes a Sábado 10:00 - 22:00 horas Domingo 11:00 - 17:00 horas','+56 9 7341 7305','https://lapicacoyhaique.cl/','Ver menú en el local.','2026-11-20'::date,'https://www.instagram.com/lapica_restaurant/','fuente_publica'),
('b2c075a8-b20f-474f-ab84-2eb04e075eb9'::uuid,'Ruta X-686, Kilómetro 18 (Sector Lago Elizalde / Villa Frei), Comuna de Coyhaique','Abierto 24/7 (Acceso público).','Teléfono Central Municipalidad de Coyhaique. +56 67 267 5100.
Oficina de Información Turística SERNATUR Aysén. +56 67 224 0290 / Correo: informacionesaysen@sernatur.cl','https://vistalagoelizalde.cl/','Gratuito (el acceso a balnearios públicos no tiene costo; servicios turísticos en los alrededores varían).','2026-11-20'::date,'https://www.gochile.cl/es/lago-elizalde/','fuente_publica'),
('3071bd4c-f94f-43cc-ac4a-d3d75080800a'::uuid,'Paseo Horn N° 47-D, Coyhaique','lunes a miércoles 12:00 - 01:00 hrs. Jueves a sábado 12:00 - 02:00 hrs.
Nota: El servicio de delivery funciona de lunes a sábado entre las 12:00 y las 22:00 horas','Teléfono Fijo Local. +56 67 221 0721.
Teléfono Móvil / Delivery y Retiro. +56 9 6409 7808','https://mammagaucha.cl/','Ver menú en el local.','2026-11-20'::date,'https://www.instagram.com/mammagaucha/?hl=en','fuente_publica'),
('7a8fa308-d93b-46d8-9a31-56dc2aef0066'::uuid,'Carr. Austral 5640, Coyhaique, Aysén','Abierto 24/7','Dirección de Arquitectura MOP Aysén. +56 67 257 2000
Ilustre Municipalidad de Coyhaique (Oficina de Turismo). +56 67 267 5100','https://www.rutakaiken.cl/blog/mirador-marchant/','Gratuito','2026-11-20'::date,'https://www.tripadvisor.cl/Attraction_Review-g317798-d12686657-Reviews-Mirador_Marchant-Coyhaique_Aisen_Region.html','fuente_publica'),
('7906b40a-6d17-446f-aca6-2cf4e3a1e315'::uuid,'Avenida General Baquedano N° 500, Coyhaique','Abierto 24/7','Cualquier duda/consulta con Municipalidad +56 67 267 5100','https://www.tripadvisor.cl/Attraction_Review-g317798-d23972372-Reviews-Mirador_Urbano_Rio_Simpson-Coyhaique_Aisen_Region.html','Gratuito','2026-11-20'::date,'https://wanderlog.com/es/place/details/10537815/mirador-río-coyhaique','fuente_publica'),
('49173567-a76c-4d09-968c-a0ab1405a3c4'::uuid,'Veintiuno de Mayo 233, 5950000 Coyhaique, Aysén','Lunes a Jueves de 08:30 a 19:00. Viernes de 08:30 a 18:00. Sábados de 09:00 a 14:00.','Reservas: 56672245780
Oficina:56672245777
Emergencia:56977493315 servicioalcliente@mitta.cl','https://mitta.cl/rent-a-car-personas/','Ver disponibilidad en el sitio web.','2026-11-20'::date,'https://mitta.cl/rent-a-car-personas/','fuente_publica'),
('98e3a943-a8b3-4c04-b06f-0a1f1a0dd20e'::uuid,'Avenida General Baquedano con Calle E. Lillo.','Abierto 24/7','N/A','https://www.monumentos.gob.cl/monumentos/monumentos-publicos/el-ovejero','Gratuito','2026-11-20'::date,'https://www.monumentos.gob.cl/monumentos/monumentos-publicos/el-ovejero','fuente_publica'),
('f5107d6e-ef17-433e-8248-1462c529fb31'::uuid,'A 21 km de Coyhaique, camino a Coyhaique Alto.','Ver disponibilidad en el sitio web.','+56672212139
aysen.oirs@conaf.cl','https://www.conaf.cl/parque_nacionales/monumento-natural-dos-lagunas/','Ver disponibilidad en el sitio web.','2026-11-20'::date,'https://www.conaf.cl/parque_nacionales/monumento-natural-dos-lagunas/','fuente_publica'),
('869db238-e0fc-438f-adb8-96e47a7fbff1'::uuid,'Camino a Coyhaique Alto - Km. 3, Coyhaique, Aysén','Lunes a Viernes de 10:00 a 19:00, sábados de 15:00 a 19:00','+56672576800 / contactoaysen@museoschile.gob.cl','https://www.museoregionalaysen.gob.cl','Gratuito','2026-11-20'::date,'https://www.museoregionalaysen.gob.cl','fuente_publica'),
('53d9cf05-814b-4f9d-8834-6eebdeb5e806'::uuid,'Ruta 7 (Carretera Austral), a 64 km al sur de Coyhaique.','Ver disponibilidad en el sitio web.','(+56) 672212225
aysen.oirs@conaf.cl','https://www.conaf.cl/parques-nacionales/parque-nacional-cerro-castillo/','Ver disponibilidad en el sitio web.','2026-11-20'::date,'https://www.conaf.cl/parque_nacionales/parque-nacional-cerro-castillo/','fuente_publica'),
('8dcdaa98-53a9-468f-ad9a-832e39bfaadf'::uuid,'Avenida Piedra del Indio s/n, sector Costanera Río Simpson, Coyhaique.','Ver disponibilidad en el sitio web.','N/A','https://repositorio.minvu.gob.cl/entities/publication/9e34ae6d-de38-4cf4-9a72-fab2626f2cf2','Ver disponibilidad en el sitio web.','2026-11-20'::date,'https://repositorio.minvu.gob.cl/entities/publication/9e34ae6d-de38-4cf4-9a72-fab2626f2cf2','fuente_publica'),
('4c17231a-57e4-4f7e-b6a8-9bcacb95c96b'::uuid,'Dussen #317, Coyhaique','Mar a Vie · 9:30–21:00 Sáb y Dom · 10:00–21:00 Lunes cerrado.','+56 67 221 0700 / patagonia@holzer.cl','https://www.holzer.cl/','$5,000-10,000','2026-11-20'::date,'https://www.holzer.cl/#sucursales','fuente_publica'),
('8021f0ae-b961-4753-9894-31d8e32821db'::uuid,'Sector Costanera Río Simpson, Avenida Piedra del Indio, Coyhaique.','Abierto 24/7','N/A','https://turismocoyhaique.cl/lugares-de-interes/piedra-del-indio/','Gratuito','2026-11-20'::date,'https://turismocoyhaique.cl/lugares-de-interes/piedra-del-indio/','fuente_publica'),
('77398f3a-7eb0-4fc1-9b96-dc24ac20a66d'::uuid,'Carlos Condell 289, Coyhaique, Aysén','Abierto 24/7','N/A','https://turismocoyhaique.cl/lugares-de-interes/plaza-coyhaique/','Gratuito','2026-11-20'::date,'https://turismocoyhaique.cl/lugares-de-interes/plaza-coyhaique/','fuente_publica'),
('cfed7c02-0c95-4ed0-9e97-8c7b9b5f3366'::uuid,'A 3 km del límite urbano de Coyhaique, camino a Coyhaique Alto','Martes a domingo de 09:00 a 16:30','+56 9 7726 3600
800 200 354','https://www.pasesparques.cl/es/coyhaique-289/reserva-nacional-coyhaique-3430','$4.500','2026-11-20'::date,'https://www.pasesparques.cl/es/coyhaique-289/reserva-nacional-coyhaique-3430','fuente_publica'),
('66690d59-6031-4957-a695-94c58dc0abdd'::uuid,'Ruta CH-240, a 37 km de Coyhaique en dirección a Puerto Aysén.','Ver disponibilidad en el sitio web.','+56672332743
aysen.oirs@conaf.cl','https://www.conaf.cl/parques-nacionales/reserva-nacional-rio-simpson/','Ver disponibilidad en el sitio web.','2026-11-19'::date,'https://www.conaf.cl/parque_nacionales/reserva-nacional-rio-simpson/','fuente_publica'),
('82baec4f-6ca6-4672-9873-07b5ad985ae0'::uuid,'A 30 kilómetros de Coyhaique por Ruta 7 (camino Austral) a Villa Ortega y desde ahí, seguir bifurcación por ruta X-445 hacia Ñirehuao, a 15 kilómetros.','Ver disponibilidad en el sitio web.','+56672212139
aysen.oirs@conaf.cl','https://www.conaf.cl/parque_nacionales/reserva-nacional-trapananda/','Ver disponibilidad en el sitio web.','2026-11-19'::date,'https://www.conaf.cl/parque_nacionales/reserva-nacional-trapananda/','fuente_publica'),
('a49fa8f6-778b-4ed1-868d-4df34e3b6231'::uuid,'Cam. del Bosque 1170, 5950000 Coyhaique, Aysén','Ver disponibilidad y horarios de recepción en el sitio web.','+56 9 8293 8049 +56 9 8293 8034/ administracion@thepatagonianlodge.cl','https://www.thepatagonianlodge.cl/','Ver disponibilidad en el sitio web.','2026-11-19'::date,'https://www.thepatagonianlodge.cl/contacto.html','fuente_publica'),
('9a1621a8-cf3e-4966-aa88-3c5b7f0b48ab'::uuid,'Gral. Baquedano 457, 5951363 Coyhaique, Aysén','Ver disponibilidad y horarios en el sitio web.','+569 9640 6412 / contacto@traeger.cl','https://traeger.cl','Ver disponibilidad en el sitio web.','2026-11-19'::date,'https://traeger.cl','fuente_publica'),
('c4f04ba0-be59-41ae-887f-5e563cfd0d1c'::uuid,'Ogana 1049, 5951830 Coyhaique, Aysén','lunes a sabado, 10 a.m.–3 a.m.
domingo, 12 p.m.-3 a.m.','+56982079573
+569 7785 2212','https://www.facebook.com/Vivesaborcoyhaique','$15,000-20,000','2026-11-19'::date,'https://www.facebook.com/Vivesaborcoyhaique','fuente_publica'))
update public.places_v2 p set
 address=coalesce(n.address,p.address),
 schedule=coalesce(n.schedule,p.schedule),
 contact_info=coalesce(btrim(n.contact_info),p.contact_info),
 website_url=case when n.website_url is not null then n.website_url when p.website_url in ('null','https://null','') then null else p.website_url end,
 reference_price=coalesce(n.reference_price,p.reference_price),
 last_verified_date=n.last_verified_date,
 source_es=coalesce(n.source_es,p.source_es),
 verification_level=coalesce(n.verification_level,p.verification_level),
 is_active=true,
 updated_at=now()
from n where p.id=n.id
returning p.name_es, p.is_active, p.verification_level, p.last_verified_date;