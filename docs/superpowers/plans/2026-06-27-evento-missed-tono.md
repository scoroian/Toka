# Hallazgo #08 — Evento "missed" con tono cooperativo (Enfoque A) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reencuadrar el evento `missed` del feed/detalle de historial para que hable del estado de la tarea ("Tarea vencida"), sin nombre, sin avatar de persona y sin color de alarma — eliminando el señalamiento personal.

**Architecture:** Cambio **solo de cliente Flutter + ARB**. El backend (`process_expired_tasks`) sigue creando el evento igual (`eventType:"missed"`, `penaltyApplied:true`, baja `complianceRate`); no se toca. Se reescribe el copy ARB `history_event_missed` (se le quita el placeholder `{name}`), se regeneran las localizaciones y se ajustan dos call sites; luego se despersonaliza el `_MissedTile` (leading neutro + color sin alarma) con golden nuevo.

**Tech Stack:** Flutter/Dart, Riverpod, `flutter_localizations`/intl ARB, `flutter_test` (widget + golden).

## Global Constraints

- **Spec de referencia:** `docs/superpowers/specs/2026-06-27-evento-missed-tono-design.md`. Enfoque **A** (encuadre neutro); Enfoque B descartado.
- **NO se toca backend** (`functions/`) ni `firestore.rules` ni el modelo `TaskEvent`. La penalización estadística se mantiene tal cual.
- **Nada de texto UI hardcodeado:** todo copy va en `lib/l10n/app_es.arb` / `app_en.arb` / `app_ro.arb` y se accede con `l10n.clave`. Regenerar localizaciones tras editar ARB: `flutter gen-l10n`.
- **Pantallas reales = `*_v2.dart`** (los archivos sin sufijo son wrappers `SkinSwitch`). Editar las V2.
- **Convención del lote: el árbol se deja SIN commitear** (como el #07). Los "checkpoints" de cada tarea son los gates verdes, no un commit. No commitear salvo que el usuario lo autorice.
- **Tests en WSL en foreground y acotados** a los archivos del cambio (lanzar `flutter test` en background no escribe salida). Si antes se hizo `flutter build`/`pub get` en Windows, restaurar con `flutter pub get` en WSL antes de testear.
- **Gates antes de cerrar:** `flutter analyze` sin errores en los archivos tocados + tests nuevos/afectados verdes. Documentar los ~fallos golden ambientales por `google_fonts` sin red (ajenos al hallazgo).
- **Copy exacto (es / en / ro):** `history_event_missed` = **"Tarea vencida"** / **"Task overdue"** / **"Sarcină expirată"** (sin placeholder).

---

### Task 1: Copy neutro — ARB + regeneración + call sites (tile y detalle)

Reescribe `history_event_missed` sin placeholder en los tres ARB, regenera las localizaciones y ajusta los dos call sites para que la app compile y el copy sea neutro y sin nombre.

**Files:**
- Modify: `lib/l10n/app_es.arb:1125-1127`
- Modify: `lib/l10n/app_en.arb:1119-1121`
- Modify: `lib/l10n/app_ro.arb:1119-1121`
- Modify: `lib/features/history/presentation/widgets/history_event_tile.dart:269` (título del `_MissedTile`)
- Modify: `lib/features/history/presentation/skins/history_event_detail_screen_v2.dart:128` (resumen del `missed`)
- Generated (regenerar, no editar a mano): `lib/l10n/app_localizations.dart`, `app_localizations_es.dart`, `app_localizations_en.dart`, `app_localizations_ro.dart`
- Test: `test/ui/features/history/history_event_tile_resolved_test.dart` (reescribir el caso `missed`)
- Test: `test/ui/features/history/history_event_detail_screen_test.dart` (añadir caso `missed`)

**Interfaces:**
- Consumes: `AppLocalizations` (delegates ya cableados en los harness de test).
- Produces: getter `String get history_event_missed` (sin parámetros) en `AppLocalizations`. Las Tasks posteriores asumen este getter sin argumentos.

- [ ] **Step 1: Reescribir el test del tile `missed` para esperar el copy neutro (rojo)**

En `test/ui/features/history/history_event_tile_resolved_test.dart`, **reemplazar** el test existente `'MissedEvent muestra alias, no UID'` (líneas 80-88) por:

```dart
    testWidgets('MissedEvent: copy neutro centrado en la tarea, sin nombre',
        (tester) async {
      await tester.pumpWidget(_wrap(HistoryEventTile(
        event: missed,
        actorName: 'Ana',
        actorPhotoUrl: null,
      )));
      // Encuadre neutro: estado de la tarea, no de la persona.
      expect(find.text('Tarea vencida'), findsOneWidget);
      // Ya no señala a nadie por nombre, ni expone el UID.
      expect(find.textContaining('Ana'), findsNothing);
      expect(find.textContaining('uid_actor'), findsNothing);
      // La tarea sigue identificándose en el subtítulo.
      expect(find.textContaining('Aspirar'), findsOneWidget);
    });
```

- [ ] **Step 2: Añadir el caso `missed` al test del detalle (rojo)**

En `test/ui/features/history/history_event_detail_screen_test.dart`, añadir dentro de `void main()` (tras el `group` existente) un nuevo grupo. Reutiliza el helper `_wrap`, `_FakeAuth`, `_user`, `_member` ya definidos en el archivo:

```dart
  group('HistoryEventDetailScreenV2 — evento missed (tono neutro)', () {
    final missedEvent = TaskEvent.missed(
      id: 'e9',
      taskId: 't9',
      taskTitleSnapshot: 'Aspirar',
      taskVisualSnapshot: const TaskVisual(kind: 'emoji', value: '🧹'),
      actorUid: 'uid_performer',
      toUid: 'uid_third',
      penaltyApplied: true,
      missedAt: DateTime(2026, 4, 20, 12),
      createdAt: DateTime(2026, 4, 20, 12),
    );

    testWidgets('el resumen muestra copy neutro sin nombre del responsable',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const HistoryEventDetailScreenV2(homeId: 'home1', eventId: 'e1'),
        [
          authProvider.overrideWith(
              () => _FakeAuth(AuthState.authenticated(_user('uid_third')))),
          homeMembersProvider('home1').overrideWith((ref) => Stream.value([
                _member('uid_performer', 'Luis', MemberRole.member),
                _member('uid_third', 'Pepe', MemberRole.admin),
              ])),
          historyEventDetailProvider(homeId: 'home1', eventId: 'e1')
              .overrideWith((ref) => Stream.value(HistoryEventDetail(
                    event: missedEvent,
                    reviews: const [],
                  ))),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Tarea vencida'), findsOneWidget);
      expect(find.textContaining('Luis'), findsNothing);
    });
  });
```

- [ ] **Step 3: Ejecutar los tests y verificar que fallan**

Run: `flutter test test/ui/features/history/history_event_tile_resolved_test.dart test/ui/features/history/history_event_detail_screen_test.dart`
Expected: FAIL — el tile aún renderiza "Ana no completó" (`'Tarea vencida'` no encontrado; `'Ana'` encontrado) y el detalle aún muestra "Luis no completó".

- [ ] **Step 4: Reescribir el copy ARB (es) sin placeholder**

En `lib/l10n/app_es.arb` reemplazar:

```json
  "history_event_missed": "{name} no completó",
  "@history_event_missed": {
    "placeholders": { "name": { "type": "String" } }
  },
```

por:

```json
  "history_event_missed": "Tarea vencida",
  "@history_event_missed": {
    "description": "Etiqueta neutra, centrada en la tarea, para un evento de tarea vencida (missed). Sin nombrar a la persona (Hallazgo #08, tono cooperativo)."
  },
```

- [ ] **Step 5: Reescribir el copy ARB (en) sin placeholder**

En `lib/l10n/app_en.arb` reemplazar:

```json
  "history_event_missed": "{name} didn't complete",
  "@history_event_missed": {
    "placeholders": { "name": { "type": "String" } }
  },
```

por:

```json
  "history_event_missed": "Task overdue",
  "@history_event_missed": {
    "description": "Neutral, task-centric label for an overdue (missed) task event. No person named (finding #08, cooperative tone)."
  },
```

- [ ] **Step 6: Reescribir el copy ARB (ro) sin placeholder**

En `lib/l10n/app_ro.arb` reemplazar:

```json
  "history_event_missed": "{name} nu a finalizat",
  "@history_event_missed": {
    "placeholders": { "name": { "type": "String" } }
  },
```

por:

```json
  "history_event_missed": "Sarcină expirată",
  "@history_event_missed": {
    "description": "Etichetă neutră, axată pe sarcină, pentru un eveniment de sarcină expirată (missed). Fără a numi persoana (constatarea #08, ton cooperativ)."
  },
```

- [ ] **Step 7: Regenerar las localizaciones**

Run: `flutter gen-l10n`
Expected: actualiza `lib/l10n/app_localizations*.dart`; `AppLocalizations.history_event_missed` pasa de método `(String name)` a getter `String get history_event_missed`. Sin errores.

- [ ] **Step 8: Ajustar el call site del tile**

En `lib/features/history/presentation/widgets/history_event_tile.dart:269` reemplazar:

```dart
      title: Text(l10n.history_event_missed(actorName)),
```

por:

```dart
      title: Text(l10n.history_event_missed),
```

- [ ] **Step 9: Ajustar el call site del detalle**

En `lib/features/history/presentation/skins/history_event_detail_screen_v2.dart:128` reemplazar:

```dart
      MissedEvent e => l10n.history_event_missed(_name(e.actorUid)),
```

por (el binding `e` deja de usarse → usar `_` para evitar lint de variable sin usar):

```dart
      MissedEvent _ => l10n.history_event_missed,
```

- [ ] **Step 10: Ejecutar los tests y verificar que pasan**

Run: `flutter test test/ui/features/history/history_event_tile_resolved_test.dart test/ui/features/history/history_event_detail_screen_test.dart`
Expected: PASS (ambos archivos).

- [ ] **Step 11: Analyze de los archivos tocados**

Run: `flutter analyze lib/features/history/presentation/widgets/history_event_tile.dart lib/features/history/presentation/skins/history_event_detail_screen_v2.dart`
Expected: No issues found (en estos archivos).

---

### Task 2: Despersonalizar el `_MissedTile` (leading neutro + sin alarma) + golden

Sustituye el avatar de la persona por un icono neutro, quita el color de alarma naranja y deja `_MissedTile` sin los parámetros de identidad ya no usados. Añade un golden del tile reencuadrado.

**Files:**
- Modify: `lib/features/history/presentation/widgets/history_event_tile.dart` (`HistoryEventTile.build` rama `missed:` líneas 78-85; clase `_MissedTile` líneas 243-284)
- Test: `test/ui/features/history/history_event_tile_resolved_test.dart` (nuevo caso + golden)
- Create: `test/ui/features/history/goldens/history_event_tile_missed.png` (generado con `--update-goldens`)

**Interfaces:**
- Consumes: getter `l10n.history_event_missed` (Task 1) y `ColorScheme` del tema.
- Produces: `_MissedTile` ya **no** declara `actorName` ni `actorPhotoUrl`. Ningún otro consumidor depende de esos campos (eran privados al archivo).

- [ ] **Step 1: Escribir el test de despersonalización + sin alarma (rojo)**

En `test/ui/features/history/history_event_tile_resolved_test.dart`, dentro del `group('HistoryEventTile — render sin UIDs crudos', ...)`, añadir:

```dart
    testWidgets('MissedEvent: leading neutro (sin avatar de persona) y sin alarma',
        (tester) async {
      await tester.pumpWidget(_wrap(HistoryEventTile(
        event: missed,
        actorName: 'Ana',
        actorPhotoUrl: null,
      )));

      // No hay avatar de persona: no aparece su inicial 'A'.
      expect(find.text('A'), findsNothing);
      // Leading despersonalizado: icono neutro centrado en la tarea.
      expect(find.byIcon(Icons.event_busy_outlined), findsOneWidget);
      // Ningún icono usa color de alarma naranja.
      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      expect(icons.any((i) => i.color == Colors.orange), isFalse);
    });
```

- [ ] **Step 2: Ejecutar el test y verificar que falla**

Run: `flutter test test/ui/features/history/history_event_tile_resolved_test.dart -p vm`
Expected: FAIL — hoy el leading es el avatar (muestra 'A') y el trailing usa `Colors.orange`; `Icons.event_busy_outlined` no existe aún en el tile.

- [ ] **Step 3: Dejar de pasar la identidad al `_MissedTile`**

En `lib/features/history/presentation/widgets/history_event_tile.dart`, en `HistoryEventTile.build`, reemplazar la rama `missed:` (líneas 78-85):

```dart
      missed: (e) => _MissedTile(
        event: e,
        actorName: actorName,
        actorPhotoUrl: actorPhotoUrl,
        timestamp: _formatRelativeTime(l10n, e.missedAt, locale),
        l10n: l10n,
        trailingOverride: trailing,
      ),
```

por:

```dart
      missed: (e) => _MissedTile(
        event: e,
        timestamp: _formatRelativeTime(l10n, e.missedAt, locale),
        l10n: l10n,
        trailingOverride: trailing,
      ),
```

- [ ] **Step 4: Despersonalizar el cuerpo de `_MissedTile`**

En el mismo archivo, reemplazar la clase `_MissedTile` completa (líneas 243-284) por:

```dart
class _MissedTile extends StatelessWidget {
  const _MissedTile({
    required this.event,
    required this.timestamp,
    required this.l10n,
    this.trailingOverride,
  });
  final MissedEvent event;
  final String timestamp;
  final AppLocalizations l10n;
  final Widget? trailingOverride;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final visual = event.taskVisualSnapshot;
    final taskLabel = visual.kind == 'emoji'
        ? '${visual.value} ${event.taskTitleSnapshot}'
        : event.taskTitleSnapshot;

    return ListTile(
      key: Key('history_tile_${event.id}'),
      // Encuadre neutro (Hallazgo #08): el evento habla del estado de la tarea,
      // no de la persona. Sin avatar de miembro: icono neutro centrado en la tarea.
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: cs.surfaceContainerHighest,
        child: Icon(Icons.event_busy_outlined, color: cs.onSurfaceVariant),
      ),
      title: Text(l10n.history_event_missed),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(taskLabel, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(timestamp,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      trailing: _wrapTrailing(
        trailingOverride ??
            Icon(Icons.timer_off_outlined, color: cs.onSurfaceVariant),
      ),
      isThreeLine: true,
    );
  }
}
```

> Nota: si `flutter analyze` reportara que `Icons.event_busy_outlined` no existe en la versión del SDK, usar `Icons.event_busy` (variante rellena) y actualizar la aserción del Step 1 en consecuencia.

- [ ] **Step 5: Ejecutar el test y verificar que pasa**

Run: `flutter test test/ui/features/history/history_event_tile_resolved_test.dart -p vm`
Expected: PASS (incluye el caso de copy de la Task 1 y el nuevo de despersonalización).

- [ ] **Step 6: Añadir el test de golden del tile `missed`**

En `test/ui/features/history/history_event_tile_resolved_test.dart`, al final de `void main()` (fuera del grupo anterior), añadir:

```dart
  group('HistoryEventTile — golden tile missed', () {
    final missedGolden = TaskEvent.missed(
      id: 'g1',
      taskId: 't1',
      taskTitleSnapshot: 'Aspirar',
      taskVisualSnapshot: const TaskVisual(kind: 'emoji', value: '🧹'),
      actorUid: 'uid_actor',
      toUid: 'uid_other',
      penaltyApplied: true,
      missedAt: DateTime(2026, 4, 20, 12),
      createdAt: DateTime(2026, 4, 20, 12),
    );

    testWidgets('golden: evento vencido reencuadrado (neutro, sin nombre)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 360);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(HistoryEventTile(
        event: missedGolden,
        actorName: 'Ana',
        actorPhotoUrl: null,
      )));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/history_event_tile_missed.png'),
      );
    });
  });
```

- [ ] **Step 7: Generar el golden**

Run: `flutter test --update-goldens test/ui/features/history/history_event_tile_resolved_test.dart`
Expected: crea `test/ui/features/history/goldens/history_event_tile_missed.png`. Inspeccionar visualmente el PNG: título "Tarea vencida", icono neutro a la izquierda, sin avatar de persona, sin naranja.

- [ ] **Step 8: Verificar el golden y la suite del archivo en verde**

Run: `flutter test test/ui/features/history/history_event_tile_resolved_test.dart`
Expected: PASS (todos los casos + golden).

- [ ] **Step 9: Gates finales del cambio**

Run: `flutter analyze lib/features/history/presentation/widgets/history_event_tile.dart`
Expected: No issues found.

Run: `flutter test test/ui/features/history/`
Expected: PASS (documentar cualquier fallo golden ambiental por `google_fonts` sin red como ajeno).

---

## Self-Review

**1. Cobertura del spec:**
- Encuadre neutro del feed (sin acusación personal) → Task 1 (copy) + Task 2 (leading/color). ✓
- Detalle sin nombre del responsable → Task 1 Step 2/9. ✓
- Penalización no exhibida como etiqueta pública → satisfecho por construcción (el feed/detalle no muestran número; copy neutro). ✓
- Localizado es/en/ro → Task 1 Steps 4-6. ✓
- Backend sin tocar (jest N/A) → Global Constraints + spec. ✓
- Verificación en 2 dispositivos → fuera del plan de código; se ejecuta en el cierre del hallazgo según `_CONVENCIONES.md` §7. ✓

**2. Placeholders:** Sin "TBD"/"TODO"; todos los pasos llevan código/comando concreto. La única condicionalidad (icono fallback) es una nota de robustez, no un hueco.

**3. Consistencia de tipos:** `history_event_missed` se redefine como getter sin args en Task 1 y se consume sin args en Tasks 1-2. `_MissedTile` pierde `actorName`/`actorPhotoUrl` en Task 2 y su call site se actualiza en el mismo Step 3. Consistente.
