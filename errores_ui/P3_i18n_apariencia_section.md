# P3 — Sección "Apariencia" hardcodeada en español

## Bug que corrige
- **Bug #4** — La sección "Apariencia" en Settings tiene el título hardcodeado en español en lugar de usar una clave ARB. Si el usuario cambia el idioma a inglés o rumano, el título seguirá en español.

## Archivos a modificar

| Archivo | Cambio |
|---------|--------|
| `lib/features/settings/presentation/settings_screen.dart` | Reemplazar string hardcodeado por `l10n.appearance` |
| `lib/l10n/app_es.arb` | Añadir clave `appearance` |
| `lib/l10n/app_en.arb` | Añadir clave `appearance` |
| `lib/l10n/app_ro.arb` | Añadir clave `appearance` |

## Cambio requerido

### 1. En settings_screen.dart

```dart
// ANTES
Text('Apariencia', style: ...),
// o
const ListTile(title: Text('Apariencia')),

// DESPUÉS
Text(l10n.appearance, style: ...),
// o
ListTile(title: Text(l10n.appearance)),
```

Para obtener `l10n`, en el widget:
```dart
final l10n = AppLocalizations.of(context)!;
```

### 2. En los archivos ARB

**`lib/l10n/app_es.arb`**:
```json
"appearance": "Apariencia",
"@appearance": {
  "description": "Settings section title for appearance/theme options"
}
```

**`lib/l10n/app_en.arb`**:
```json
"appearance": "Appearance",
"@appearance": {
  "description": "Settings section title for appearance/theme options"
}
```

**`lib/l10n/app_ro.arb`**:
```json
"appearance": "Aspect",
"@appearance": {
  "description": "Settings section title for appearance/theme options"
}
```

### 3. Verificar si hay otros strings hardcodeados en Settings

```bash
# Buscar strings en español hardcodeados en la capa de presentación
grep -rn "\"[A-ZÁÉÍÓÚÑ]" lib/features/settings/presentation/
grep -rn "\"[a-záéíóúñ]" lib/features/settings/presentation/ | grep -v "//\|import\|const "
```

## Criterios de aceptación

- [ ] Con idioma en inglés, la sección muestra "Appearance".
- [ ] Con idioma en español, la sección muestra "Apariencia".
- [ ] Con idioma en rumano, la sección muestra "Aspect".
- [ ] La clave `appearance` está en los 3 archivos ARB.
- [ ] `flutter analyze` no reporta strings sin localizar (si hay linter rule configurado).

## Tests requeridos

- Test de widget: `SettingsScreen` con locale `en` → sección muestra "Appearance".
- Test de widget: `SettingsScreen` con locale `es` → sección muestra "Apariencia".
