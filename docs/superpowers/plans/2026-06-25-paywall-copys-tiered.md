# Migrar copys binarios del paywall al modelo tiered — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminar las cifras hardcodeadas del modelo binario antiguo (10 miembros, 3,99 €) en las superficies que comparten widgets binarios (paywall binario, pantalla de rescate, tarjeta Free), parametrizándolas por tier.

**Architecture:** `PlanComparisonCard` deja de tener cifras fijas y recibe `int premiumMemberLimit`; cada superficie inyecta el valor correcto (paywall binario → Grupo/10, rescate → tier actual del hogar con fallback Grupo, Free → copy de rango). El precio del paywall binario pasa a leerse de la store (Grupo) con fallback ARB. El paywall **tiered** ya es correcto y no se toca.

**Tech Stack:** Flutter 3.x, Dart 3.x, Riverpod, flutter gen-l10n (ARB es/en/ro), goldens con `matchesGoldenFile`.

## Global Constraints

- Responder e implementar en **español**; todo texto visible va en ARB (es/en/ro), nunca hardcodeado.
- Precios de referencia por tier (fallback ARB, ya existentes): Pareja 2,99/19,99 · Familia 3,99/29,99 · **Grupo 5,99/49,99**.
- El SKU legacy `toka_premium_*` (paywall binario, flag `home_tiers_enabled` OFF) el backend lo mapea a **Grupo (10)** → el "tier por defecto" del binario es Grupo.
- Ahorro anual de Grupo: **21,89 €** (5,99×12 − 49,99).
- `homeTiersEnabled` por defecto es **false** en tests (fail-safe) → los tests de `PaywallScreenV2` ejercen el cuerpo **binario**.
- Mensaje de copy Free aprobado: "De 2 a 10 miembros según el plan".
- `l10n.yaml`: `synthetic-package: false`, template `app_es.arb`. Tras tocar ARB ejecutar `flutter gen-l10n`.
- No tocar el paywall tiered (`_TieredPaywallBody`) ni las tarjetas de tier/packs.
- Convenciones del repo: tests con `mocktail` (no mockito), strings vía `l10n.<clave>`.

---

### Task 1: `RescueViewModel.premiumMemberLimit`

Expone el límite de miembros del tier actual del hogar (fallback Grupo) para que la pantalla de rescate muestre "su tier".

**Files:**
- Modify: `lib/features/subscription/application/rescue_view_model.dart`
- Test: `test/unit/features/subscription/rescue_view_model_test.dart`

**Interfaces:**
- Consumes: `currentHomeTierProvider` (`Provider<HomeTier?>`), `HomeTierX.maxMembers` (Pareja 2 / Familia 5 / Grupo 10).
- Produces: `int RescueViewModel.premiumMemberLimit` — lo consume Task 2 (`RescueScreenV2`).

- [ ] **Step 1: Write the failing test**

Añadir al final de `test/unit/features/subscription/rescue_view_model_test.dart`, dentro de `void main()` (antes del cierre `}`):

```dart
  group('RescueViewModel — premiumMemberLimit (tier del hogar)', () {
    const rescue = SubscriptionState.rescue(
      plan: 'monthly',
      endsAt: null,
      daysLeft: 2,
    );

    test('Pareja → 2 miembros', () {
      final container =
          _makeContainer(subState: rescue, tier: HomeTier.pareja, tiersEnabled: true);
      addTearDown(container.dispose);
      expect(container.read(rescueViewModelProvider).premiumMemberLimit, 2);
    });

    test('Familia → 5 miembros', () {
      final container =
          _makeContainer(subState: rescue, tier: HomeTier.familia, tiersEnabled: true);
      addTearDown(container.dispose);
      expect(container.read(rescueViewModelProvider).premiumMemberLimit, 5);
    });

    test('tier desconocido (null) → fallback Grupo (10)', () {
      final container =
          _makeContainer(subState: rescue, tier: null, tiersEnabled: false);
      addTearDown(container.dispose);
      expect(container.read(rescueViewModelProvider).premiumMemberLimit, 10);
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/features/subscription/rescue_view_model_test.dart`
Expected: FAIL — `premiumMemberLimit` no está definido en `RescueViewModel`.

- [ ] **Step 3: Add the getter to the abstract interface**

En `rescue_view_model.dart`, en `abstract class RescueViewModel`, añadir tras `String get monthlyProductId;`:

```dart
  /// Tope de miembros del tier ACTUAL del hogar (Pareja 2 / Familia 5 / Grupo
  /// 10). Fallback a Grupo (10) si el tier es desconocido — coherente con
  /// `renewalProductId`, que cae al SKU legacy (=Grupo) en ese caso. Lo usa la
  /// pantalla de rescate para mostrar los miembros de "su tier", no "10" fijo.
  int get premiumMemberLimit;
```

- [ ] **Step 4: Implement in the impl class**

En `_RescueViewModelImpl`, añadir el campo y su asignación en el constructor:

```dart
  @override
  final int premiumMemberLimit;
```

Añadir `required this.premiumMemberLimit,` a la lista de parámetros del constructor `const _RescueViewModelImpl({...})` (junto a `required this.monthlyProductId,`).

En el provider `rescueViewModel`, donde ya está `final tier = ref.watch(currentHomeTierProvider);`, añadir a la construcción del `_RescueViewModelImpl(...)`:

```dart
    premiumMemberLimit: (tier ?? HomeTier.grupo).maxMembers,
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/unit/features/subscription/rescue_view_model_test.dart`
Expected: PASS (todos los grupos, incl. los preexistentes).

- [ ] **Step 6: Commit**

```bash
git add lib/features/subscription/application/rescue_view_model.dart test/unit/features/subscription/rescue_view_model_test.dart
git commit -m "feat(paywall-05): RescueViewModel expone premiumMemberLimit del tier del hogar"
```

---

### Task 2: `PlanComparisonCard` parametrizado por `premiumMemberLimit`

La tabla Free-vs-Premium muestra el nº de miembros del tier en vez de "Hasta 10" fijo. Se actualizan sus DOS call sites (paywall binario y rescate) en la misma task para mantener la compilación.

**Files:**
- Modify: `lib/features/subscription/presentation/widgets/plan_comparison_card.dart`
- Modify: `lib/features/subscription/presentation/skins/paywall_screen_v2.dart:103`
- Modify: `lib/features/subscription/presentation/skins/rescue_screen_v2.dart:50`
- Modify: `test/ui/features/subscription/rescue_screen_test.dart`
- Test (nuevo): `test/ui/features/subscription/plan_comparison_card_test.dart`

**Interfaces:**
- Consumes: `RescueViewModel.premiumMemberLimit` (Task 1); `HomeTierX.maxMembers`; `l10n.paywall_tier_members(int)` ("Hasta {count} miembros", ya existe en ARB).
- Produces: `PlanComparisonCard({required int premiumMemberLimit})` — usado por el paywall binario y la pantalla de rescate.

- [ ] **Step 1: Write the failing widget test (nuevo archivo)**

Crear `test/ui/features/subscription/plan_comparison_card_test.dart`:

```dart
// test/ui/features/subscription/plan_comparison_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/subscription/presentation/widgets/plan_comparison_card.dart';
import 'package:toka/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(width: 360, child: child),
        ),
      ),
    );

void main() {
  testWidgets('Pareja: muestra "Hasta 2 miembros"', (t) async {
    await t.pumpWidget(_wrap(const PlanComparisonCard(premiumMemberLimit: 2)));
    await t.pumpAndSettle();
    expect(find.text('Hasta 2 miembros'), findsOneWidget);
    expect(find.text('Hasta 10 miembros por hogar'), findsNothing);
  });

  testWidgets('Familia: muestra "Hasta 5 miembros"', (t) async {
    await t.pumpWidget(_wrap(const PlanComparisonCard(premiumMemberLimit: 5)));
    await t.pumpAndSettle();
    expect(find.text('Hasta 5 miembros'), findsOneWidget);
  });

  testWidgets('Grupo: muestra "Hasta 10 miembros"', (t) async {
    await t.pumpWidget(_wrap(const PlanComparisonCard(premiumMemberLimit: 10)));
    await t.pumpAndSettle();
    expect(find.text('Hasta 10 miembros'), findsOneWidget);
  });

  testWidgets('golden: PlanComparisonCard Pareja (2)', (t) async {
    await t.pumpWidget(_wrap(const PlanComparisonCard(premiumMemberLimit: 2)));
    await t.pumpAndSettle();
    await expectLater(
      find.byKey(const Key('plan_comparison_card')),
      matchesGoldenFile('goldens/plan_comparison_card_2.png'),
    );
  });

  testWidgets('golden: PlanComparisonCard Familia (5)', (t) async {
    await t.pumpWidget(_wrap(const PlanComparisonCard(premiumMemberLimit: 5)));
    await t.pumpAndSettle();
    await expectLater(
      find.byKey(const Key('plan_comparison_card')),
      matchesGoldenFile('goldens/plan_comparison_card_5.png'),
    );
  });

  testWidgets('golden: PlanComparisonCard Grupo (10)', (t) async {
    await t.pumpWidget(_wrap(const PlanComparisonCard(premiumMemberLimit: 10)));
    await t.pumpAndSettle();
    await expectLater(
      find.byKey(const Key('plan_comparison_card')),
      matchesGoldenFile('goldens/plan_comparison_card_10.png'),
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ui/features/subscription/plan_comparison_card_test.dart`
Expected: FAIL — `PlanComparisonCard` no acepta `premiumMemberLimit` (constructor const sin ese parámetro).

- [ ] **Step 3: Parametrize the widget**

En `plan_comparison_card.dart`, cambiar el constructor y la fila de miembros:

```dart
class PlanComparisonCard extends StatelessWidget {
  const PlanComparisonCard({super.key, required this.premiumMemberLimit});

  /// Tope de miembros del tier a comparar contra Free. Cada superficie inyecta
  /// el valor correcto (paywall binario → Grupo/10; rescate → tier del hogar).
  final int premiumMemberLimit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final features = [
      (l10n.paywall_tier_members(premiumMemberLimit), false, true),
      (l10n.paywall_feature_smart, false, true),
      (l10n.paywall_feature_vacations, false, true),
      (l10n.paywall_feature_reviews, false, true),
      (l10n.paywall_feature_history, false, true),
      (l10n.paywall_feature_no_ads, false, true),
    ];
    // ... resto sin cambios
```

- [ ] **Step 4: Update call site — paywall binario**

En `paywall_screen_v2.dart`, dentro de `_BinaryPaywallBody`, cambiar:

```dart
          const PlanComparisonCard(),
```
por:
```dart
          PlanComparisonCard(premiumMemberLimit: HomeTier.grupo.maxMembers),
```

(`HomeTier` ya está importado vía `domain/tier_catalog.dart`, línea 21.)

- [ ] **Step 5: Update call site — pantalla de rescate**

En `rescue_screen_v2.dart`, cambiar:

```dart
            const PlanComparisonCard(),
```
por:
```dart
            PlanComparisonCard(premiumMemberLimit: vm.premiumMemberLimit),
```

(`vm` ya existe: `final vm = ref.watch(rescueViewModelProvider);`.)

- [ ] **Step 6: Add rescate widget test for tier-aware members**

En `test/ui/features/subscription/rescue_screen_test.dart`, añadir dos tests dentro de `void main()` (el harness ya overridea `currentHomeTierProvider` y `homeTiersEnabledProvider`):

```dart
  testWidgets('RescueScreen: tier Pareja → comparación dice "Hasta 2 miembros"',
      (tester) async {
    final overrides = [
      currentHomeProvider.overrideWith(() => _FakeCurrentHome(_rescueHome)),
      subscriptionRepositoryProvider
          .overrideWithValue(_MockSubscriptionRepository()),
      subscriptionStateProvider.overrideWith(
        (_) => const SubscriptionState.rescue(
            plan: 'monthly', endsAt: null, daysLeft: 2),
      ),
      paywallProvider.overrideWith(() => _FakePaywall()),
      currentHomeTierProvider.overrideWithValue(HomeTier.pareja),
      homeTiersEnabledProvider.overrideWithValue(true),
    ];
    await tester.pumpWidget(_wrap(const RescueScreenV2(), overrides: overrides));
    await tester.pumpAndSettle();

    expect(find.text('Hasta 2 miembros'), findsOneWidget);
    expect(find.text('Hasta 10 miembros por hogar'), findsNothing);
  });

  testWidgets('RescueScreen: tier desconocido → fallback "Hasta 10 miembros"',
      (tester) async {
    // baseOverrides usa currentHomeTierProvider=null, homeTiersEnabled=false.
    await tester.pumpWidget(_wrap(const RescueScreenV2(), overrides: baseOverrides));
    await tester.pumpAndSettle();

    expect(find.text('Hasta 10 miembros'), findsOneWidget);
  });
```

- [ ] **Step 7: Run the affected tests**

Run: `flutter test test/ui/features/subscription/plan_comparison_card_test.dart test/ui/features/subscription/rescue_screen_test.dart`
Expected: los tests de texto PASAN; los 3 golden de `plan_comparison_card_*` FALLAN (aún no existe el `.png`).

- [ ] **Step 8: Generate the new goldens**

Run: `flutter test --update-goldens test/ui/features/subscription/plan_comparison_card_test.dart`
Then verify: `flutter test test/ui/features/subscription/plan_comparison_card_test.dart`
Expected: PASS (goldens creados en `test/ui/features/subscription/goldens/plan_comparison_card_{2,5,10}.png`).

- [ ] **Step 9: Commit**

```bash
git add lib/features/subscription/presentation/widgets/plan_comparison_card.dart \
        lib/features/subscription/presentation/skins/paywall_screen_v2.dart \
        lib/features/subscription/presentation/skins/rescue_screen_v2.dart \
        test/ui/features/subscription/plan_comparison_card_test.dart \
        test/ui/features/subscription/rescue_screen_test.dart \
        test/ui/features/subscription/goldens/plan_comparison_card_2.png \
        test/ui/features/subscription/goldens/plan_comparison_card_5.png \
        test/ui/features/subscription/goldens/plan_comparison_card_10.png
git commit -m "feat(paywall-05): PlanComparisonCard parametrizado por tier (miembros del plan real)"
```

---

### Task 3: Precio de Grupo en el paywall binario + ahorro 21,89 €

Los chips de precio del paywall binario dejan de mostrar 3,99/29,99 € (Familia) y muestran el precio de **Grupo** (lo que vende el SKU legacy) leído de la store con fallback ARB, y el ahorro correcto de Grupo.

**Files:**
- Modify: `lib/features/subscription/presentation/skins/paywall_screen_v2.dart` (`_BinaryPaywallBody`)
- Modify: `lib/l10n/app_es.arb`, `lib/l10n/app_en.arb`, `lib/l10n/app_ro.arb` (`subscription_annual_saving`)
- Modify: `test/ui/features/subscription/paywall_screen_test.dart`

**Interfaces:**
- Consumes: `tierPricingProvider` (`FutureProvider<Map<String, TierProductInfo>>`), `productIdFor(HomeTier, BillingCycle)`, `tierFallbackPrice(l10n, HomeTier, BillingCycle)`, `l10n.subscription_annual_saving`. Todos ya importados en `paywall_screen_v2.dart`.
- Produces: ninguna interfaz nueva (cambio interno del cuerpo binario).

- [ ] **Step 1: Update ARB — ahorro de Grupo (21,89 €)**

Editar el valor de `subscription_annual_saving` en los 3 ARB:
- `lib/l10n/app_es.arb`: `"subscription_annual_saving": "Ahorra 21,89 €",`
- `lib/l10n/app_en.arb`: `"subscription_annual_saving": "Save €21.89",`
- `lib/l10n/app_ro.arb`: `"subscription_annual_saving": "Economisești 21,89 €",`

- [ ] **Step 2: Regenerate localizations**

Run: `flutter gen-l10n`
Expected: sin errores; `lib/l10n/app_localizations_es.dart` ahora devuelve `'Ahorra 21,89 €'`.

- [ ] **Step 3: Write the failing test**

En `test/ui/features/subscription/paywall_screen_test.dart`, añadir los imports al principio (junto a los existentes):

```dart
import 'package:toka/features/subscription/application/tier_pricing_provider.dart';
import 'package:toka/features/subscription/domain/tier_catalog.dart';
```

Añadir `tierPricingProvider` a `baseOverrides` (fallback determinista: mapa vacío → usa fallback ARB Grupo) y a `overridesWithOffer`:

```dart
  final baseOverrides = <Override>[
    currentHomeProvider.overrideWith(() => _FakeCurrentHome(home: _freeHome)),
    paywallProvider.overrideWith(() => _FakePaywall()),
    annualIntroOfferProvider.overrideWith((ref) async => IntroOffer.none),
    tierPricingProvider.overrideWith((ref) async => const {}),
  ];
```
```dart
  List<Override> overridesWithOffer(IntroOffer offer) => [
        currentHomeProvider
            .overrideWith(() => _FakeCurrentHome(home: _freeHome)),
        paywallProvider.overrideWith(() => _FakePaywall()),
        annualIntroOfferProvider.overrideWith((ref) async => offer),
        tierPricingProvider.overrideWith((ref) async => const {}),
      ];
```

Añadir dos tests nuevos dentro de `void main()`:

```dart
  testWidgets('binario: precios de Grupo (fallback ARB), no las cifras de Familia',
      (tester) async {
    await tester.pumpWidget(
        _wrap(const PaywallScreenV2(), overrides: baseOverrides));
    await tester.pumpAndSettle();

    expect(find.text('5,99 €'), findsOneWidget); // Grupo mensual
    expect(find.text('49,99 €'), findsOneWidget); // Grupo anual
    expect(find.text('Ahorra 21,89 €'), findsOneWidget);
    expect(find.text('3,99 €/mes'), findsNothing);
    expect(find.text('29,99 €/año'), findsNothing);
  });

  testWidgets('binario: usa el precio localizado de la store cuando existe',
      (tester) async {
    final overrides = <Override>[
      currentHomeProvider.overrideWith(() => _FakeCurrentHome(home: _freeHome)),
      paywallProvider.overrideWith(() => _FakePaywall()),
      annualIntroOfferProvider.overrideWith((ref) async => IntroOffer.none),
      tierPricingProvider.overrideWith((ref) async => {
            productIdFor(HomeTier.grupo, BillingCycle.monthly): const TierProductInfo(
              productId: 'toka_grupo_monthly',
              price: '7,77 €',
              introOffer: IntroOffer.none,
            ),
            productIdFor(HomeTier.grupo, BillingCycle.annual): const TierProductInfo(
              productId: 'toka_grupo_annual',
              price: '66,66 €',
              introOffer: IntroOffer.none,
            ),
          }),
    ];
    await tester.pumpWidget(_wrap(const PaywallScreenV2(), overrides: overrides));
    await tester.pumpAndSettle();

    expect(find.text('7,77 €'), findsOneWidget);
    expect(find.text('66,66 €'), findsOneWidget);
    expect(find.text('5,99 €'), findsNothing);
  });
```

- [ ] **Step 4: Run test to verify it fails**

Run: `flutter test test/ui/features/subscription/paywall_screen_test.dart`
Expected: FAIL — los chips aún muestran `3,99 €/mes` y `29,99 €/año`.

- [ ] **Step 5: Implement — leer precio de Grupo en `_BinaryPaywallBody`**

En `paywall_screen_v2.dart`, en `_BinaryPaywallBody.build`, tras `final hasTrial = annualOffer.hasFreeTrial;`, añadir:

```dart
    // Modo binario: el SKU legacy vende Grupo (10). Mostramos el precio de Grupo
    // de la store con fallback ARB de Grupo, no las cifras genéricas antiguas.
    final pricing = ref.watch(tierPricingProvider).valueOrNull ?? const {};
    final monthlyPrice =
        pricing[productIdFor(HomeTier.grupo, BillingCycle.monthly)]?.price ??
            tierFallbackPrice(l10n, HomeTier.grupo, BillingCycle.monthly);
    final annualPrice =
        pricing[productIdFor(HomeTier.grupo, BillingCycle.annual)]?.price ??
            tierFallbackPrice(l10n, HomeTier.grupo, BillingCycle.annual);
```

Cambiar los dos `_PriceChip`:

```dart
          _PriceChip(
            key: const Key('chip_annual'),
            label: l10n.subscription_annual,
            price: annualPrice,
            badge: hasTrial
                ? l10n.paywall_trial_badge(annualOffer.freeTrialDays)
                : l10n.subscription_annual_saving,
          ),
          const SizedBox(height: 8),
          _PriceChip(
            key: const Key('chip_monthly'),
            label: l10n.subscription_monthly,
            price: monthlyPrice,
          ),
```

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/ui/features/subscription/paywall_screen_test.dart`
Expected: los tests de texto PASAN; el test `golden: PaywallScreen` FALLA (el golden viejo tiene 3,99/29,99 y "Hasta 10 miembros por hogar").

- [ ] **Step 7: Regenerate the paywall golden**

Run: `flutter test --update-goldens test/ui/features/subscription/paywall_screen_test.dart`
Then verify: `flutter test test/ui/features/subscription/paywall_screen_test.dart`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/features/subscription/presentation/skins/paywall_screen_v2.dart \
        lib/l10n/app_es.arb lib/l10n/app_en.arb lib/l10n/app_ro.arb \
        lib/l10n/app_localizations.dart lib/l10n/app_localizations_es.dart \
        lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_ro.dart \
        test/ui/features/subscription/paywall_screen_test.dart \
        test/ui/features/subscription/goldens/paywall_screen.png
git commit -m "feat(paywall-05): paywall binario muestra precio de Grupo (store+fallback) y ahorro correcto"
```

---

### Task 4: `PlanSummaryCard._buildFree` — copy de rango + clave ARB nueva

La tarjeta "Con Premium desbloqueas" de un hogar Free deja de prometer "Hasta 10" y muestra el rango real.

**Files:**
- Create (clave): `lib/l10n/app_es.arb`, `app_en.arb`, `app_ro.arb` (`premium_benefit_members_range`)
- Modify: `lib/features/subscription/presentation/widgets/plan_summary_card.dart:137`
- Modify: `test/ui/features/subscription/plan_summary_card_test.dart`

**Interfaces:**
- Consumes: `l10n.premium_benefit_members_range` (nueva).
- Produces: ninguna interfaz nueva.

- [ ] **Step 1: Add the new ARB key (template es + en + ro)**

En `lib/l10n/app_es.arb`, junto a las otras claves de beneficios (cerca de `paywall_feature_smart`), añadir:

```json
  "premium_benefit_members_range": "De 2 a 10 miembros según el plan",
  "@premium_benefit_members_range": { "description": "Free benefit card: member range across tiers" },
```

En `lib/l10n/app_en.arb`:
```json
  "premium_benefit_members_range": "From 2 to 10 members depending on your plan",
```

En `lib/l10n/app_ro.arb`:
```json
  "premium_benefit_members_range": "De la 2 la 10 membri în funcție de plan",
```

(En en/ro NO se repite el bloque `@...`; solo va en el template `app_es.arb`.)

- [ ] **Step 2: Regenerate localizations**

Run: `flutter gen-l10n`
Expected: sin errores; `String get premium_benefit_members_range` aparece en `app_localizations*.dart`.

- [ ] **Step 3: Write the failing test**

En `test/ui/features/subscription/plan_summary_card_test.dart`, añadir un test (el harness `_dashboard`/`_wrap` ya existe):

```dart
  testWidgets('free: muestra el rango de miembros, no "Hasta 10" fijo', (t) async {
    await t.pumpWidget(_wrap(
      PlanSummaryCard(
        data: _dashboard(
          HomePremiumStatus.free,
          plan: null,
          withEndsAt: false,
          autoRenew: false,
          payerUid: null,
          counters: const PlanCounters(
            activeMembers: 2,
            activeTasks: 0,
            automaticRecurringTasks: 1,
            totalAdmins: 1,
          ),
        ),
      ),
    ));
    await t.pumpAndSettle();
    expect(find.text('De 2 a 10 miembros según el plan'), findsOneWidget);
    expect(find.text('Hasta 10 miembros por hogar'), findsNothing);
  });
```

- [ ] **Step 4: Run test to verify it fails**

Run: `flutter test test/ui/features/subscription/plan_summary_card_test.dart`
Expected: FAIL — la card aún muestra `Hasta 10 miembros por hogar`.

- [ ] **Step 5: Implement**

En `plan_summary_card.dart`, dentro de `_buildFree`, cambiar:

```dart
      _benefit(l10n.paywall_feature_members),
```
por:
```dart
      _benefit(l10n.premium_benefit_members_range),
```

- [ ] **Step 6: Run test + regenerate the free golden**

Run: `flutter test test/ui/features/subscription/plan_summary_card_test.dart`
Expected: el test de texto PASA; `golden: PlanSummaryCard estado free` FALLA (el golden viejo tiene "Hasta 10 miembros por hogar").

Run: `flutter test --update-goldens test/ui/features/subscription/plan_summary_card_test.dart`
Then verify: `flutter test test/ui/features/subscription/plan_summary_card_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/subscription/presentation/widgets/plan_summary_card.dart \
        lib/l10n/app_es.arb lib/l10n/app_en.arb lib/l10n/app_ro.arb \
        lib/l10n/app_localizations.dart lib/l10n/app_localizations_es.dart \
        lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_ro.dart \
        test/ui/features/subscription/plan_summary_card_test.dart \
        test/ui/features/subscription/goldens/plan_summary_card_free.png
git commit -m "feat(paywall-05): tarjeta Free muestra el rango de miembros por plan (no '10' fijo)"
```

---

### Task 5: Limpieza de claves ARB huérfanas + verificación global

Eliminar las claves del modelo binario que ya nadie usa (`paywall_feature_members`, `subscription_price_monthly`, `subscription_price_annual`) y confirmar que toda la suite y el análisis estático pasan.

**Files:**
- Modify: `lib/l10n/app_es.arb`, `app_en.arb`, `app_ro.arb`
- Regenera: `lib/l10n/app_localizations*.dart`

**Interfaces:**
- Consumes/Produces: ninguna (limpieza).

- [ ] **Step 1: Verify no remaining references**

Run: `grep -rn "paywall_feature_members\|subscription_price_monthly\|subscription_price_annual" lib --include="*.dart" | grep -v "app_localizations"`
Expected: SIN resultados (Tasks 2–4 ya eliminaron todos los usos). Si aparece alguno, corregirlo antes de seguir.

- [ ] **Step 2: Remove the orphan keys from the 3 ARB files**

En `lib/l10n/app_es.arb` eliminar estas líneas (clave + su `@`):
```json
  "subscription_price_monthly": "3,99 €/mes",
  "@subscription_price_monthly": { "description": "Monthly price" },
  "subscription_price_annual": "29,99 €/año",
  "@subscription_price_annual": { "description": "Annual price" },
  "paywall_feature_members": "Hasta 10 miembros por hogar",
  "@paywall_feature_members": { "description": "Premium feature: members" },
```
En `lib/l10n/app_en.arb` y `lib/l10n/app_ro.arb` eliminar las claves `subscription_price_monthly`, `subscription_price_annual`, `paywall_feature_members` (en estos archivos no llevan bloque `@`).

Cuidar la sintaxis JSON: no dejar una coma colgando ni quitar la coma que separa la clave anterior de la siguiente.

- [ ] **Step 3: Regenerate localizations**

Run: `flutter gen-l10n`
Expected: sin errores; los getters `paywall_feature_members`, `subscription_price_monthly`, `subscription_price_annual` desaparecen de `app_localizations*.dart`.

- [ ] **Step 4: Static analysis**

Run: `flutter analyze`
Expected: sin errores nuevos (referencias a las claves eliminadas = 0).

- [ ] **Step 5: Run the full subscription test suite**

Run: `flutter test test/unit/features/subscription/ test/ui/features/subscription/`
Expected: PASS. (Nota: pueden persistir fallos golden PREEXISTENTES del WIP ajenos a esta tarea —ver memoria de cierre de monetización—; confirmar que los que fallan NO son de los archivos tocados aquí: `plan_comparison_card_*`, `paywall_screen`, `plan_summary_card_free`, `rescue_*`.)

- [ ] **Step 6: Commit**

```bash
git add lib/l10n/app_es.arb lib/l10n/app_en.arb lib/l10n/app_ro.arb \
        lib/l10n/app_localizations.dart lib/l10n/app_localizations_es.dart \
        lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_ro.dart
git commit -m "chore(paywall-05): elimina claves ARB binarias huérfanas (members/price)"
```

---

### Task 6: Verificación en dispositivo (Firebase real) + cierre del hallazgo

Verificación end-to-end por adb (no se delega: se verifica en MI_9 + emulador, según convención del proyecto).

**Files:**
- Modify: `Arreglos/.../INDICE.md` (marcar #05 ✅ + fecha + nota)

- [ ] **Step 1: Build e instalar** el APK `main_dev` actualizado (compilar con el Flutter de Windows; ejecutar `flutter pub get` en Windows ANTES del build, y restaurar `package_config.json` con `flutter pub get` en WSL después, para no romper los tests — ver memorias de build).

- [ ] **Step 2: home_tiers_enabled ON** — abrir el paywall desde un hogar **Pareja** y otro **Familia** (cuenta QA con dos hogares). Capturar: las cifras de miembros/precio deben diferir y ser correctas (Pareja 2/2,99 · Familia 5/3,99). `magick` a `C:\tmp` para leer.

- [ ] **Step 3: Rescate** — llevar un hogar Pareja a ventana de rescate (`qa_premium.js` / Admin SDK) y abrir `/subscription/rescue`: la comparación debe decir "Hasta 2 miembros", no "Hasta 10". Captura.

- [ ] **Step 4: home_tiers_enabled OFF** (binario) — verificar que no aparecen cifras absurdas: Grupo/10 + precios de Grupo (5,99/49,99) o el localizado de store. Captura.

- [ ] **Step 5: Cerrar** — actualizar `INDICE.md` (#05 ✅ + fecha 2026-06-25 + nota), listar archivos y capturas en la respuesta final.

---

## Self-Review

**1. Spec coverage:**
- Criterio "miembros = tier concreto, nunca 10 fijo" → Task 2 (PlanComparisonCard) + Task 4 (Free). ✓
- Criterio "precio de store + fallback del tier correcto, no 3,99 plano" → Task 3. ✓
- Criterio "rescate muestra su tier, coherente con renewal_product" → Task 1 + Task 2 (call site rescate). ✓
- Criterio "sin strings hardcodeadas; todo en ARB es/en/ro" → Task 3/4 (ARB) + Task 5 (limpieza). ✓
- Criterio "no romper binario legacy (tier por defecto Grupo)" → Task 2 (binario→Grupo.maxMembers) + Task 3 (precio Grupo). ✓
- Pruebas unit/widget/golden → Tasks 1–4; verificación en dispositivo → Task 6. ✓

**2. Placeholder scan:** Sin TBD/TODO; todos los pasos llevan código o comando concreto. ✓

**3. Type consistency:** `premiumMemberLimit` es `int` en `RescueViewModel` (Task 1), en `PlanComparisonCard` (Task 2) y se alimenta de `HomeTierX.maxMembers` (int) y `vm.premiumMemberLimit` (int). `tierFallbackPrice(l10n, HomeTier, BillingCycle)` y `productIdFor(HomeTier, BillingCycle)` se usan con las firmas existentes. `TierProductInfo` const con `productId/price/introOffer`. ✓
