# AutoGest Pro

**Prototipo SaaS de gestión para automotoras chilenas.** Interfaz en español chileno, con inventario, CRM, ventas, costos y reportes. Diseñado como demostración comercial, no para operar una automotora real todavía.

## Qué incluye

- Dashboard ejecutivo con indicadores, gráfico de ventas y estado de stock.
- Inventario con búsqueda, filtros por marca/estado, costos y margen estimado.
- Alta de vehículos con validaciones básicas y control de patente duplicada.
- Clientes y prospectos con etapas comerciales y próxima acción.
- Registro demostrativo de ventas y reservas.
- Costos y rentabilidad por vehículo, incluyendo ROI estimado.
- Reportes y exportación CSV compatible con Excel en formato chileno.
- Navegación responsive para escritorio, tablet y móvil.
- Funciones avanzadas señaladas como demostración: tasación asistida, publicación en portales, documentos digitales y más.
- Esquema inicial PostgreSQL/Supabase con separación por automotora, membresías, índices y RLS.

## Ejecutar la demo

No requiere instalación, build ni servidor backend.

1. Descarga/clona el repositorio.
2. Abre `index.html` en un navegador moderno. Si el navegador limita alguna función local, ejecuta un servidor estático desde esta carpeta, por ejemplo `python -m http.server 8080`, y abre `http://localhost:8080`.
3. Prueba búsqueda y filtros, exportaciones CSV y el botón **Ingresar vehículo**.

Los cambios de vehículos se guardan únicamente en `localStorage` del navegador actual. No hay inicio de sesión ni sincronización entre usuarios. Puedes borrar los datos locales del sitio para restablecer el entorno; el dataset de prueba está incluido en `app.js`.

## Conectar Supabase más adelante

1. Crea un proyecto Supabase independiente para AutoGest Pro.
2. Ejecuta `sql/001_schema.sql` en el SQL Editor.
3. Revisa y adapta los permisos por rol, las políticas RLS y los procesos de alta de automotoras/miembros antes de conectar una interfaz.
4. `sql/002_demo_seed.sql` contiene ejemplos comentados; no los ejecuta automáticamente.
5. Conecta Supabase Auth y sustituye el almacenamiento local por operaciones `supabase-js`. Nunca pongas la `service_role` key en el navegador; solo la clave publishable/anon con RLS correctamente configurado.

> **Importante:** el frontend actual no está conectado a Supabase. El SQL es una base de arquitectura inicial y debe revisarse y probarse antes de producción. No se ha desplegado ningún servicio ni se han usado datos reales.

## Estructura

```text
AutoGest-Pro/
├── index.html
├── styles.css
├── app.js
├── README.md
└── sql/
    ├── 001_schema.sql
    └── 002_demo_seed.sql
```

## Seguridad y límites de esta demo

- Todos los vehículos, nombres, teléfonos, correos y operaciones son ficticios. Las patentes están marcadas `DEMO-*` y los correos usan el dominio reservado `.test`.
- Las imágenes de vehículos se cargan desde URLs externas de Unsplash y requieren conexión a internet; existe fallback visual si una imagen no carga.
- No hay autenticación real, multiempresa operativa, integración con portales, firma electrónica, documentos, financiamiento ni asesoría tributaria.
- Los indicadores usan datos de muestra y no deben utilizarse para decisiones comerciales reales.
- El esquema incluye RLS por membresía de automotora, pero la autorización granular por rol y las pruebas de seguridad pendientes deben completarse antes de producción.

## Checklist de validación manual

- [ ] Abrir dashboard y navegar entre todas las secciones.
- [ ] Buscar vehículos por marca/modelo/patente y combinar filtros.
- [ ] Crear vehículo válido; comprobar que aparece en inventario y dashboard.
- [ ] Intentar repetir una patente; debe impedirse.
- [ ] Introducir valores inválidos; los campos deben bloquearlos.
- [ ] Exportar CSV de inventario, prospectos, ventas y costos.
- [ ] Revisar diseño en ancho móvil y escritorio.
- [ ] Probar navegación con teclado y cierre de modal con Escape.
- [ ] Ejecutar una revisión SQL/RLS en un proyecto Supabase de prueba antes de cualquier integración.
