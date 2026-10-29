# AutoGest Pro

Aplicación web inicial para gestión de automotoras chilenas, con autenticación Supabase y un inventario de vehículos persistido en PostgreSQL.

## Estado actual

- Registro e inicio de sesión mediante Supabase Auth.
- Configuración inicial de automotora: el primer usuario autenticado que completa el asistente queda como propietario.
- Tabla de perfiles para nombre del propietario.
- Inventario conectado a `public.vehicles`: lectura filtrada por automotora y alta de vehículos.
- Separación multiempresa por `dealership_id` y políticas Row Level Security (RLS).
- Interfaz responsive en español y precios en CLP.

## Ejecutar

Abre `index.html` desde un servidor estático, por ejemplo:

```bash
python -m http.server 8080
```

Luego visita `http://localhost:8080`. Se requiere conexión a internet para cargar Supabase JS desde CDN y comunicarse con Supabase.

## Proyecto Supabase

- Proyecto: `ctillqsactkhwgxhfnoq`
- URL: `https://ctillqsactkhwgxhfnoq.supabase.co`
- La aplicación utiliza únicamente la clave publishable pública. **Nunca añadir una clave `service_role` o secret key al frontend.**

El esquema y las funciones de onboarding están aplicados directamente en el proyecto Supabase. Las tablas incluyen `dealerships`, `dealership_members`, `profiles`, `vehicles`, `vehicle_expenses`, `customers`, `leads`, `sales` y `audit_log`. Todas las tablas de `public` tienen RLS habilitado.

## Flujo de acceso

1. Crear una cuenta con correo y contraseña (mínimo 8 caracteres).
2. Confirmar el correo si Supabase Auth exige confirmación.
3. Iniciar sesión y completar nombre del propietario y nombre de la automotora.
4. El servidor valida `auth.uid()`, crea el perfil, la automotora y la membresía `propietario` en una sola función transaccional.
5. Añadir vehículos. Los registros se guardan en Supabase y solo se consultan para la automotora del usuario autenticado.

La función de creación de automotora es `SECURITY DEFINER` intencionalmente para completar las tres inserciones protegidas de forma atómica. Tiene `search_path` vacío, valida la identidad con `auth.uid()`, rechaza usuarios sin sesión o ya asociados a una automotora y revoca ejecución a `PUBLIC` y `anon`; solo `authenticated` puede ejecutarla.

## Límites pendientes

Esta es una primera integración funcional, no una declaración de preparación para producción. El inventario está conectado; clientes/prospectos, ventas, costos, auditoría de cambios, invitaciones de equipo, recuperación de contraseña y pruebas automatizadas aún requieren implementación. Antes de usar datos reales, configurar SMTP y URL de redirección de Auth, probar aislamiento entre dos automotoras, y revisar roles/permisos en cada operación.
