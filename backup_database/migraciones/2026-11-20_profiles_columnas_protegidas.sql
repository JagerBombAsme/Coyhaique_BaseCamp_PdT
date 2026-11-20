-- H-03 · El usuario no puede escribir role ni is_verified en su perfil.
-- Proyecto: BDD-CBC. Aplicar solo después de desplegar la app que usa
-- ProfileDto.toWriteJson() (rama fix/perfil-columnas-y-creacion).
--
-- En PostgreSQL un permiso de columna no se aplica mientras exista el
-- permiso sobre toda la tabla: se quita el de tabla y se dan permisos solo
-- a las columnas que la app escribe. La política RLS (id = auth.uid())
-- sigue impidiendo escribir filas de otros usuarios.

revoke insert, update on public.profiles from authenticated;

grant insert (id, full_name, username, biography, avatar_url,
              language, country, city)
  on public.profiles to authenticated;

grant update (id, full_name, username, biography, avatar_url,
              language, country, city, updated_at)
  on public.profiles to authenticated;

-- Verificación: debe devolver 0 filas.
-- select column_name, privilege_type
-- from information_schema.column_privileges
-- where table_schema = 'public' and table_name = 'profiles'
--   and grantee = 'authenticated'
--   and column_name in ('role', 'is_verified');
