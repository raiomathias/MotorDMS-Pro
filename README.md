# MotorDMS Pro

**Versión actual de la interfaz: v0.6**

La interfaz muestra el número de versión y comprueba periódicamente si hay una versión posterior publicada; cuando la detecta, ofrece recargar la aplicación.

Aplicación web inicial para gestión de automotoras chilenas, con autenticación Supabase y un inventario de vehículos persistido en PostgreSQL.

## Estado actual

- Inicio de sesión por nombre y apellido, sin correo visible en la interfaz.
- No hay registro público en la interfaz. Las cuentas se crean desde **Administrar usuarios**.
- Perfiles y permisos: `sysadmin`, `administrador` y `vendedor`.
- Sysadmin y administrador pueden crear administradores o vendedores. La función de base de datos rechaza asignar `sysadmin` desde la gestión normal de usuarios.
- El perfil inicial de Mathias Michell está creado con rol `sysadmin` y asociado a la automotora interna MotorDMS Pro. La contraseña de esa cuenta debe terminar de establecerse desde la administración de Auth antes de poder verificar el acceso.
- Inventario conectado a `public.vehicles`: lectura, búsqueda, filtros y alta de vehículos persistidos en Supabase.
- Aislamiento por automotora mediante `dealership_id` y Row Level Security (RLS).


## Navegación mediante teclado (v0.6)

La aplicación incorpora navegación orientada al teclado en el acceso, inventario, panel administrativo y registro de ventas. Los botones muestran una etiqueta discreta con su combinación asignada. Atajos principales:

- `Alt + 1…9`: cambiar entre secciones del menú.
- `Alt + N`: crear o ingresar un registro nuevo.
- `Alt + S`: enviar/guardar el formulario activo.
- `Alt + F` o `/`: enfocar la búsqueda.
- `Alt + R`: actualizar datos.
- `Alt + V`: abrir el registro de ventas.
- `Alt + B`: volver al inventario.
- `Alt + Q`: cerrar sesión.
- `Esc`: cerrar ventanas y paneles.
- `Ctrl + K` o `?`: abrir el buscador de atajos y acciones.
- `Tab` / `Shift + Tab`: recorrer campos y controles; `Enter` / `Espacio` activa el control enfocado.

Las acciones adicionales reciben combinaciones únicas visibles junto a cada botón. Las sugerencias de autocompletado mantienen sus controles de flechas y Enter.

## Ejecutar

Abre la carpeta desde un servidor estático, por ejemplo:

```bash
python -m http.server 8080
```

Luego visita `http://localhost:8080`. Se requiere internet para cargar Supabase JS desde CDN y comunicarse con Supabase.

## Proyecto Supabase

- Proyecto: `ctillqsactkhwgxhfnoq`
- URL: `https://ctillqsactkhwgxhfnoq.supabase.co`
- El frontend utiliza exclusivamente una clave publishable pública. Nunca incluyas una clave `service_role` o secret key en el frontend.

El esquema incluye `dealerships`, `dealership_members`, `profiles`, `vehicles`, `vehicle_expenses`, `customers`, `leads`, `sales` y `audit_log`. Las migraciones de permisos y autenticación están versionadas en `supabase/migrations`.

## Acceso y permisos

El nombre de acceso se normaliza como usuario interno (por ejemplo, `Nombre Apellido` → `nombre.apellido`) y se vincula a un identificador interno de autenticación; no se requiere correo en la pantalla de inicio de sesión. Las contraseñas deben tener al menos 8 caracteres.

- **Sysadmin:** control global; puede crear administradores y vendedores. Es el único rol reservado para asignación inicial o intervención privilegiada.
- **Administrador:** puede crear administradores y vendedores.
- **Vendedor:** no puede crear cuentas ni administrar permisos.

La función `create_managed_user` valida los permisos del usuario autenticado y crea la cuenta con confirmación interna ya resuelta. Un trigger de base de datos bloquea inserciones de usuarios procedentes del servicio de registro público de Supabase Auth; la interfaz tampoco ofrece registro abierto. La autorización se valida en la base de datos, no solo ocultando botones.

## Límites pendientes

Esta es una integración inicial, no una declaración de preparación para producción. Antes de usar datos reales, hay que probar el inicio de sesión con la cuenta inicial y el alta de usuarios en el proyecto desplegado; además, clientes/prospectos, ventas, costos, auditoría funcional, recuperación segura de contraseña, edición/eliminación de vehículos y pruebas automatizadas aún requieren implementación.