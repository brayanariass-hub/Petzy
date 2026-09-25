# Seguridad

## Qué puede estar en el cliente

La URL del proyecto Supabase y la clave `sb_publishable_...` son identificadores y credenciales públicas del cliente. No conceden privilegios administrativos por sí mismas. El acceso real debe estar protegido con autenticación, RLS y políticas de Storage en Supabase.

La app Flutter distribuida debe considerarse inspeccionable. No debe contener:

- claves `service_role` de Supabase;
- secretos JWT o claves privadas;
- contraseñas de bases de datos;
- claves secretas de Stripe, Mercado Pago o AWS;
- certificados, keystores o tokens de servidores.

## Archivos protegidos

Los `.env`, certificados, material de firma y configuraciones locales están excluidos por los `.gitignore` raíz y del proyecto. Se puede publicar un `.env.example` sin valores reales si en el futuro se incorpora configuración no pública al backend.

La carpeta `build/` es salida generada. Para Flutter Web se publica únicamente el artefacto generado de `build/web`; no se debe configurar un servidor web para exponer la raíz del repositorio, `lib/`, `.dart_tool/`, `android/` o archivos de configuración.

## Respuesta ante exposición

Si alguna vez se publica una clave privada o secreta:

1. Revocarla o rotarla inmediatamente en el proveedor.
2. Revisar el historial Git y los logs de CI/CD.
3. Eliminarla del repositorio usando una herramienta de limpieza de historial si es necesario.
4. Crear una nueva credencial con permisos mínimos.
5. Revisar RLS, Storage policies y actividad del proveedor.

Eliminar el archivo en un commit posterior no basta: los secretos permanecen en el historial.

## Estado del backend

Las migraciones iniciales de perfiles, RLS, Storage privado y RPC de reservas viven en `Petzy App/supabase/migrations`. Deben ejecutarse en el proyecto Supabase y probarse con usuarios de distintos roles; su presencia en Git no significa que ya estén aplicadas en la nube.

## Reglas de backend

Las operaciones críticas, pagos, cambios de roles y autorización de transiciones deben ejecutarse y validarse en Supabase/RPC/Edge Functions. Nunca se debe confiar únicamente en validaciones de Flutter.
