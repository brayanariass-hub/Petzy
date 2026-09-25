# Estructura del proyecto

## Codigo fuente

```text
lib/
├── core/
│   ├── constants/       # Valores publicos y configuracion de app
│   ├── di/              # Composicion de implementaciones concretas
│   ├── errors/          # Errores compartidos
│   ├── router/          # GoRouter global
│   └── theme/           # Tema visual
├── features/
│   ├── auth/
│   │   ├── data/        # Supabase Auth
│   │   ├── domain/      # Usuario y contrato AuthRepository
│   │   └── presentation/# Login, registro y providers
│   ├── bookings/
│   │   ├── data/        # Datasources, modelos y repositorios
│   │   ├── domain/      # Reserva, estados y casos de uso
│   │   └── presentation/# Pantallas y providers
│   ├── pets/
│   │   ├── data/        # Repositorio Supabase de mascotas
│   │   ├── domain/      # Mascota, PetDraft y contratos
│   │   └── presentation/# Pantallas y cache Riverpod
│   ├── sitter/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── home/
│       └── presentation/ # Shell que compone varias features
│           ├── providers/
│           └── screens/
└── main.dart
```

## Direccion de dependencias

```text
features/*/data -> features/*/domain
features/*/presentation -> features/*/domain
features/*/presentation -> core
core/di -> features/*/data + features/*/domain
```

Cada `features/<name>/domain` no depende de Flutter, Supabase, Riverpod ni archivos de plataforma. `data` conoce Supabase. `presentation` conoce Riverpod y widgets, pero no debe llamar directamente al SDK de Supabase.

## Que puede estar visible en GitHub

En un repositorio publico pueden estar:

- `lib/`, `test/`, `web/` y configuracion Flutter no secreta.
- URLs de Supabase y claves `sb_publishable_...` publicas.
- Migraciones SQL, siempre que no incluyan secretos.
- `.env.example` sin valores reales.
- Documentacion y archivos de CI sin credenciales.

El codigo Flutter distribuido se considera inspeccionable. Nunca se debe colocar seguridad critica en el cliente.

## Que no debe estar versionado ni expuesto

- `.env`, `.env.local` y credenciales reales.
- Claves `service_role`, JWT secrets y contraseñas de base de datos.
- Secret keys de pagos, AWS tokens y tokens de CI/CD.
- Keystores, certificados privados, `*.pem`, `*.p12`, `*.jks` y `key.properties`.
- `local.properties`, `.dart_tool/`, `build/`, `coverage/` y caches de IDE.
- Backups de base de datos o dumps con información personal.

## Despliegue web

GitHub puede contener el código fuente. El servidor web no debe apuntar al repositorio raíz. Para Flutter Web se publica solamente el contenido generado en `build/web`.

No se deben servir directamente `lib/`, `test/`, `data/`, `domain/`, `android/`, `.dart_tool/` ni archivos `.env`.

## Reglas prácticas

1. Toda pantalla usa providers o casos de uso, nunca Supabase directamente.
2. Toda escritura remota pasa por un repositorio y actualiza el estado Riverpod.
3. Toda autorización real se valida también en Supabase mediante RLS, RPC o Edge Functions.
4. Las migraciones y políticas de Supabase deben versionarse en `supabase/migrations/` cuando se incorporen al repositorio.
5. Antes de publicar: `flutter analyze`, `flutter test` y una comprobación de secretos.
