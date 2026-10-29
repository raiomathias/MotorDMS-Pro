# AutoGest Pro

Aplicación web inicial para gestión de automotoras chilenas, con autenticación Supabase y un inventario de vehículos persistido en PostgreSQL.

## Estado actual

- Registro e inicio de sesión mediante Supabase Auth.
- Asistente de configuración inicial: el primer usuario autenticado crea su automotora y recibe el rol `propietario`.
- Perfil del propietario.
- Inventario conectado a `public.vehicles`: lectura, búsqueda, filtros y alta de vehículos persistidos en Supabase.
- Aislamiento por automotora mediante `dealership_id` y Row Level Security (RLS).
- Interfaz responsive en español y precios en CLP.

## Ejecutar

Abre la carpeta desde un servidor estático, por ejemplo:

```bash
python -m http.server 8080
```

Luego visita `http://localhost:8080`. Se requiere internet para cargar Supabase JS desde CDN y comunicarse con Supabase.

## Proyecto Supabase

- Proyecto: `ctillqsactkhwgxhfnoq`
- URL: `https://ctillqsactkhwgxhfnoq.supabase.co`
- La aplicación utiliza exclusivamente una clave publishable pública. Nunca incluyas una clave `service_role` o secret key en el frontend.

El esquema está aplicado en el proyecto e incluye `dealerships`, `dealership_members`, `profiles`, `vehicles`, `vehicle_expenses`, `customers`, `leads`, `sales` y `audit_log`. Todas las tablas expuestas tienen RLS activado.

## Flujo de acceso

1. Crear una cuenta con correo y contraseña de al menos 8 caracteres.
2. Confirmar el correo si Supabase Auth tiene habilitada la confirmación.
3. Iniciar sesión y completar nombre del propietario y nombre de la automotora.
4. La función de onboarding crea el perfil, la automotora y la membresía propietaria en una sola transacción.
5. Añadir vehículos; se guardan en Supabase y las consultas se limitan a la automotora del usuario.

La función de onboarding usa `SECURITY INVOKER`, valida `auth.uid()` y se apoya en políticas RLS para autorizar la creación inicial. La política de bootstrap permite que el usuario cree únicamente su propia automotora y se asigne el rol propietario una sola vez. La revisión de seguridad de Supabase no reporta alertas.

## Límites pendientes

Esta es una primera integración funcional, no una declaración de preparación para producción. El inventario está conectado; clientes/prospectos, ventas, costos, auditoría de cambios, invitaciones de equipo, recuperación de contraseña y pruebas automatizadas aún requieren implementación. Antes de usar datos reales, configurar SMTP y URL de redirección de Auth, probar aislamiento entre dos automotoras y revisar permisos de cada operación.
