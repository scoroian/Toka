# Spec-01: Internacionalización y lista de idiomas desde Firebase

**Dependencias previas:** Spec-00  
**Oleada:** Pre-oleada (base técnica)

---

## Objetivo

Implementar el sistema completo de internacionalización: ARB files, generación de código `AppLocalizations`, servicio de idioma, y consulta a Firebase de la lista pública de idiomas disponibles.

---

## Reglas de negocio

1. La lista de idiomas disponibles se obtiene de Firestore en la colección `app_config/languages` (lectura pública, sin autenticación).
2. La lista **solo se consulta** en dos momentos:
   - Pantalla de selección de idioma del onboarding.
   - Pantalla Ajustes → Idioma.
3. La selección del usuario se guarda en:
   - **Pre-auth:** `SharedPreferences` con clave `locale`.
   - **Post-auth:** Campo `locale` en `users/{uid}` en Firestore.
4. Al iniciar la app, se lee el idioma desde Firestore (si hay usuario) o SharedPreferences (si no).
5. El idioma por defecto si no hay selección es el idioma del dispositivo, con fallback a `es`.

---

## Archivos a crear / modificar

```
lib/
├── l10n/
│   ├── app_es.arb               (ampliar con todas las claves)
│   ├── app_en.arb
│   └── app_ro.arb
├── features/
│   └── i18n/
│       ├── data/
│       │   └── language_repository_impl.dart
│       ├── domain/
│       │   ├── language.dart          (modelo freezed)
│       │   └── language_repository.dart (interfaz)
│       ├── application/
│       │   ├── language_provider.dart
│       │   └── locale_provider.dart
│       └── presentation/
│           └── language_selector_widget.dart
└── core/
    └── services/
        └── locale_service.dart
```

---

## Implementación

### 1. ARB files completos

Añadir al menos estas claves en los tres archivos (es/en/ro):

**Claves de autenticación:**

- `auth_title`, `auth_subtitle`, `auth_google`, `auth_apple`, `auth_email`
- `auth_email_label`, `auth_password_label`, `auth_login`, `auth_register`
- `auth_forgot_password`, `auth_reset_sent`

**Claves de onboarding:**

- `onboarding_welcome`, `onboarding_select_language`, `onboarding_create_home`
- `onboarding_join_home`, `onboarding_your_name`, `onboarding_photo_optional`

**Claves de ajustes:**

- `settings_title`, `settings_language`, `settings_account`, `settings_privacy`
- `settings_notifications`, `settings_subscription`, `settings_logout`

**Claves de idioma:**

- `language_select_title`, `language_select_subtitle`, `language_saved`

**Claves generales ya definidas en spec-00:** loading, error_generic, retry, cancel, confirm, save, delete, back, next, done, skip.

### 2. Configurar generación de localizations

`pubspec.yaml`:

```yaml
flutter:
  generate: true

# archivo l10n.yaml en raíz:
```

`l10n.yaml`:

```yaml
arb-dir: lib/l10n
template-arb-file: app_es.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
preferred-supported-locales: [es, en, ro]
```

### 3. Modelo Language

```dart
// features/i18n/domain/language.dart
@freezed
class Language with _$Language {
  const factory Language({
    required String code,
    required String name,
    required String flag,
    required String arbKey,
    required bool enabled,
    required int sortOrder,
  }) = _Language;

  factory Language.fromFirestore(Map<String, dynamic> data) => Language(
    code: data['code'] as String,
    name: data['name'] as String,
    flag: data['flag'] as String,
    arbKey: data['arb_key'] as String,
    enabled: data['enabled'] as bool? ?? true,
    sortOrder: data['sort_order'] as int? ?? 99,
  );
}
```

### 4. Repositorio de idiomas

```dart
// domain/language_repository.dart
abstract interface class LanguageRepository {
  Future<List<Language>> fetchAvailableLanguages();
}

// data/language_repository_impl.dart
class LanguageRepositoryImpl implements LanguageRepository {
  final FirebaseFirestore _firestore;

  @override
  Future<List<Language>> fetchAvailableLanguages() async {
    final snapshot = await _firestore
        .collection('app_config')
        .doc('languages')  // Nota: colección app_config, documentos son los códigos
        // CORRECCIÓN: es una SUBcolección
        // Ruta real: app_config/languages/{code}
        .collection('items')
        // RUTA FINAL según data-model.md: app_config/languages/{code}
        // Implementar como colección directa:
        .get();
    // Ver nota de implementación abajo
  }
}
```

**Nota de implementación:** La colección pública es `app_config/languages` donde cada documento tiene como ID el código de idioma (`es`, `en`, `ro`). El repositorio hace:

```dart
final snapshot = await _firestore
    .collection('app_config')
    .doc('languages')
    // No: la ruta es colección app_config, documentos son los códigos
    // REAL: colección separada
    .collection('available')
    .where('enabled', isEqualTo: true)
    .orderBy('sort_order')
    .get();
```

**DECISIÓN FINAL de ruta:** Usar `languages` como colección de primer nivel separada para simplicidad de Security Rules:

```
languages/{code}  →  { code, name, flag, arb_key, enabled, sort_order }
```

Security Rule: `match /languages/{code} { allow read: if true; allow write: if false; }`

### 5. LocaleService

```dart
// core/services/locale_service.dart
class LocaleService {
  static const _key = 'locale';

  final SharedPreferences _prefs;
  final FirebaseFirestore _firestore;

  // Leer locale: Firestore (auth) o SharedPreferences (no-auth)
  Future<Locale> getCurrentLocale(String? uid) async { ... }

  // Guardar locale
  Future<void> saveLocale(String code, String? uid) async {
    await _prefs.setString(_key, code);
    if (uid != null) {
      await _firestore.collection('users').doc(uid).update({'locale': code});
    }
  }

  // Locale por defecto según sistema
  Locale get deviceLocale => ... // usa Platform.localeName

  // Fallback
  static const fallback = Locale('es');
  static const supported = [Locale('es'), Locale('en'), Locale('ro')];
}
```

### 6. Providers de idioma

```dart
// application/locale_provider.dart
@Riverpod(keepAlive: true)
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Locale build() => const Locale('es'); // inicial, se actualiza

  Future<void> initialize(String? uid) async { ... }
  Future<void> setLocale(String code, String? uid) async { ... }
}

// application/language_provider.dart
@riverpod
Future<List<Language>> availableLanguages(Ref ref) async {
  final repo = ref.watch(languageRepositoryProvider);
  return repo.fetchAvailableLanguages();
}
```

### 7. Widget selector de idioma (reutilizable)

```dart
// presentation/language_selector_widget.dart
// Lista vertical de idiomas con bandera, nombre, y radio button
// Se usa tanto en onboarding como en ajustes
class LanguageSelectorWidget extends ConsumerWidget {
  final bool showTitle;
  final VoidCallback? onSelected;
  ...
}
```

### 8. Integrar en app.dart

```dart
// app.dart
class TokaApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeNotifierProvider);

    return MaterialApp.router(
      locale: locale,
      supportedLocales: LocaleService.supported,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: appRouter,
      theme: AppTheme.light,
      ...
    );
  }
}
```

### 9. Datos iniciales en emulador

Crear script `scripts/seed_languages.ts` para poblar la colección `languages` en el emulador:

```typescript
const languages = [
  {
    code: "es",
    name: "Español",
    flag: "🇪🇸",
    arb_key: "app_es",
    enabled: true,
    sort_order: 1,
  },
  {
    code: "en",
    name: "English",
    flag: "🇬🇧",
    arb_key: "app_en",
    enabled: true,
    sort_order: 2,
  },
  {
    code: "ro",
    name: "Română",
    flag: "🇷🇴",
    arb_key: "app_ro",
    enabled: true,
    sort_order: 3,
  },
];
```

---

## Tests requeridos

### Unitarios

**`test/unit/features/i18n/language_test.dart`**

- `Language.fromFirestore` parsea correctamente un mapa válido.
- `Language.fromFirestore` usa valores por defecto si faltan campos opcionales.

**`test/unit/features/i18n/locale_service_test.dart`**

- `getCurrentLocale` devuelve el locale de SharedPreferences si no hay uid.
- `getCurrentLocale` devuelve el locale de Firestore si hay uid.
- `saveLocale` guarda en SharedPreferences siempre.
- `saveLocale` guarda en Firestore si hay uid.
- `deviceLocale` devuelve la locale del sistema.
- Si la locale del sistema no está soportada, `getCurrentLocale` devuelve fallback `es`.

**`test/unit/features/i18n/language_repository_impl_test.dart`**

- `fetchAvailableLanguages` devuelve lista ordenada por `sort_order`.
- `fetchAvailableLanguages` filtra idiomas con `enabled: false`.
- `fetchAvailableLanguages` lanza `LanguagesFetchException` si Firestore falla.

### De integración

**`test/integration/features/i18n/language_fetch_test.dart`**

- Usando `fake_cloud_firestore`, poblar colección `languages` y verificar que el repo devuelve los idiomas correctos.
- Verificar que la colección es accesible sin autenticación (simular Security Rules).

### UI

**`test/ui/features/i18n/language_selector_widget_test.dart`**

- Renderiza la lista con bandera, nombre y radio button por cada idioma.
- Al tocar un idioma, llama al provider y actualiza la locale.
- Golden test con los tres idiomas visibles.

---

## Pruebas manuales requeridas al terminar esta spec

1. **Cambio de idioma sin usuario autenticado:**
   - Abrir la app en modo dev.
   - Forzar la aparición del selector de idioma (puede ser en una pantalla de debug temporal).
   - Seleccionar "English" → toda la UI cambia al inglés.
   - Seleccionar "Română" → toda la UI cambia al rumano.
   - Cerrar y reabrir la app → debe mantener el rumano (guardado en SharedPreferences).

2. **Verificar la colección Firebase:**
   - Abrir Firestore Emulator UI → colección `languages`.
   - Verificar que hay tres documentos: `es`, `en`, `ro`.
   - Cada uno debe tener `flag`, `name`, `arb_key`, `enabled`, `sort_order`.

3. **Verificar fallback de idioma:**
   - Borrar las SharedPreferences del dispositivo.
   - Si el idioma del dispositivo es español → la app debe abrirse en español.
   - Si el idioma del dispositivo es alemán (no soportado) → debe abrirse en español (fallback).

4. **Verificar que la lista solo se consulta cuando toca:**
   - Abrir la app con el idioma ya guardado.
   - En las herramientas de red del emulador, verificar que NO hay una llamada a la colección `languages` al arrancar (solo se hace en onboarding o ajustes/idioma).
