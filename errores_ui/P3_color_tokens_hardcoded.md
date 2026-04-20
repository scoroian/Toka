# P3 — Colores hardcodeados en lugar de tokens de tema

## Bugs que corrige
- **Bug #6** — Settings usa `Colors.amber` y `Colors.red` directamente en vez de `AppColors` o `colorScheme`.
- **Bug #7** — HomeSettings usa `Colors.orange` y `Colors.red` directamente.

## Archivos a modificar

| Archivo | Colores a reemplazar |
|---------|---------------------|
| `lib/features/settings/presentation/settings_screen.dart` | `Colors.amber`, `Colors.red` |
| `lib/features/homes/presentation/home_settings_screen.dart` | `Colors.orange`, `Colors.red` |

## Cambios requeridos

### 1. Identificar todos los usos de colores hardcodeados

```bash
grep -rn "Colors\.\(amber\|red\|orange\|blue\|green\|purple\|yellow\)" lib/features/settings/ lib/features/homes/
```

### 2. Mapeo de colores a tokens de tema

| Color hardcodeado | Equivalente semántico recomendado |
|-------------------|----------------------------------|
| `Colors.red` (destructivo) | `Theme.of(context).colorScheme.error` |
| `Colors.red` (alerta) | `Theme.of(context).colorScheme.errorContainer` |
| `Colors.amber` (advertencia) | `Theme.of(context).colorScheme.tertiary` (o definir `AppColors.warning`) |
| `Colors.orange` (advertencia) | `Theme.of(context).colorScheme.tertiary` |

### 3. Ejemplo de sustitución

```dart
// ANTES
Icon(Icons.warning, color: Colors.amber),
Text('Error', style: TextStyle(color: Colors.red)),

// DESPUÉS
Icon(Icons.warning, color: Theme.of(context).colorScheme.tertiary),
Text('Error', style: TextStyle(color: Theme.of(context).colorScheme.error)),
```

### 4. Si se necesita un color de advertencia específico, definirlo en AppColors

En `lib/core/theme/app_colors.dart`:

```dart
class AppColors {
  // ... colores existentes
  static const Color warning = Color(0xFFFF9800); // Material Orange 500
  // Para el color adaptativo a tema oscuro, usar ColorScheme.tertiary
}
```

## Criterios de aceptación

- [ ] No queda ningún `Colors.amber`, `Colors.red`, `Colors.orange` en los archivos de Settings y HomeSettings.
- [ ] Los colores de error siguen siendo visualmente correctos en tema claro Y tema oscuro.
- [ ] Los colores de advertencia son coherentes con el design system.
- [ ] `flutter analyze` no reporta warnings de colores hardcodeados (si hay linter rule configurado).

## Tests requeridos

- Golden test: `SettingsScreen` en tema claro y oscuro → verificar que no hay colores que no cambian entre temas.
- Golden test: `HomeSettingsScreen` en tema claro y oscuro → mismo criterio.
