# Fallos preexistentes de la suite Dart — recuento verificado

> Sustituye al "~68 fallos pre-existentes (shader `ink_sparkle.frag` + goldens)"
> aproximado de `FIX_PROMPTS.md` §0, que estaba desfasado.

**Fecha de medición:** 2026-06-18 · **Comando:** `flutter test test/unit test/ui --reporter expanded` (Flutter 3.44.2, WSL) · **Resultado:** `790 passed / 57 failed`.

- `test/integration/` **no** se incluye: requiere los emuladores Firebase locales; sin ellos falla por conexión, no por entorno, y contaminaría el conteo.
- **Ninguno** de los 57 está en `test/unit/`. Los 57 están en `test/ui/`.
- No son regresiones de los fixes de esta sesión QA.

## Desglose por causa raíz (57)

| Causa | Nº | Notas |
|---|---:|---|
| **Golden mismatch** | 45 | Imágenes golden generadas en otra máquina/backend de render; `flutter test` local las compara y difieren. Causa dominante. |
| **Timezone sin inicializar** (`LocationNotFoundException`) | 4 | Solo `create_task_screen_test.dart`: su `build` llama `upcomingDates` → `tz.getLocation()` y el test no hace `tzdata.initializeTimeZones()` en `setUpAll`. Setup gap, fix trivial. |
| **GoError / falta `GoRouter` en el harness** | ~3 | `members_screen_test.dart` (×2), `all_tasks_screen_v2_test.dart`: el widget usa go_router y el harness no provee un `GoRouter`. |
| **`pumpAndSettle` timed out** | 2 | `onboarding_flow_test.dart`. |
| **Aserción de layout/widget** | ~3 | `all_tasks_screen_v2_fab_banner_test.dart` (FAB vs banner), `home_selector_widget_test.dart` (flecha), `history_screen_v2_test.dart`. |

## Correcciones frente a `FIX_PROMPTS.md` §0

1. El número real es **57**, no ~68 (varios pudieron arreglarse con los fixes de la sesión en curso, o el ~68 era aproximado/incluía integración).
2. El shader **`ink_sparkle.frag` NO aparece** en la corrida (0 ocurrencias). La causa dominante son **golden mismatches**, no el shader.
3. Hay causas que §0 no menciona: **timezone, GoRouter, timeouts, layout**.

## Ficheros con fallos (nº de tests fallidos)

```
 9  test/ui/features/onboarding/onboarding_flow_test.dart        (7 golden + 2 timeout)
 8  test/ui/features/tasks/create_task_screen_test.dart          (4 golden + 4 timezone)
 6  test/ui/features/subscription/plan_summary_card_test.dart    (golden)
 5  test/ui/features/settings/settings_screen_test.dart          (golden)
 4  test/ui/features/subscription/premium_state_banner_test.dart (golden)
 4  test/ui/features/members/members_screen_test.dart            (2 golden + 2 GoError)
 3  test/ui/features/tasks/today_task_card_todo_test.dart        (golden)
 2  test/ui/shared/widgets/ad_aware_scaffold_test.dart           (golden)
 2  test/ui/features/homes/home_settings_screen_test.dart        (golden)
 2  test/ui/features/homes/home_selector_widget_test.dart        (1 golden + 1 aserción)
 1  test/ui/features/tasks/today_task_card_done_test.dart        (golden)
 1  test/ui/features/tasks/pass_turn_dialog_test.dart            (golden)
 1  test/ui/features/tasks/complete_task_dialog_test.dart        (golden)
 1  test/ui/features/tasks/all_tasks_screen_v2_test.dart         (GoError)
 1  test/ui/features/tasks/all_tasks_screen_v2_fab_banner_test.dart (aserción)
 1  test/ui/features/subscription/rescue_banner_test.dart        (golden)
 1  test/ui/features/subscription/paywall_screen_test.dart       (golden)
 1  test/ui/features/profile/review_dialog_test.dart             (golden)
 1  test/ui/features/profile/radar_chart_widget_test.dart        (golden)
 1  test/ui/features/i18n/language_selector_widget_test.dart     (golden)
 1  test/ui/features/history/history_screen_v2_test.dart         (sin clasificar)
 1  test/ui/features/auth/login_screen_test.dart                 (golden)
```

> Reproducir con `--update-goldens` regeneraría las imágenes en esta máquina y
> resolvería los 45 golden; los otros 12 son setup/harness genuinos (timezone,
> GoRouter, timeouts, layout) que sí valdría la pena arreglar en una limpieza.
