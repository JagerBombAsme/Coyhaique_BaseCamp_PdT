# Coyhaique BaseCamp — USER_FLOWS

## 1. Regla principal

Las pantallas y funcionalidades se implementan en orden de dependencia.

No se construye una pantalla posterior si requiere una pantalla, dato o servicio anterior todavía inexistente.

## 2. Flujo de inicio

```text
Splash
  ↓
Selección de idioma
  ↓
Acceso
  ├── Continuar como invitado
  ├── Iniciar sesión
  └── Crear cuenta
  ↓
Selección / detección de ubicación inicial
  ↓
Home
```

La secuencia exacta debe contrastarse con el flujo final de Figma antes de programar.

## 3. Exploración turística

```text
Home
  ↓
Listado de atractivos (HU-01)
  ↓
Detalle de atractivo (HU-02)
```

Filtros:

```text
Listado (HU-01)
  ↓
Categorías / filtros (HU-03)
  ↓
Listado filtrado
```

HU-02 no comienza antes de que HU-01 sea funcional.

HU-03 se integra sobre un listado ya existente.

## 4. Orientación territorial

```text
Home / Detalle
  ↓
Permiso de ubicación (HU-05)
  ├── Concedido → obtener ubicación
  └── Rechazado → ubicación manual
  ↓
Mapa y puntos cercanos (HU-06)
  ↓
Distancia (HU-07)
  ↓
Ruta (HU-08)
```

Orden obligatorio:

```text
Geolocalización
  ↓
Mapa
  ↓
Cercanos
  ↓
Distancia
  ↓
Ruta
```

## 5. Itinerario

```text
Atractivos disponibles
  ↓
Propuesta básica de itinerario (HU-04)
  ↓
Itinerario generado
  ↓
Editar itinerario (HU-13)
```

No implementar optimización avanzada, IA o recomendación predictiva.

## 6. Cuenta

```text
Acceso
  ├── Invitado
  ├── Login
  └── Registro
```

Registro:

```text
Crear cuenta (HU-21)
  ↓
Validación
  ↓
Sesión
```

Login:

```text
Iniciar sesión (HU-22)
  ↓
Sesión autenticada
  ↓
Persistencia autorizada (HU-29)
```

Recuperación:

```text
Olvidé contraseña
  ↓
Correo
  ↓
Código / enlace según solución implementada
  ↓
Nueva contraseña
```

La recuperación debe ajustarse al mecanismo real elegido en Supabase Auth.

## 7. Perfil

Disponible solo cuando exista sesión autenticada.

Funciones derivadas del alcance:
- información mínima de perfil;
- idioma;
- sesión;
- eliminación de cuenta cuando corresponda.

No agregar funciones sociales.

## 8. Offline

```text
Contenido online ya disponible
  ↓
Seleccionar descarga
  ↓
Descargando
  ↓
Disponible offline
  ↓
Consulta sin conexión
```

HU-15 se implementa después del núcleo turístico estable.

## 9. Administración web

```text
/admin
  ↓
Autenticación
  ↓
Autorización administrativa
  ↓
Listado de contenidos
  ├── Crear (HU-17)
  ├── Editar (HU-18)
  ├── Activar/desactivar (HU-19)
  └── Retirar (HU-20)
```

## 10. Landing

```text
Landing
  ├── Proyecto
  ├── Características
  ├── Coyhaique
  ├── Descargar
  ├── Privacidad
  ├── Términos
  └── Eliminar cuenta
```

## 11. Orden global

```text
Base técnica
  ↓
HU-01
  ↓
HU-02
  ↓
HU-03
  ↓
HU-05
  ↓
HU-06
  ↓
HU-07
  ↓
HU-08
  ↓
HU-04
  ↓
HU-13
  ↓
HU-17
  ↓
HU-18
  ↓
HU-19
  ↓
HU-20
  ↓
HU-21
  ↓
HU-22
  ↓
HU-29
  ↓
HU-15
  ↓
HU-30
  ↓
Integración
  ↓
Pruebas
  ↓
Despliegue
```

## 12. Pendiente

Antes de convertir este archivo en versión final:
- contrastar nombres de pantallas con Figma;
- numerar pantallas definitivas;
- asociar cada pantalla con su HU;
- documentar rutas del router Flutter;
- registrar estados alternativos de error y vacío.
