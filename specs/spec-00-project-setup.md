# Spec-00: Configuración inicial del proyecto

**Dependencias previas:** Ninguna  
**Oleada:** Pre-oleada (base técnica)

---

## Objetivo

Crear el proyecto Flutter desde cero con toda la configuración técnica necesaria: Firebase, estructura de carpetas, dependencias, temas, emuladores, linting y CI básico.

---

## Tareas

### 1. Crear proyecto Flutter

```bash
flutter create toka --org com.toka --platforms android,ios
cd toka
```

### 2. Configurar Firebase

```bash
# Instalar FlutterFire CLI si no existe
dart pub global activate flutterfire_cli

# Inicializar Firebase (requiere proyecto Firebase creado previamente)
flutterfire configure
```

Crear los flavors: `dev` y `prod`. En `dev`, conectar todos los servicios a los emuladores.

Archivos a crear:

- `lib/main_dev.dart` — entry point con emuladores
- `lib/main_prod.dart` — entry point producción
- `lib/main.dart` — redirige según flavor

### 3. Dependencias (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # Firebase
  firebase_core: ^3.x
  firebase_auth: ^5.x
  cloud_firestore: ^5.x
  firebase_storage: ^12.x
  firebase_messaging: ^15.x
  firebase_analytics: ^11.x
  firebase_crashlytics: ^4.x
  firebase_remote_config: ^5.x
  firebase_app_check: ^0.x
  google_mobile_ads: ^5.x
  in_app_purchase: ^3.x

  # Estado y navegación
  flutter_riverpod: ^2.x
  riverpod_annotation: ^2.x
  go_router: ^14.x

  # Modelos
  freezed_annotation: ^2.x
  json_annotation: ^4.x

  # UI
  cached_network_image: ^3.x
  image_picker: ^1.x

  # Auth social
  google_sign_in: ^6.x
  sign_in_with_apple: ^6.x

  # Utilidades
  shared_preferences: ^2.x
  intl: ^0.19.x
  uuid: ^4.x
  equatable: ^2.x

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter

  # Generadores
  build_runner: ^2.x
  freezed: ^2.x
  riverpod_generator: ^2.x
  json_serializable: ^6.x

  # Tests
  mocktail: ^1.x
  patrol: ^3.x
  fake_cloud_firestore: ^3.x
  firebase_auth_mocks: ^0.x

  # Calidad
  flutter_lints: ^4.x
  custom_lint: ^0.x
  riverpod_lint: ^2.x
```

### 4. Estructura de carpetas

Crear la estructura completa según `CLAUDE.md`:

```
lib/
├── main.dart
├── main_dev.dart
├── main_prod.dart
├── firebase_options.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── routes.dart
│   │   └── app_constants.dart
│   ├── errors/
│   │   ├── failures.dart
│   │   └── exceptions.dart
│   ├── extensions/
│   │   ├── context_extensions.dart
│   │   └── string_extensions.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   └── app_text_styles.dart
│   └── utils/
│       └── logger.dart
├── features/           # vacío por ahora, se llena por specs
├── l10n/
│   ├── app_es.arb
│   ├── app_en.arb
│   └── app_ro.arb
├── shared/
│   ├── widgets/
│   │   └── loading_widget.dart
│   ├── models/
│   └── services/
│       └── analytics_service.dart
```

### 5. Tema visual de Toka

Paleta principal (crear en `app_colors.dart`):

| Token         | Color          | Hex     |
| ------------- | -------------- | ------- |
| primary       | Coral cálido   | #F4845F |
| secondary     | Menta suave    | #81C99C |
| surface       | Blanco roto    | #FAFAF8 |
| background    | Gris muy claro | #F2F2EF |
| onPrimary     | Blanco         | #FFFFFF |
| error         | Rojo suave     | #E05C5C |
| textPrimary   | Gris oscuro    | #2D2D2D |
| textSecondary | Gris medio     | #7A7A7A |

Fuente: Inter (Google Fonts).

Usar Material 3 (`useMaterial3: true`).

### 6. ARB mínimos iniciales

Crear `app_es.arb`, `app_en.arb`, `app_ro.arb` con las claves base del app:

```json
{
  "@@locale": "es",
  "appName": "Toka",
  "loading": "Cargando...",
  "error_generic": "Algo salió mal. Inténtalo de nuevo.",
  "retry": "Reintentar",
  "cancel": "Cancelar",
  "confirm": "Confirmar",
  "save": "Guardar",
  "delete": "Eliminar",
  "back": "Atrás",
  "next": "Siguiente",
  "done": "Hecho",
  "skip": "Omitir"
}
```

### 7. Configuración lint

`analysis_options.yaml`:

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  plugins:
    - custom_lint
  errors:
    missing_required_param: error
    missing_return: error

linter:
  rules:
    - always_declare_return_types
    - avoid_print
    - prefer_const_constructors
    - prefer_final_fields
```

### 8. Firebase emuladores

`firebase.json`:

```json
{
  "emulators": {
    "auth": { "port": 9099 },
    "firestore": { "port": 8080 },
    "functions": { "port": 5001 },
    "storage": { "port": 9199 },
    "ui": { "enabled": true }
  }
}
```

`main_dev.dart`:

```dart
// Conectar a emuladores en modo dev
await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
```

### 9. Cloud Functions — setup inicial

```bash
cd functions
npm install --save-dev typescript @types/node
npm install firebase-admin firebase-functions
```

`functions/tsconfig.json`:

```json
{
  "compilerOptions": {
    "module": "commonjs",
    "noImplicitReturns": true,
    "noUnusedLocals": true,
    "outDir": "lib",
    "sourceMap": true,
    "strict": true,
    "target": "es2020"
  }
}
```

`functions/src/index.ts`:

```typescript
import * as admin from "firebase-admin";
admin.initializeApp();

// Las funciones se importan desde sus módulos
export * from "./entitlement";
export * from "./tasks";
export * from "./homes";
export * from "./notifications";
export * from "./jobs";
```

---

## Tests requeridos

### Unitarios

- `test/unit/core/theme/app_colors_test.dart` — Verificar que los colores definidos tienen el valor hex correcto.
- `test/unit/core/constants/routes_test.dart` — Verificar que todas las rutas constantes tienen valores únicos.

### UI

- `test/ui/core/theme/app_theme_test.dart` — Golden test del tema claro y oscuro (pantalla vacía con tema aplicado).

### De integración

- `test/integration/firebase_connection_test.dart` — Verificar conexión a emuladores de Auth y Firestore.

---

## Pruebas manuales requeridas al terminar esta spec

1. **Ejecutar la app en modo dev:**

   ```bash
   flutter run --target lib/main_dev.dart
   ```

   → La app debe arrancar sin errores en la pantalla de inicio (puede ser un scaffold vacío).

2. **Verificar conexión a emuladores:**
   - Abrir `http://localhost:4000` (Firebase Emulator UI).
   - Confirmar que aparecen los emuladores de Auth, Firestore y Storage activos.

3. **Verificar tema:**
   - La app debe mostrar la paleta coral/menta.
   - El texto debe usar la fuente Inter.

4. **Verificar build:**

   ```bash
   flutter build apk --debug --target lib/main_dev.dart
   ```

   → Debe compilar sin errores ni warnings bloqueantes.

5. **Verificar análisis estático:**

   ```bash
   flutter analyze
   ```

   → Cero errores. Advertencias mínimas y justificadas.

6. **Verificar generación de código:**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
   → Sin conflictos ni errores.
