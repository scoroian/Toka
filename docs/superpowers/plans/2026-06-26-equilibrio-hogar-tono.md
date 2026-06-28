# Equilibrio del hogar — reencuadre cooperativo (Hallazgo #07) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reformular la tarjeta "Equilibrio del hogar" para que hable del hogar en conjunto y oriente a repartir, sin señalar a ningún miembro por nombre ni usar color de alarma.

**Architecture:** Cambio solo de cliente Flutter en un único widget privado (`_BalanceCardV2` en `members_screen_v2.dart`) más las tres ARB. Se elimina la lógica nominal (`_topDelta`), se sustituye el copy por dos claves cooperativas sin placeholder, se cambia el color de alerta por neutro/informativo y se añade un CTA que navega a la pestaña Tareas con `context.go(AppRoutes.tasks)`. Sin backend, sin nuevos providers, sin cambios de datos.

**Tech Stack:** Flutter 3.x, Riverpod, go_router, flutter_localizations + ARB, flutter_test (widget + golden).

## Global Constraints

- **Nada de texto UI hardcodeado.** Toda string visible va en `lib/l10n/app_es.arb`, `app_en.arb`, `app_ro.arb` y se accede con `l10n.clave`. Regenerar localizaciones tras editar ARB.
- **Editar la pantalla V2.** La pantalla real es `members_screen_v2.dart`; el archivo sin sufijo es un wrapper `SkinSwitch`.
- **Navegación entre pestañas del shell = `context.go(...)`** (no `push`), como en `main_shell_v2.dart:284`.
- **Color sin alarma:** prohibido `cs.tertiary` en esta tarjeta. Estado positivo → `cs.primary`; estado desigual → neutro (`cs.onSurfaceVariant` / `cs.secondary`).
- **Gates antes de cerrar:** `flutter analyze` sin errores; `flutter test test/unit/` + tests nuevos verdes (hay ~6 fallos golden preexistentes ambientales por `google_fonts` sin red — ajenos, documentarlos).
- **Tests con `mocktail`**, nunca `mockito`.

---

### Task 1: Reencuadre de `_BalanceCardV2` (lógica + copy + color + CTA)

Unidad cohesiva: el código del widget referencia la clave ARB que se elimina, así que ARB y widget deben cambiar juntos para que compile. Un solo commit.

**Files:**
- Modify: `lib/l10n/app_es.arb` (bloque `members_balance_unbalanced`, ~líneas 461-465)
- Modify: `lib/l10n/app_en.arb` (mismo bloque)
- Modify: `lib/l10n/app_ro.arb` (mismo bloque)
- Modify: `lib/features/members/presentation/skins/members_screen_v2.dart:312-414` (`_BalanceCardV2`)
- Test: `test/ui/features/members/members_balance_card_test.dart` (nuevo)

**Interfaces:**
- Consumes: `Member.complianceRate` (double 0..1), `Member.nickname` (String), `Member.tasksCompleted` (int); `AppRoutes.tasks` (`'/tasks'`); `l10n.members_balance_title`, `l10n.members_balance_well_distributed`.
- Produces (claves ARB nuevas, consumidas en Task 2 goldens y device): `l10n.members_balance_uneven` (String, sin placeholder), `l10n.members_balance_share_cta` (String). CTA con `Key('btn_balance_share')` que ejecuta `context.go(AppRoutes.tasks)`. Se **elimina** `l10n.members_balance_unbalanced`.

- [ ] **Step 1: Escribir los widget tests (fallan)**

Crear `test/ui/features/members/members_balance_card_test.dart`. Reutiliza el harness del test existente (`members_screen_test.dart`) pero añade un GoRouter de prueba para verificar la navegación del CTA.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:toka/core/constants/routes.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/application/homes_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/members/application/members_provider.dart';
import 'package:toka/features/members/domain/member.dart';
import 'package:toka/features/members/presentation/skins/members_screen_v2.dart';
import 'package:toka/l10n/app_localizations.dart';

const _ownerUser = AuthUser(
  uid: 'uid-owner',
  email: 'owner@test.com',
  displayName: 'Owner',
  photoUrl: null,
  emailVerified: true,
  providers: [],
);

final _fakeHome = Home(
  id: 'home1',
  name: 'Casa Test',
  ownerUid: 'uid-owner',
  currentPayerUid: null,
  lastPayerUid: null,
  premiumStatus: HomePremiumStatus.free,
  premiumPlan: null,
  premiumEndsAt: null,
  restoreUntil: null,
  autoRenewEnabled: false,
  limits: const HomeLimits(maxMembers: 3),
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);

final _ownerMembership = HomeMembership(
  homeId: 'home1',
  homeNameSnapshot: 'Casa Test',
  role: MemberRole.owner,
  billingState: BillingState.currentPayer,
  status: MemberStatus.active,
  joinedAt: DateTime(2026, 1, 1),
);

Member _member({
  required String uid,
  required String nickname,
  required int tasksCompleted,
  required double complianceRate,
  MemberRole role = MemberRole.member,
}) =>
    Member(
      uid: uid,
      homeId: 'home1',
      nickname: nickname,
      photoUrl: null,
      bio: null,
      phone: null,
      phoneVisibility: 'hidden',
      role: role,
      status: MemberStatus.active,
      joinedAt: DateTime(2026, 1, 1),
      tasksCompleted: tasksCompleted,
      passedCount: 0,
      complianceRate: complianceRate,
      currentStreak: 0,
      averageScore: 8.0,
    );

// Desequilibrio real: balance promedio < 75 % y reparto dispar.
// 'Zoraida' es el "top" por tareas — el código viejo habría escrito "Zoraida +N".
final _unevenMembers = [
  _member(uid: 'uid-owner', nickname: 'Zoraida', tasksCompleted: 20, complianceRate: 0.55, role: MemberRole.owner),
  _member(uid: 'uid-2', nickname: 'Bruno', tasksCompleted: 2, complianceRate: 0.40),
];

final _balancedMembers = [
  _member(uid: 'uid-owner', nickname: 'Zoraida', tasksCompleted: 12, complianceRate: 0.92, role: MemberRole.owner),
  _member(uid: 'uid-2', nickname: 'Bruno', tasksCompleted: 11, complianceRate: 0.88),
];

final _soloMember = [
  _member(uid: 'uid-owner', nickname: 'Zoraida', tasksCompleted: 3, complianceRate: 0.30, role: MemberRole.owner),
];

class _FakeAuth extends Auth {
  final AuthState _state;
  _FakeAuth(this._state);
  @override
  AuthState build() => _state;
}

class _FakeCurrentHome extends CurrentHome {
  @override
  Future<Home?> build() async => _fakeHome;
}

List<Override> _overrides(List<Member> members) => [
      authProvider.overrideWith(
          () => _FakeAuth(const AuthState.authenticated(_ownerUser))),
      currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
      userMembershipsProvider('uid-owner')
          .overrideWith((ref) => Stream.value([_ownerMembership])),
      homeMembersProvider('home1')
          .overrideWith((ref) => Stream.value(members)),
    ];

Widget _wrap(List<Member> members) {
  final router = GoRouter(
    initialLocation: AppRoutes.members,
    routes: [
      GoRoute(
        path: AppRoutes.members,
        builder: (_, __) => const MembersScreenV2(),
      ),
      GoRoute(
        path: AppRoutes.tasks,
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('TASKS_PAGE'))),
      ),
    ],
  );
  return ProviderScope(
    overrides: _overrides(members),
    child: MaterialApp.router(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      routerConfig: router,
    ),
  );
}

void main() {
  group('Balance card — reencuadre cooperativo (#07)', () {
    testWidgets('reparto desigual: copy cooperativo y CTA, sin nombre ni +N',
        (tester) async {
      await tester.pumpWidget(_wrap(_unevenMembers));
      await tester.pumpAndSettle();

      // Copy neutro nuevo + CTA presentes.
      expect(find.text('El reparto está algo desigual.'), findsOneWidget);
      expect(find.byKey(const Key('btn_balance_share')), findsOneWidget);
      expect(find.text('Repartir las tareas'), findsOneWidget);

      // Sin señalamiento: ni "+N" ni el copy viejo.
      expect(find.textContaining('Zoraida +'), findsNothing);
      expect(find.textContaining('+2'), findsNothing);
      expect(find.textContaining('Desequilibrado'), findsNothing);
    });

    testWidgets('CTA navega a la pestaña Tareas', (tester) async {
      await tester.pumpWidget(_wrap(_unevenMembers));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_balance_share')));
      await tester.pumpAndSettle();

      expect(find.text('TASKS_PAGE'), findsOneWidget);
    });

    testWidgets('reparto equilibrado: "Bien repartido", sin CTA',
        (tester) async {
      await tester.pumpWidget(_wrap(_balancedMembers));
      await tester.pumpAndSettle();

      expect(find.text('Bien repartido'), findsOneWidget);
      expect(find.byKey(const Key('btn_balance_share')), findsNothing);
      expect(find.text('El reparto está algo desigual.'), findsNothing);
    });

    testWidgets('un solo miembro: nunca "desigual" ni CTA', (tester) async {
      await tester.pumpWidget(_wrap(_soloMember));
      await tester.pumpAndSettle();

      // Con 1 miembro no hay reparto que equilibrar → estado positivo, sin CTA.
      expect(find.byKey(const Key('btn_balance_share')), findsNothing);
      expect(find.text('El reparto está algo desigual.'), findsNothing);
      expect(find.text('Bien repartido'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Ejecutar los tests para verlos fallar**

Run: `flutter test test/ui/features/members/members_balance_card_test.dart`
Expected: FAIL — la clave `members_balance_uneven` no existe aún (error de compilación: `members_balance_uneven isn't defined`) y/o no se encuentra el copy/CTA.

- [ ] **Step 3: Editar los ARB (es/en/ro): sustituir la clave nominal por dos cooperativas**

En `lib/l10n/app_es.arb`, reemplazar el bloque:

```json
  "members_balance_unbalanced": "Desequilibrado · {topName}",
  "@members_balance_unbalanced": {
    "description": "Message when one member has done many more tasks than the rest",
    "placeholders": { "topName": { "type": "String" } }
  },
```

por:

```json
  "members_balance_uneven": "El reparto está algo desigual.",
  "@members_balance_uneven": { "description": "Cooperative message when chores are unevenly shared; never names a member" },
  "members_balance_share_cta": "Repartir las tareas",
  "@members_balance_share_cta": { "description": "Button that opens the Tasks tab to rebalance chores" },
```

En `lib/l10n/app_en.arb`, reemplazar el bloque equivalente (`"members_balance_unbalanced": "Unbalanced · {topName}",` + su `@`-metadata con placeholder `topName`) por:

```json
  "members_balance_uneven": "Chores are a bit uneven right now.",
  "@members_balance_uneven": { "description": "Cooperative message when chores are unevenly shared; never names a member" },
  "members_balance_share_cta": "Share out the tasks",
  "@members_balance_share_cta": { "description": "Button that opens the Tasks tab to rebalance chores" },
```

En `lib/l10n/app_ro.arb`, reemplazar el bloque equivalente (`"members_balance_unbalanced": "Dezechilibrat · {topName}",` + su `@`-metadata con placeholder `topName`) por:

```json
  "members_balance_uneven": "Sarcinile sunt cam inegale acum.",
  "@members_balance_uneven": { "description": "Cooperative message when chores are unevenly shared; never names a member" },
  "members_balance_share_cta": "Repartizează sarcinile",
  "@members_balance_share_cta": { "description": "Button that opens the Tasks tab to rebalance chores" },
```

> Nota: en `app_en.arb` y `app_ro.arb` la clave `members_balance_unbalanced` ocupa la línea de valor seguida del bloque `@` en líneas siguientes (ver `:457`/`:457`). Borrar **ambas** (valor + `@`-metadata). No debe quedar ninguna referencia a `members_balance_unbalanced` en el repo.

- [ ] **Step 4: Regenerar las localizaciones**

Run: `flutter gen-l10n`
Expected: regenera `lib/l10n/app_localizations*.dart` con `members_balance_uneven` y `members_balance_share_cta`; sin la antigua. Si el proyecto genera l10n vía `flutter test`/`run` automáticamente, igualmente ejecútalo para validar el ARB.

Verifica que no quedan referencias colgando:
Run: `grep -rn "members_balance_unbalanced" lib/ test/`
Expected: sin resultados.

- [ ] **Step 5: Reescribir `_BalanceCardV2`**

Sustituir todo el cuerpo de la clase `_BalanceCardV2` (`members_screen_v2.dart:312-414`) por:

```dart
/// Tarjeta "Equilibrio del hogar".
///
/// Muestra el promedio de `complianceRate` de los miembros activos como un
/// porcentaje con barra. Habla del hogar en conjunto: si el reparto está
/// desigual (≥2 miembros activos y balance < 75 %) sugiere repartir, sin
/// señalar a nadie por nombre ni usar color de alarma.
class _BalanceCardV2 extends StatelessWidget {
  const _BalanceCardV2({required this.activeMembers, required this.l10n});

  final List<Member> activeMembers;
  final AppLocalizations l10n;

  double get _balance {
    if (activeMembers.isEmpty) return 0;
    final sum = activeMembers.fold<double>(
      0,
      (acc, m) => acc + m.complianceRate.clamp(0, 1),
    );
    return (sum / activeMembers.length).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final value = _balance;
    final percent = (value * 100).round();
    // Con un solo miembro activo no hay reparto que equilibrar.
    final isBalanced = activeMembers.length < 2 || percent >= 75;
    // Neutro/informativo en desequilibrio: nunca color de alarma.
    final neutral = cs.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isBalanced ? Icons.balance : Icons.scale_outlined,
                size: 20,
                color: isBalanced ? cs.primary : neutral,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.members_balance_title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isBalanced ? cs.primary : neutral,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: cs.surface,
              valueColor: AlwaysStoppedAnimation(
                isBalanced ? cs.primary : cs.secondary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (isBalanced)
            Text(
              l10n.members_balance_well_distributed,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            )
          else ...[
            Text(
              l10n.members_balance_uneven,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('btn_balance_share'),
                onPressed: () => context.go(AppRoutes.tasks),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: Text(l10n.members_balance_share_cta),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

> `AppRoutes` y `go_router` ya están importados en este archivo (`:3`, y usos en `:129`/`:170`). No añadir imports nuevos.

- [ ] **Step 6: Ejecutar los tests y el analyzer**

Run: `flutter test test/ui/features/members/members_balance_card_test.dart`
Expected: PASS (4 tests).

Run: `flutter test test/ui/features/members/members_screen_test.dart`
Expected: los 3 tests de comportamiento PASAN; el golden `members_screen.png` puede fallar por el nuevo color/altura — se regenera en Task 2 (anótalo, no lo arregles aquí).

Run: `flutter analyze lib/features/members/presentation/skins/members_screen_v2.dart test/ui/features/members/members_balance_card_test.dart`
Expected: sin errores.

- [ ] **Step 7: Commit**

```bash
git add lib/l10n/app_es.arb lib/l10n/app_en.arb lib/l10n/app_ro.arb \
        lib/l10n/app_localizations.dart lib/l10n/app_localizations_es.dart \
        lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_ro.dart \
        lib/features/members/presentation/skins/members_screen_v2.dart \
        test/ui/features/members/members_balance_card_test.dart
git commit -m "feat(h07): equilibrio del hogar cooperativo (sin señalar a nadie)

Reformula _BalanceCardV2: elimina el marcador nominal '{nickname} +N' y el
color de alerta (cs.tertiary). En desequilibrio muestra copy cooperativo
('El reparto está algo desigual.') + CTA 'Repartir las tareas' -> pestaña
Tareas, en tono neutro/informativo. ARB es/en/ro: nuevas claves
members_balance_uneven/_share_cta, retirada members_balance_unbalanced.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Goldens de la tarjeta (equilibrado + desigual)

**Files:**
- Modify: `test/ui/features/members/members_balance_card_test.dart` (añadir grupo de goldens)
- Create (golden): `test/ui/features/members/goldens/members_balance_uneven.png`
- Modify (golden, regen): `test/ui/features/members/goldens/members_screen.png`

**Interfaces:**
- Consumes: el harness `_wrap(...)` y las listas `_unevenMembers`/`_balancedMembers` de Task 1.
- Produces: golden `members_balance_uneven.png` que congela el estado cooperativo (copy neutro + CTA + color informativo).

- [ ] **Step 1: Añadir el golden test del estado desigual**

Añadir al final de `members_balance_card_test.dart`, dentro de `main()`:

```dart
  group('Balance card — golden', () {
    testWidgets('golden: reparto desigual (copy neutro + CTA)',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(_unevenMembers));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/members_balance_uneven.png'),
      );
    });
  });
```

- [ ] **Step 2: Generar los goldens**

Run: `flutter test --update-goldens test/ui/features/members/members_balance_card_test.dart`
Expected: crea `goldens/members_balance_uneven.png`.

Run: `flutter test --update-goldens test/ui/features/members/members_screen_test.dart`
Expected: regenera `goldens/members_screen.png` (cambia por el nuevo color de la barra en el estado balanceado y, si aplica, la altura).

- [ ] **Step 3: Inspección visual del diff**

Abrir `test/ui/features/members/goldens/members_balance_uneven.png` y confirmar a ojo:
- No aparece ningún nombre de miembro ni "+N" en la tarjeta de equilibrio.
- La barra/icono/% del estado desigual NO son naranja/rojo de alarma (tono neutro/secundario).
- El CTA "Repartir las tareas" se ve completo, sin overflow.

Para `members_screen.png`, confirmar que el único cambio es de color/altura de la tarjeta de equilibrio (no regresiones en el resto de la pantalla).

- [ ] **Step 4: Verificar que los goldens pasan sin update**

Run: `flutter test test/ui/features/members/members_balance_card_test.dart test/ui/features/members/members_screen_test.dart`
Expected: PASS. (Si `members_screen.png` falla por `google_fonts` sin red en este entorno, documentarlo como fallo ambiental preexistente, no de este cambio.)

- [ ] **Step 5: Commit**

```bash
git add test/ui/features/members/members_balance_card_test.dart \
        test/ui/features/members/goldens/members_balance_uneven.png \
        test/ui/features/members/goldens/members_screen.png
git commit -m "test(h07): goldens de la tarjeta de equilibrio (desigual + regen pantalla)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Verificación final (manual, fuera de los commits de tareas)

Según `_CONVENCIONES.md` (Firebase real, dos perfiles). No bloquea los commits, pero es requisito de cierre del hallazgo:

1. Build APK debug `main.dart` (Windows). Emulador=Ana (owner) completa varias tareas; MI_9=Beto (member) deja tareas sin hacer → crear desequilibrio real.
2. Abrir **Miembros** en ambos. Capturar la tarjeta: no debe señalar a nadie por nombre ni usar color de alarma; debe verse el copy cooperativo + CTA "Repartir las tareas". Pulsar el CTA → debe abrir la pestaña **Tareas**.
3. Equilibrar el reparto → verificar estado "Bien repartido" (color positivo, sin CTA). Capturar.
4. Capturas a `C:\tmp\h07\`, redimensionadas ≤1900px antes de leerlas con Read.
5. Restaurar entorno (asignaciones, force-stop) y dejar emu=Ana / MI_9=Beto.

## Cierre

- Actualizar `Arreglos/ux_hallazgos_2026-06-25/INDICE.md`: estado **✅ Completado** + fecha + nota (commits, archivos clave, capturas).
- Listar archivos nuevos/modificados y enlazar capturas.
- No marcar DONE si algún gate (analyze/tests/device) no está verde.

---

## Self-Review (hecho)

- **Cobertura del spec:** sin nombre/+N → Task 1 Step 5 (elimina `_topDelta`) + test "sin nombre ni +N"; color no-alarma → Task 1 Step 5 (sin `cs.tertiary`); mensaje cooperativo accionable → copy `members_balance_uneven` + CTA; localizado es/en/ro → Task 1 Step 3; "Bien repartido" positivo → conservado; tests unit/widget/golden → Task 1 + Task 2; verificación 2 dispositivos → sección final. ✓
- **Placeholders:** ninguno; todo el código y comandos son literales. ✓
- **Consistencia de tipos/nombres:** `members_balance_uneven`, `members_balance_share_cta`, `Key('btn_balance_share')`, `AppRoutes.tasks`, `context.go` usados igual en plan, tests e implementación. ✓
