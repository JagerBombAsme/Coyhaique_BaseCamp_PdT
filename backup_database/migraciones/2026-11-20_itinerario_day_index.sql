-- Itinerarios por días (rediseño de la sección Itinerario).
--
-- Agrega el día (1, 2, 3…) a cada lugar de un itinerario guardado. Es un
-- cambio aditivo: las filas existentes quedan en el día 1 y la versión
-- anterior de la app sigue funcionando (no envía la columna y usa el valor
-- por defecto).
--
-- ORDEN DE DESPLIEGUE: ejecutar ANTES de instalar la build que lee day_index.
-- Requiere aprobación del equipo. No se ejecutó en producción.
--
-- `position` sigue siendo único por itinerario (itinerary_items_v2_unique_position):
-- la app lo numera de forma correlativa recorriendo los días en orden.

begin;

alter table public.itinerary_items_v2
  add column if not exists day_index integer not null default 1;

alter table public.itinerary_items_v2
  drop constraint if exists itinerary_items_v2_day_index_check;

alter table public.itinerary_items_v2
  add constraint itinerary_items_v2_day_index_check
  check (day_index between 1 and 14);

comment on column public.itinerary_items_v2.day_index is
  'Día del itinerario (1 a 14). Sin fecha de calendario: la app muestra «Día N».';

commit;

-- Reversión (solo si hiciera falta):
--   alter table public.itinerary_items_v2 drop constraint itinerary_items_v2_day_index_check;
--   alter table public.itinerary_items_v2 drop column day_index;
