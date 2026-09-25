# Arquitectura y escalabilidad de Petzy

## Estado actual

Petzy es un cliente Flutter que usa Supabase como backend administrado, PostgreSQL como base de datos y Riverpod como estado reactivo/cache en memoria.

| Area | Estado | Evidencia o siguiente accion |
| --- | --- | --- |
| Capas desacopladas | MVP cubierto | Cada feature contiene `data`, `domain` y `presentation`; `core/di` compone implementaciones. |
| API-first | Parcial | Supabase expone una API REST generada. Las consultas deben mantener columnas explicitas, filtros y paginacion. |
| Cache cliente | Cubierto parcialmente | Riverpod mantiene el cache en memoria e invalida tras mutaciones. No es Redis ni cache distribuida. |
| Persistencia | Cubierto con migraciones | Supabase PostgreSQL, migraciones en `supabase/migrations` y RLS; deben ejecutarse y verificarse en tu proyecto. |
| Procesamiento asincrono | Pendiente de backend | Emails, reportes, thumbnails y tareas pesadas deben vivir en Edge Functions/Workers con una cola. No deben ejecutarse en Flutter. |
| Stateless backend | Delegado a Supabase | La app usa la sesion/token de Supabase; no mantiene sesiones en memoria de un servidor propio. |
| Rate limiting | Pendiente de plataforma | Configurar limites en Supabase/API Gateway/Cloudflare antes de exponer endpoints propios. |
| Observabilidad | Pendiente | Agregar errores y metricas en Supabase/Edge Functions y un proveedor APM antes de produccion. |
| Pruebas de carga | Pendiente | Definir escenarios y ejecutar k6 contra el backend desplegado, no contra tests Flutter. |
| CDN y balanceador | Delegado a plataforma | Supabase Storage/CDN y el proveedor de despliegue deben cubrir esta capa. |
| Docker/Kubernetes | No aplica aun | No existe backend propio que empaquetar. Adoptarlo ahora agregaria complejidad sin resolver un cuello de botella medido. |
| Estados de reserva | Cubierto cliente + RPC | El cliente valida UX y `create_booking` calcula precio, propiedad y estado inicial en servidor. |
| Offline/reconexion | Ausente | Riverpod conserva cache durante la vida del provider, pero no hay cola local ni reintentos persistentes para operaciones offline. |
| Tiempo real | Ausente | No hay suscripciones Realtime para reservas o disponibilidad; agregarlas cuando exista una pantalla que necesite actualizacion en vivo. |

## Limites de responsabilidad

- `features/<feature>/presentation`: widgets, navegacion local y estado efimero de UI.
- `features/<feature>/domain`: entidades, contratos y reglas de negocio aisladas.
- `features/<feature>/data`: implementaciones de repositorios, serializacion y acceso a Supabase.
- `features/pets/domain/entities/pet_draft.dart`: entrada de dominio para crear mascotas sin exponer payloads al repositorio.
- `features/home/presentation`: shell que compone varias features, no contiene reglas de dominio.
- `supabase/migrations`: perfiles, RLS, Storage privado y RPC de reservas; se ejecutan fuera de Flutter.
- Supabase/Edge Functions: autorizacion de servidor, operaciones atomicas, tareas pesadas, limites de tasa y procesos asincronos.

## Reglas de rendimiento

1. Toda consulta nueva debe seleccionar columnas explicitas.
2. Toda lista remota debe tener limite y paginacion; nunca usar `select()` ilimitado en una pantalla.
3. Los providers Riverpod son la fuente de lectura para el cliente y deben actualizar o invalidar el cache despues de escribir.
4. No poner claves secretas, credenciales de servicio ni reglas de autorizacion solo en Flutter.
5. Las operaciones que cruzan varias tablas deben implementarse como RPC/Edge Function transaccional cuando la consistencia lo requiera.
6. Las imagenes grandes deben procesarse fuera de la peticion interactiva, idealmente con Storage triggers y un worker.
7. Las transiciones de reserva deben validarse en dominio para la UX y en una funcion/RLS del servidor para seguridad.
8. No llamar al SDK de Supabase desde widgets; los repositorios son la frontera de infraestructura.
9. Los providers Riverpod deben depender de contratos de `domain`; las implementaciones concretas se registran al componer la app.

## Hoja de ruta antes de produccion

1. Ejecutar y adaptar las migraciones de `supabase/migrations` y revisar indices PostgreSQL con `EXPLAIN ANALYZE`.
2. Añadir tests de repositorios con fakes y tests de providers sin red.
3. Configurar logs estructurados, alertas de errores, latencia, tasa de fallos y uso de Storage.
4. Implementar rate limiting y validacion de payloads en Edge Functions/API Gateway.
5. Definir jobs asincronos para correo, imagenes y reportes con reintentos e idempotencia.
6. Ejecutar pruebas de carga con k6 sobre un entorno staging y establecer objetivos de latencia y disponibilidad.
7. Adoptar replicas de lectura, Redis o microservicios solo cuando las metricas y el volumen justifiquen esas piezas.
8. Separar la construccion de `PetDraft` del widget en un use case cuando el formulario crezca.
9. Definir una politica offline explicita antes de agregar SQLite: operaciones idempotentes, reintentos con backoff y resolucion de conflictos.
