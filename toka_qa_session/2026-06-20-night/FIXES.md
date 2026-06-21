# Reanálisis, fixes y re-test — Noche 2026-06-20/21

Cada bug detectado en la QA se reanalizó leyendo el código (causa raíz) para descartar falsos positivos. Los reales se arreglaron, se recompiló el APK (Flutter Windows 3.44.2) y se reinstaló en MI_9 + emulador para re-probar.

## Resultado por bug

| # | Bug | Veredicto | Fix | Re-test |
|---|-----|-----------|-----|---------|
| 1 | Tareas Puntual (oneTime) no se renderizan en Hoy | **REAL** | `RecurrenceOrder.all` no incluía `'oneTime'` (el bucle de Hoy itera esa lista). Añadido `'oneTime'` (primero) + título `recurrenceOneTime` ("Puntual"/"One-off"/"Unic") | ✅ Aparece grupo "Puntual" con Hecho/Pasar; completada end-to-end → `completedOneTime` |
| 2 | Tras expulsar/abandonar, hogar free queda "3/3" y no deja invitar | **REAL** | `members_view_model` usaba `dashboard.planCounters.activeMembers` (stale). Cambiado a `activeMembers.length` (conteo en vivo que ya tenía cargado) | ✅ Expulsar Tres → banner de límite desaparece + botón "Invitar" aparece (2/3); reincorporar ya no se bloquea |
| 3 | "Tu Premium vence en 1 días" (plural) | **REAL** | `subscription_rescue_warning` sin ICU plural. Añadido `{days, plural, one{…} other{…}}` en es/en/ro | ✅ Con 1 día muestra "1 **día**"; con 0 "0 días" |
| 4 | Botón "🧪 DEBUG premium" visible en owner (también release) | **REAL** | `showDebugPremiumToggle: isOwner` → `isOwner && kDebugMode` (+ import explícito de foundation: el analyzer aceptaba `kDebugMode` pero el CFE no) | ✅ En build debug se muestra (esperado); en release queda oculto (gate por código) |
| 5 | Nombre del hogar solo guarda con Enter; se pierde al volver atrás | **REAL** | Añadido `FocusNode` + guardado al perder foco (`_persistNameIfChanged`); `onSubmitted` también actualiza el baseline | ✅ Editar + pulsar "Atrás" sin Enter → persiste en Firestore |
| 6 | Cuenta borrada aparece en "Antiguos miembros" (UID crudo + "Reincorporar" inválido) | **REAL** | `Member.accountDeleted` (nuevo campo) + filtro `leftMembers.where(!accountDeleted)` | ✅ La cuenta borrada ya no aparece en "Antiguos miembros" |
| 7 | Sin indicador de vacaciones en la lista de miembros | **REAL** | `Member.vacationActive` (nuevo campo, de `vacation.isActive`) + badge "🏖️ De vacaciones" en `MemberCard` | ✅ Miembro de vacaciones muestra el badge en la lista |
| 8 | "Hecho" deshabilitado sin feedback al tocarlo | **FALSO POSITIVO** | El código ya tiene `_handleDoneNotReady` → SnackBar `today_hecho_not_yet`. La QA original capturó entre el tap y el SnackBar transitorio | ✅ Con captura inmediata: "El botón 'Hecho' estará activo el lun 22 jun" |
| 11/12 | Banner/checkbox solapan el formulario Crear tarea | **PROBABLE FALSO POSITIVO** | El formulario ya reserva padding inferior vía `AdAwareScaffold.bottomPaddingOf` + shell `extendBody`. El "solape" es scroll normal detrás del banner fijo; el contenido es accesible | (no se tocó código; verificado por análisis) |

## Ficheros modificados
- `lib/features/tasks/domain/recurrence_order.dart` (#1)
- `lib/l10n/app_es.arb`, `app_en.arb`, `app_ro.arb` (#1 recurrenceOneTime, #3 plural, #7 members_on_vacation)
- `lib/features/members/application/members_view_model.dart` (#2 conteo en vivo, #6 filtro accountDeleted)
- `lib/features/homes/application/home_settings_view_model.dart` (#4 kDebugMode + import foundation)
- `lib/features/homes/presentation/skins/home_settings_screen_v2.dart` (#5 guardado al perder foco)
- `lib/features/members/domain/member.dart` + `data/member_model.dart` (#6/#7 campos accountDeleted, vacationActive) → build_runner
- `lib/features/members/presentation/widgets/member_card.dart` (#7 badge)

## Regresión (build nuevo, ambos dispositivos)
Sin crashes ni errores. Verificado: Hoy (Puntual/Día/Semana/Mes), completar tarea normal (Limpiar cocina → +1 día), pasar turno, Tareas, Historial, Miembros (badge vacaciones, sin cuenta borrada), Ajustes/Suscripción/Ajustes del hogar, expulsar/reincorporar, i18n.
`flutter analyze`: 0 errores (42 lints info pre-existentes). APK debug construido e instalado en MI_9 + emulador.

## Hallazgo NUEVO (detectado y ARREGLADO en el re-test)
- 🟡 **Icono custom mostraba el codepoint como texto** → **ARREGLADO Y VERIFICADO**.
  - **Causa raíz**: varios sitios componían el título como `'${task.visualValue} ${task.title}'`, concatenando el codepoint crudo ("57622") en vez de usar `taskVisualWidget` (que sí renderiza `Icon(IconData(cp))`).
  - **Fix** (4 sitios, todos pasados a `taskVisualWidget` + `Row`): `today_task_card_done.dart` (Hechas), `complete_task_dialog.dart` (diálogo confirmación), `all_tasks_screen_v2.dart` (mostraba `Icons.task_alt` genérico para iconos), y `today_task_card_todo.dart` (tarjeta V1).
  - **Re-test** (build nuevo): la lista de **Hechas** muestra el icono de llave (no "57622"); el **diálogo de confirmación** muestra la llave + título; flujo end-to-end de tarea con icono custom OK.
  - Segundo build/install/re-test realizado; `flutter analyze` 0 errores.

## Notas
- Los fixes son TODOS client-side → testeables reinstalando el APK, sin tocar producción.
- El fix #2 resuelve el impacto de usuario del cluster de contadores SIN deploy de Cloud Functions. La regeneración server-side de `planCounters` en `leaveHome`/`removeMember`/`reinstateMember` (llamar `updateHomeDashboard`) sigue siendo recomendable para otros consumidores del dashboard, pero requiere deploy a prod (autorización explícita) → NO realizado.
- Cambios SIN commitear (a revisión).
