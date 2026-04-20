# P2 — Radar chart no renderiza en el perfil de miembro

## Bug que corrige
- **Bug #34** — El radar chart de estadísticas no aparece en ningún perfil (ni en el propio ni en el de otros miembros), incluso cuando el usuario tiene actividad registrada. La widget existe en el skin v2 pero no renderiza.

## Relación con otros bugs

Este bug está bloqueado parcialmente por **Bug #26** (stats siempre 0 porque `completedCount` ≠ `tasksCompleted`). Sin datos reales, es imposible confirmar si el radar chart renderiza correctamente cuando los datos son válidos. **Resolver Bug #26 primero** (ver `P0_stats_completedcount_mismatch.md`).

Sin embargo, el radar chart puede tener bugs propios independientes de Bug #26:
- Renderizar con datos vacíos/nulos puede causar crash silencioso.
- El provider `MemberRadarProvider` puede no estar conectado correctamente a la pantalla.

## Archivos a investigar

| Archivo | Qué buscar |
|---------|-----------|
| `lib/features/members/application/member_radar_provider.dart` | ¿Qué datos devuelve? ¿Maneja `null`/`0` correctamente? |
| `lib/features/members/presentation/widgets/member_radar_chart.dart` | ¿Hay guard para datos vacíos? |
| `lib/features/members/presentation/member_profile_screen.dart` o `skins/` | ¿Está el widget incluido en el árbol? |

## Cambios requeridos

### 1. Guard para datos vacíos en el radar chart

El componente del radar chart debe manejar el caso de todos los valores a 0:

```dart
class MemberRadarChart extends StatelessWidget {
  final MemberStats stats;
  
  @override
  Widget build(BuildContext context) {
    // Si todos los valores son 0, mostrar estado vacío
    if (stats.isEmpty) {
      return Center(
        child: Text(
          l10n.noStatsYet,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    
    return RadarChart(
      data: [
        stats.tasksCompleted.toDouble(),
        stats.currentStreak.toDouble(),
        stats.averageScore,
        stats.complianceRate,
        // ...otros ejes
      ],
    );
  }
}
```

### 2. Verificar que MemberRadarProvider está conectado a la pantalla

```dart
// En MemberProfileScreen o MemberProfileScreenV2
final radarAsync = ref.watch(memberRadarProvider(memberId));

radarAsync.when(
  loading: () => const SizedBox(height: 200, child: CircularProgressIndicator()),
  error: (e, st) => const SizedBox.shrink(), // fallo silencioso aceptable
  data: (stats) => MemberRadarChart(stats: stats),
),
```

### 3. Asegurar que el radar usa datos normalizados

Los ejes del radar deben estar en escala 0-1 o 0-100 para que el gráfico sea visualmente coherente:

```dart
// Normalizar valores para el radar
final normalized = RadarData(
  tasksCompleted: (stats.tasksCompleted / maxTasks).clamp(0.0, 1.0),
  complianceRate: stats.complianceRate / 100.0,
  currentStreak: (stats.currentStreak / maxStreak).clamp(0.0, 1.0),
  averageScore: stats.averageScore / 5.0, // si la escala es 0-5
);
```

### 4. Test de renderizado con datos reales

Después de implementar el fix de Bug #26, completar varias tareas con la cuenta Owner y verificar:
- El perfil propio muestra el radar con al menos un eje > 0.
- El radar tiene etiquetas legibles en los ejes.
- No hay overflow ni crash al renderizar.

## Criterios de aceptación

- [ ] Con todos los stats a 0: se muestra un mensaje "Sin estadísticas todavía" en lugar del radar vacío.
- [ ] Con al menos un stat > 0 (tras fix de Bug #26): el radar chart renderiza correctamente.
- [ ] Los ejes del radar tienen labels legibles.
- [ ] El radar no causa crash ni overflow con valores extremos (0 o muy altos).
- [ ] El widget aparece tanto en el perfil propio como en el de otros miembros.

## Tests requeridos

- Test de widget: `MemberRadarChart` con `stats.isEmpty == true` → muestra texto "Sin estadísticas".
- Test de widget: `MemberRadarChart` con datos válidos → renderiza sin errores (snapshot/golden test).
- Test de widget: `MemberProfileScreen` con provider mock de stats → radar visible en el árbol.
