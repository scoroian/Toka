# CLAUDE.md — Toka: Instrucciones maestras para Claude Code

## ¿Qué es Toka?

Toka es una app cooperativa de gestión de tareas del hogar para parejas, familias y pisos compartidos. Permite repartir tareas con rotación, recurrencias, estadísticas, valoraciones y un modelo premium por hogar.

---

## Stack tecnológico

| Capa          | Tecnología                                              |
| ------------- | ------------------------------------------------------- |
| Cliente       | Flutter 3.x + Dart 3.x                                  |
| Auth          | Firebase Authentication (Google, Apple, email/password) |
| Base de datos | Cloud Firestore                                         |
| Archivos      | Cloud Storage (solo foto de perfil)                     |
| Backend       | Cloud Functions for Firebase (Node.js 20)               |
| Mensajería    | Firebase Cloud Messaging (FCM)                          |
| Config remota | Firebase Remote Config                                  |
| Analítica     | Firebase Analytics                                      |
| Estabilidad   | Firebase Crashlytics                                    |
| Publicidad    | Google AdMob                                            |
| Compras       | in_app_purchase + validación backend                    |
| i18n          | flutter_localizations + intl + ARB files                |
| Estado        | Riverpod (flutter_riverpod)                             |
| Navegación    | go_router                                               |
| Inyección     | get_it (solo para servicios singleton no-UI)            |
| Tests         | flutter_test, mocktail, integration_test, patrol        |

---

## Arquitectura del proyecto

```
lib/
├── main.dart
├── firebase_options.dart
├── app.dart                        # MaterialApp + GoRouter setup
├── core/
│   ├── constants/
│   ├── errors/
│   ├── extensions/
│   ├── theme/
│   └── utils/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   ├── application/
│   │   └── presentation/
│   ├── onboarding/
│   ├── i18n/
│   ├── homes/
│   ├── tasks/
│   ├── members/
│   ├── profile/
│   ├── history/
│   ├── notifications/
│   ├── subscription/
│   └── settings/
├── l10n/
│   ├── app_es.arb
│   ├── app_en.arb
│   └── app_ro.arb
└── shared/
    ├── widgets/
    ├── models/
    └── services/

functions/
├── src/
│   ├── index.ts
│   ├── entitlement/
│   ├── tasks/
│   ├── homes/
│   ├── notifications/
│   └── jobs/
├── package.json
└── tsconfig.json

test/
├── unit/
│   └── features/
├── integration/
│   └── features/
└── ui/
    └── features/

integration_test/
└── app_test.dart

firestore.rules
firestore.indexes.json
storage.rules
```

---

## Convenciones de código obligatorias

### Dart / Flutter

- **Siempre** usar `freezed` para modelos de dominio y estados.
- **Siempre** usar `riverpod_annotation` con `@riverpod` y `@riverpodKeepAlive`.
- Nombrar providers con sufijo `Provider`: `authStateProvider`, `homesProvider`.
- Repositorios: interfaz abstracta en `domain/`, implementación en `data/`.
- Cada feature tiene su propio `router.dart` con rutas nombradas.
- Constantes de rutas en `core/constants/routes.dart`.
- No usar `BuildContext` fuera de widgets. Los servicios no conocen el contexto.
- Todas las strings visibles al usuario deben ir en archivos ARB. **Nunca hardcodear texto UI**.
- Usar `l10n.nombreDeLaClave` para acceder a las traducciones.
- Los colores, tipografías y radios van en `core/theme/`.
- Usar `AsyncValue` de Riverpod para estados de carga/error/datos.

### Firestore

- Nunca hacer lecturas de listas completas sin paginación (`limit` + `startAfter`).
- La pantalla Hoy lee **un único documento**: `homes/{homeId}/views/dashboard`.
- Siempre cerrar listeners al salir de pantallas (usar `ref.onDispose`).
- Las operaciones críticas (completar tarea, pasar turno, downgrade) van por **Callable Functions o transacciones**.
- El estado Premium se lee SIEMPRE de Firestore, nunca del dispositivo.

### Tests

- **Todo código nuevo debe tener tests**. No se acepta código sin cobertura.
- Mínimo por cada unidad funcional:
  - 1 test unitario por caso feliz
  - 1 test unitario por caso de error/edge case
  - 1 test de integración si toca Firestore o Functions
  - 1 test de UI (golden o patrol) si es una pantalla nueva
- Usar `mocktail` para mocks. No usar `mockito`.
- Los tests de integración usan emuladores Firebase locales.

### Cloud Functions

- TypeScript estricto (`strict: true` en tsconfig).
- Todas las callable functions validan autenticación al inicio.
- Usar `FieldValue.serverTimestamp()` siempre para timestamps.
- Logging estructurado con `logger` de Firebase Functions.

---

## Reglas de negocio clave (resumen rápido)

1. **Premium es por hogar**, no por usuario.
2. Cada cuenta tiene **2 hogares base** + hasta **3 extra permanentes** por cobros válidos (máx 5).
3. Los créditos de plaza son **permanentes** aunque se cancele la suscripción.
4. Rol operativo y estado de facturación son **independientes**.
5. El pagador no puede ser expulsado mientras haya periodo Premium vigente.
6. La pantalla Hoy ordena: **Hora → Día → Semana → Mes → Año**, con subgrupos Por hacer / Hechas.
7. Pasar turno genera **penalización estadística visible antes de confirmar**.
8. Las notas de valoración son **privadas**: solo autor y evaluado.
9. El downgrade automático se activa si no hay decisión manual al llegar `premiumEndsAt`.
10. Ventana de rescate: **3 días antes** de `premiumEndsAt`. Ventana de restauración: **30 días** tras downgrade.

---

## Internacionalización (i18n)

- Idiomas iniciales: **Español (es), Inglés (en), Rumano (ro)**.
- La lista de idiomas disponibles se obtiene de Firestore: `app_config/languages` (colección pública).
- Estructura de cada documento en esa colección:
  ```json
  {
    "code": "es",
    "name": "Español",
    "flag": "🇪🇸",
    "arb_key": "app_es",
    "enabled": true,
    "sort_order": 1
  }
  ```
- La lista de idiomas **solo se consulta** en:
  1. Paso de selección de idioma del onboarding.
  2. Pantalla Ajustes → Idioma.
- La selección se guarda en `users/{uid}.locale` (string con el código, ej: `"es"`).
- Mientras no hay usuario autenticado, se usa `SharedPreferences` para guardar el código temporalmente.
- El idioma se aplica al iniciar la app leyendo de Firestore (usuario) o SharedPreferences (anónimo).

---

## Orden de las specs

Ver `execution-order.md` para el orden estricto de ejecución de las specs.

---

## Workflow de desarrollo

Seguir siempre estos pasos en orden:

1. Antes de implementar: usar la skill `superpowers:brainstorming` para confirmar el plan.
2. Implementar el código.
3. Ejecutar `flutter analyze` — debe pasar sin errores.
4. Compilar y desplegar en emulador: `flutter run -d emulator-5554`.
5. Capturar screenshot con ADB: `adb exec-out screencap -p > /tmp/screen.png`.
6. Analizar la captura visualmente contra la spec.
7. Si algo no cumple la spec → corregir y volver al paso 3.
8. Solo marcar una tarea como DONE cuando la captura confirme que es correcto.

### Criterios de aceptación UI

- Los textos deben ser legibles (sin overflow ni cortados).
- Los botones deben estar en la posición descrita en la spec.
- El espaciado debe ser consistente con Material Design 3.
- No puede haber pantallas en blanco ni errores visibles.

---

## Al terminar cada spec

Claude Code debe:

1. Ejecutar todos los tests de la spec y confirmar que pasan.
2. Imprimir al final un bloque `## Pruebas manuales requeridas` con los pasos exactos que debe hacer el desarrollador.
3. Confirmar qué archivos nuevos fueron creados y cuáles modificados.
4. Si algún test falla, NO marcar la spec como completa.

---

## Emuladores Firebase para desarrollo

```bash
# Iniciar emuladores
firebase emulators:start --import=./emulator-data --export-on-exit

# Puertos por defecto
# Auth:      9099
# Firestore: 8080
# Functions: 5001
# Storage:   9199
# Hosting:   5000
```

En `main_dev.dart` conectar todos los servicios a los emuladores.

### Emulador Android

```bash
# Dispositivo
Device: emulator-5554

# Lanzar app en el emulador
flutter run -d emulator-5554

# Capturar pantalla con ADB
adb exec-out screencap -p > /tmp/screen.png

# ADB path (ajustar según instalación local)
# macOS/Linux: ~/Library/Android/sdk/platform-tools/adb
# Windows:     %LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe
```

---

## Comandos útiles

```bash
# Generar código (freezed, riverpod, json_serializable)
dart run build_runner build --delete-conflicting-outputs

# Tests unitarios
flutter test test/unit/

# Tests de integración (requiere emuladores activos)
flutter test test/integration/

# Tests de UI
flutter test test/ui/

# Tests e2e con patrol
patrol test

# Análisis estático
flutter analyze

# Formatear
dart format .
```

## Lenguaje

Responder siempre en español
