# Hallazgo #09 — Transparencia "esto compartes con el hogar" al unirse · Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mostrar un aviso de transparencia antes de confirmar la unión a un hogar (onboarding y selector) que informe de qué verán los demás miembros (nombre, foto, estadísticas; teléfono solo si es visible), con acceso a cambiar la visibilidad del teléfono.

**Architecture:** Un widget puro nuevo `JoinPrivacyNotice` (sin providers) insertado en las dos entradas de unión. El estado de visibilidad del teléfono (`phoneShared`) se calcula fuera del widget: del estado del onboarding en la entrada de onboarding, y del perfil real en Firestore (`userProfileProvider`) en el selector. Solo cliente Flutter + ARB; no se tocan reglas ni backend.

**Tech Stack:** Flutter 3.x, Riverpod, go_router, flutter_localizations + ARB (es/en/ro), flutter_test + mocktail.

## Global Constraints

- **Sin texto UI hardcodeado.** Toda string nueva va en `lib/l10n/app_es.arb`, `app_en.arb`, `app_ro.arb` y se accede con `l10n.<clave>`. Regenerar con `flutter gen-l10n` tras editar.
- **Solo el `app_es.arb` (template) lleva bloques `@<clave>` de metadata**; `app_en.arb`/`app_ro.arb` solo llevan el par `"clave": "valor"`.
- **Las pantallas reales son las `*_v2.dart`.** Los archivos sin sufijo son wrappers `SkinSwitch`.
- **`phoneVisibility`** toma `'hidden'` (default) o `'sameHomeMembers'`. `phoneShared := (phone no vacío) && (phoneVisibility == 'sameHomeMembers')`. El copy nunca promete mostrar el teléfono si `phoneShared == false`.
- **Sin tocar** `firestore.rules`, `functions/`, ni el modelo de datos.
- **Tests en WSL**: correr `flutter test <archivo>` en **foreground** (lanzarlo en background no escribe output) y acotado a los archivos del cambio. No compilar Android desde WSL.
- **Nota de entorno:** el working tree ya contiene WIP de otros hallazgos del lote sin commitear (incl. `lib/l10n/app_localizations*.dart`). Al regenerar l10n y commitear, los archivos generados pueden arrastrar líneas previas del WIP del lote: es esperado. Añadir por ruta explícita los archivos de cada task.

---

## File Structure

**Nuevos:**
- `lib/features/homes/presentation/widgets/join_privacy_notice.dart` — widget puro del aviso.
- `test/ui/features/homes/join_privacy_notice_test.dart` — test de widget aislado.

**Modificados:**
- `lib/l10n/app_es.arb`, `app_en.arb`, `app_ro.arb` — 5 claves nuevas (+ generados `app_localizations*.dart`).
- `lib/features/onboarding/presentation/widgets/home_join_form.dart` — parámetro `phoneShared` + inserción del aviso.
- `lib/features/onboarding/presentation/steps/skins/home_choice_step_v2.dart` — propaga `phoneShared`.
- `lib/features/onboarding/presentation/steps/skins/home_choice_step.dart` — propaga `phoneShared`.
- `lib/features/onboarding/presentation/onboarding_flow_screen.dart` — calcula `phoneShared` del view model.
- `lib/features/homes/presentation/home_selector_widget.dart` — aviso + enlace en `_buildJoinCode`.
- `test/ui/features/onboarding/onboarding_flow_test.dart` — test nuevo de integración onboarding.
- `test/ui/features/homes/home_selector_widget_test.dart` — test nuevo de integración selector.

---

## Task 1: i18n — 5 claves del aviso en es/en/ro + regenerar

**Files:**
- Modify: `lib/l10n/app_es.arb` (final del objeto)
- Modify: `lib/l10n/app_en.arb` (final del objeto)
- Modify: `lib/l10n/app_ro.arb` (final del objeto)
- Generated: `lib/l10n/app_localizations.dart`, `app_localizations_es.dart`, `app_localizations_en.dart`, `app_localizations_ro.dart`

**Interfaces:**
- Produces: getters `l10n.join_privacy_notice_intro`, `join_privacy_notice_phone_visible`, `join_privacy_notice_phone_hidden`, `join_privacy_notice_change`, `join_privacy_notice_change_hint` (todos `String`, sin placeholders).

- [ ] **Step 1: Añadir las claves al template `app_es.arb`**

Sustituir (el cierre actual del archivo):

```json
  "@ad_banner_notice_dismiss": { "description": "Accessibility label for the dismiss (x) button on the banner notice caption" }
}
```

por:

```json
  "@ad_banner_notice_dismiss": { "description": "Accessibility label for the dismiss (x) button on the banner notice caption" },
  "join_privacy_notice_intro": "Al unirte, los miembros del hogar verán tu nombre, tu foto y tus estadísticas de tareas.",
  "@join_privacy_notice_intro": { "description": "Transparency notice (Hallazgo #09) shown before joining a home: what other members will see" },
  "join_privacy_notice_phone_visible": "Tu teléfono también será visible para ellos.",
  "@join_privacy_notice_phone_visible": { "description": "Join transparency notice: phone line when the user's phone is visible to home members" },
  "join_privacy_notice_phone_hidden": "Tu teléfono permanece oculto.",
  "@join_privacy_notice_phone_hidden": { "description": "Join transparency notice: phone line when the user's phone stays hidden" },
  "join_privacy_notice_change": "Cambiar",
  "@join_privacy_notice_change": { "description": "Join transparency notice: link to change phone visibility (opens edit profile)" },
  "join_privacy_notice_change_hint": "Puedes ajustar la visibilidad de tu teléfono en tu perfil.",
  "@join_privacy_notice_change_hint": { "description": "Join transparency notice: textual hint (onboarding) on where to change phone visibility" }
}
```

- [ ] **Step 2: Añadir las claves a `app_en.arb`**

Sustituir:

```json
  "ad_banner_notice_dismiss": "Dismiss"
}
```

por:

```json
  "ad_banner_notice_dismiss": "Dismiss",
  "join_privacy_notice_intro": "When you join, the household members will see your name, photo and task stats.",
  "join_privacy_notice_phone_visible": "Your phone number will also be visible to them.",
  "join_privacy_notice_phone_hidden": "Your phone number stays hidden.",
  "join_privacy_notice_change": "Change",
  "join_privacy_notice_change_hint": "You can adjust your phone visibility in your profile."
}
```

- [ ] **Step 3: Añadir las claves a `app_ro.arb`**

Sustituir:

```json
  "ad_banner_notice_dismiss": "Închide"
}
```

por:

```json
  "ad_banner_notice_dismiss": "Închide",
  "join_privacy_notice_intro": "Când te alături, membrii casei îți vor vedea numele, fotografia și statisticile sarcinilor.",
  "join_privacy_notice_phone_visible": "Numărul tău de telefon va fi de asemenea vizibil pentru ei.",
  "join_privacy_notice_phone_hidden": "Numărul tău de telefon rămâne ascuns.",
  "join_privacy_notice_change": "Modifică",
  "join_privacy_notice_change_hint": "Poți ajusta vizibilitatea telefonului în profilul tău."
}
```

- [ ] **Step 4: Regenerar las localizaciones**

Run: `flutter gen-l10n`
Expected: termina sin errores; `lib/l10n/app_localizations.dart` ahora declara `String get join_privacy_notice_intro;` (y las otras 4).

- [ ] **Step 5: Verificar que los getters existen**

Run: `grep -n "join_privacy_notice_intro\|join_privacy_notice_phone_visible\|join_privacy_notice_phone_hidden\|join_privacy_notice_change\b\|join_privacy_notice_change_hint" lib/l10n/app_localizations.dart`
Expected: 5 líneas (una por getter abstracto).

- [ ] **Step 6: Analyze de l10n**

Run: `flutter analyze lib/l10n/`
Expected: No issues (en los archivos de l10n).

- [ ] **Step 7: Commit**

```bash
git add lib/l10n/app_es.arb lib/l10n/app_en.arb lib/l10n/app_ro.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_es.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_ro.dart
git commit -m "feat(h09): i18n del aviso de transparencia al unirse (es/en/ro)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Widget `JoinPrivacyNotice` (TDD)

**Files:**
- Create: `lib/features/homes/presentation/widgets/join_privacy_notice.dart`
- Test: `test/ui/features/homes/join_privacy_notice_test.dart`

**Interfaces:**
- Produces: `class JoinPrivacyNotice extends StatelessWidget` con constructor
  `JoinPrivacyNotice({Key? key, required bool phoneShared, VoidCallback? onChangeVisibility})`.
  - Raíz con `Key('join_privacy_notice')`.
  - Enlace "Cambiar" con `Key('join_privacy_change_visibility')` (solo si `onChangeVisibility != null`).
- Consumes: getters i18n de la Task 1.

- [ ] **Step 1: Escribir el test de widget que falla**

Crear `test/ui/features/homes/join_privacy_notice_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/homes/presentation/widgets/join_privacy_notice.dart';
import 'package:toka/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('muestra siempre el texto base (nombre/foto/estadísticas)',
      (tester) async {
    await tester.pumpWidget(_wrap(const JoinPrivacyNotice(phoneShared: false)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('join_privacy_notice')), findsOneWidget);
    expect(
      find.text(
          'Al unirte, los miembros del hogar verán tu nombre, tu foto y tus estadísticas de tareas.'),
      findsOneWidget,
    );
  });

  testWidgets('phoneShared=true → promete teléfono visible; no dice oculto',
      (tester) async {
    await tester.pumpWidget(_wrap(const JoinPrivacyNotice(phoneShared: true)));
    await tester.pumpAndSettle();

    expect(find.text('Tu teléfono también será visible para ellos.'),
        findsOneWidget);
    expect(find.text('Tu teléfono permanece oculto.'), findsNothing);
  });

  testWidgets('phoneShared=false → dice oculto; NO promete mostrarlo',
      (tester) async {
    await tester.pumpWidget(_wrap(const JoinPrivacyNotice(phoneShared: false)));
    await tester.pumpAndSettle();

    expect(find.text('Tu teléfono permanece oculto.'), findsOneWidget);
    expect(find.text('Tu teléfono también será visible para ellos.'),
        findsNothing);
  });

  testWidgets('con onChangeVisibility → muestra enlace "Cambiar" y lo invoca',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(
      JoinPrivacyNotice(phoneShared: false, onChangeVisibility: () => taps++),
    ));
    await tester.pumpAndSettle();

    final link = find.byKey(const Key('join_privacy_change_visibility'));
    expect(link, findsOneWidget);
    expect(find.text('Cambiar'), findsOneWidget);
    // La mención textual NO aparece cuando hay enlace.
    expect(
        find.text('Puedes ajustar la visibilidad de tu teléfono en tu perfil.'),
        findsNothing);

    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('sin onChangeVisibility → mención textual, sin enlace',
      (tester) async {
    await tester.pumpWidget(_wrap(const JoinPrivacyNotice(phoneShared: false)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('join_privacy_change_visibility')), findsNothing);
    expect(
        find.text('Puedes ajustar la visibilidad de tu teléfono en tu perfil.'),
        findsOneWidget);
  });
}
```

- [ ] **Step 2: Correr el test y verificar que falla (no compila: widget inexistente)**

Run: `flutter test test/ui/features/homes/join_privacy_notice_test.dart`
Expected: FAIL — error de compilación "Couldn't resolve the package 'join_privacy_notice.dart'" / `JoinPrivacyNotice` no definido.

- [ ] **Step 3: Implementar el widget**

Crear `lib/features/homes/presentation/widgets/join_privacy_notice.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Aviso de transparencia mostrado en el flujo de unión a un hogar (Hallazgo
/// #09): antes de confirmar la unión, informa de qué verán los demás miembros
/// (nombre, foto, estadísticas; teléfono solo si es visible). Widget puro: no
/// lee providers; recibe el estado por parámetro para ser testeable aislado.
class JoinPrivacyNotice extends StatelessWidget {
  const JoinPrivacyNotice({
    super.key,
    required this.phoneShared,
    this.onChangeVisibility,
  });

  /// El teléfono del usuario se compartirá con los miembros (tiene teléfono y
  /// `phoneVisibility == 'sameHomeMembers'`). Gobierna la línea del teléfono.
  final bool phoneShared;

  /// Si no es null, se muestra un enlace "Cambiar" que lo invoca (selector:
  /// navega a editar perfil). Si es null, se muestra una mención textual de
  /// dónde ajustarlo (onboarding: sin navegar fuera del flujo).
  final VoidCallback? onChangeVisibility;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bodyStyle = textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant);

    return Container(
      key: const Key('join_privacy_notice'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.join_privacy_notice_intro, style: bodyStyle),
                const SizedBox(height: 4),
                Text(
                  phoneShared
                      ? l10n.join_privacy_notice_phone_visible
                      : l10n.join_privacy_notice_phone_hidden,
                  style: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                if (onChangeVisibility != null)
                  TextButton(
                    key: const Key('join_privacy_change_visibility'),
                    onPressed: onChangeVisibility,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.centerLeft,
                    ),
                    child: Text(l10n.join_privacy_notice_change),
                  )
                else
                  Text(
                    l10n.join_privacy_notice_change_hint,
                    style: bodyStyle?.copyWith(fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Correr el test y verificar que pasa**

Run: `flutter test test/ui/features/homes/join_privacy_notice_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: Analyze**

Run: `flutter analyze lib/features/homes/presentation/widgets/join_privacy_notice.dart test/ui/features/homes/join_privacy_notice_test.dart`
Expected: No issues.

- [ ] **Step 6: Commit**

```bash
git add lib/features/homes/presentation/widgets/join_privacy_notice.dart test/ui/features/homes/join_privacy_notice_test.dart
git commit -m "feat(h09): widget JoinPrivacyNotice (aviso de transparencia al unirse)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Integración en onboarding (HomeJoinForm + propagación) + test

**Files:**
- Modify: `lib/features/onboarding/presentation/widgets/home_join_form.dart`
- Modify: `lib/features/onboarding/presentation/steps/skins/home_choice_step_v2.dart`
- Modify: `lib/features/onboarding/presentation/steps/skins/home_choice_step.dart`
- Modify: `lib/features/onboarding/presentation/onboarding_flow_screen.dart:103-110`
- Test: `test/ui/features/onboarding/onboarding_flow_test.dart`

**Interfaces:**
- Consumes: `JoinPrivacyNotice` (Task 2).
- Produces: `HomeJoinForm`, `HomeChoiceStepV2`, `HomeChoiceStep` ganan `final bool phoneShared` con default `false`.

- [ ] **Step 1: Escribir el test de integración del onboarding (falla)**

Añadir al final del `main()` de `test/ui/features/onboarding/onboarding_flow_test.dart` (antes de la `}` de cierre de `main`):

```dart
  // ── Hallazgo #09: aviso de transparencia en el form de unión ──────────────
  Widget wrapJoinFormPhone({required bool phoneShared}) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es')],
        home: Scaffold(
          body: HomeJoinForm(
            isLoading: false,
            error: null,
            phoneShared: phoneShared,
            onJoin: (_) async {},
            onBack: () {},
          ),
        ),
      );

  testWidgets(
      'HomeJoinForm (#09) muestra el aviso de transparencia antes del botón, '
      'sin enlace Cambiar (mención textual en onboarding)', (tester) async {
    await tester.pumpWidget(wrapJoinFormPhone(phoneShared: false));
    await tester.pumpAndSettle();

    // El aviso está presente y antes del botón Unirme.
    expect(find.byKey(const Key('join_privacy_notice')), findsOneWidget);
    expect(find.byKey(const Key('join_button')), findsOneWidget);
    // En onboarding no hay enlace navegable: mención textual.
    expect(find.byKey(const Key('join_privacy_change_visibility')), findsNothing);
    expect(
        find.text('Puedes ajustar la visibilidad de tu teléfono en tu perfil.'),
        findsOneWidget);
    // Teléfono oculto → no promete mostrarlo.
    expect(find.text('Tu teléfono permanece oculto.'), findsOneWidget);
  });

  testWidgets(
      'HomeJoinForm (#09) con phoneShared=true promete teléfono visible',
      (tester) async {
    await tester.pumpWidget(wrapJoinFormPhone(phoneShared: true));
    await tester.pumpAndSettle();

    expect(find.text('Tu teléfono también será visible para ellos.'),
        findsOneWidget);
    expect(find.text('Tu teléfono permanece oculto.'), findsNothing);
  });
```

(No hace falta importar `JoinPrivacyNotice` en este archivo de test: el aviso se localiza por `Key`/texto, no por tipo. Importarlo sin usarlo dispararía `unused_import`.)

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `flutter test test/ui/features/onboarding/onboarding_flow_test.dart -n "#09"`
Expected: FAIL — `HomeJoinForm` no acepta el parámetro `phoneShared` (error de compilación).

- [ ] **Step 3: Añadir `phoneShared` a `HomeJoinForm` e insertar el aviso**

En `lib/features/onboarding/presentation/widgets/home_join_form.dart`:

Añadir el import (junto a los otros imports relativos):

```dart
import '../../../homes/presentation/widgets/join_privacy_notice.dart';
```

En el constructor y los campos de `HomeJoinForm` añadir `phoneShared` (default `false`). Sustituir:

```dart
  const HomeJoinForm({
    super.key,
    required this.isLoading,
    required this.error,
    required this.onJoin,
    required this.onBack,
    this.onClearError,
  });

  final bool isLoading;
  final String? error;
  final ValueChanged<String> onJoin;
  final VoidCallback onBack;
```

por:

```dart
  const HomeJoinForm({
    super.key,
    required this.isLoading,
    required this.error,
    required this.onJoin,
    required this.onBack,
    this.onClearError,
    this.phoneShared = false,
  });

  final bool isLoading;
  final String? error;
  final ValueChanged<String> onJoin;
  final VoidCallback onBack;

  /// Si el teléfono del usuario se compartirá con los miembros (Hallazgo #09).
  /// Gobierna la línea del teléfono del aviso de transparencia.
  final bool phoneShared;
```

Insertar el aviso entre el bloque de error del código y el `SizedBox(height: 16)` previo a la `Row` de botones. Sustituir:

```dart
          if (widget.error != null)
            Text(
              _joinErrorText(widget.error!, l10n),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton(
                key: const Key('join_back_button'),
```

por:

```dart
          if (widget.error != null)
            Text(
              _joinErrorText(widget.error!, l10n),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 16),
          // Aviso de transparencia (#09): qué verán los demás miembros. En
          // onboarding sin enlace navegable → mención textual.
          JoinPrivacyNotice(phoneShared: widget.phoneShared),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton(
                key: const Key('join_back_button'),
```

- [ ] **Step 4: Propagar `phoneShared` por `HomeChoiceStepV2`**

En `lib/features/onboarding/presentation/steps/skins/home_choice_step_v2.dart`:

Añadir al constructor y campos (tras `this.onClearError,`):

```dart
    this.phoneShared = false,
```

y el campo (tras `final VoidCallback? onClearError;`):

```dart
  /// Hallazgo #09: si el teléfono del usuario se compartirá al unirse.
  final bool phoneShared;
```

Pasar el flag al `HomeJoinForm`. Sustituir:

```dart
                    HomeJoinForm(
                      isLoading: widget.isLoading,
                      error: widget.error,
                      onJoin: widget.onJoinHome,
                      onBack: () => setState(() => _choice = _HomeChoice.none),
                      onClearError: widget.onClearError,
                    ),
```

por:

```dart
                    HomeJoinForm(
                      isLoading: widget.isLoading,
                      error: widget.error,
                      phoneShared: widget.phoneShared,
                      onJoin: widget.onJoinHome,
                      onBack: () => setState(() => _choice = _HomeChoice.none),
                      onClearError: widget.onClearError,
                    ),
```

- [ ] **Step 5: Propagar `phoneShared` por el wrapper `HomeChoiceStep`**

En `lib/features/onboarding/presentation/steps/skins/home_choice_step.dart`:

Añadir al constructor (tras `this.onClearError,`):

```dart
    this.phoneShared = false,
```

el campo (tras `final VoidCallback? onClearError;`):

```dart
  final bool phoneShared;
```

y pasarlo a `HomeChoiceStepV2`. Sustituir:

```dart
        v2: (_) => HomeChoiceStepV2(
          isLoading: isLoading,
          error: error,
          onCreateHome: onCreateHome,
          onJoinHome: onJoinHome,
          onPrev: onPrev,
          onClearError: onClearError,
        ),
```

por:

```dart
        v2: (_) => HomeChoiceStepV2(
          isLoading: isLoading,
          error: error,
          onCreateHome: onCreateHome,
          onJoinHome: onJoinHome,
          onPrev: onPrev,
          onClearError: onClearError,
          phoneShared: phoneShared,
        ),
```

- [ ] **Step 6: Calcular `phoneShared` en el flow y pasarlo**

En `lib/features/onboarding/presentation/onboarding_flow_screen.dart`, sustituir el bloque del Step 3 (líneas ~103-110):

```dart
                // Step 3: Home choice
                HomeChoiceStep(
                  isLoading: vm.isLoading,
                  error: vm.error,
                  onCreateHome: (name, emoji) => vm.createHome(name, emoji),
                  onJoinHome: vm.joinHome,
                  onPrev: vm.prevStep,
                  onClearError: vm.clearError,
                ),
```

por:

```dart
                // Step 3: Home choice
                HomeChoiceStep(
                  isLoading: vm.isLoading,
                  error: vm.error,
                  // Hallazgo #09: el aviso de transparencia refleja si el
                  // teléfono configurado en el paso de perfil se compartirá.
                  phoneShared: vm.phoneVisible &&
                      (vm.phoneNumber?.trim().isNotEmpty ?? false),
                  onCreateHome: (name, emoji) => vm.createHome(name, emoji),
                  onJoinHome: vm.joinHome,
                  onPrev: vm.prevStep,
                  onClearError: vm.clearError,
                ),
```

- [ ] **Step 7: Correr el test del onboarding y verificar que pasa**

Run: `flutter test test/ui/features/onboarding/onboarding_flow_test.dart`
Expected: PASS (todos: los existentes — que usan `wrapJoinForm`/`wrapHomeChoiceStep` sin `phoneShared`, ahora con default `false` — siguen verdes, más los 2 nuevos del #09).

- [ ] **Step 8: Analyze de los archivos tocados**

Run: `flutter analyze lib/features/onboarding/presentation/widgets/home_join_form.dart lib/features/onboarding/presentation/steps/skins/home_choice_step_v2.dart lib/features/onboarding/presentation/steps/skins/home_choice_step.dart lib/features/onboarding/presentation/onboarding_flow_screen.dart`
Expected: No issues.

- [ ] **Step 9: Commit**

```bash
git add lib/features/onboarding/presentation/widgets/home_join_form.dart lib/features/onboarding/presentation/steps/skins/home_choice_step_v2.dart lib/features/onboarding/presentation/steps/skins/home_choice_step.dart lib/features/onboarding/presentation/onboarding_flow_screen.dart test/ui/features/onboarding/onboarding_flow_test.dart
git commit -m "feat(h09): aviso de transparencia en el form de unión del onboarding

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: Integración en el selector (`_AddHomeSheet._buildJoinCode`) + test

**Files:**
- Modify: `lib/features/homes/presentation/home_selector_widget.dart`
- Test: `test/ui/features/homes/home_selector_widget_test.dart`

**Interfaces:**
- Consumes: `JoinPrivacyNotice` (Task 2), `userProfileProvider` (`features/profile/application/profile_provider.dart`), `authProvider`, `AppRoutes.editProfile`.
- Produces: el modo `joinCode` del `_AddHomeSheet` renderiza `JoinPrivacyNotice` con `onChangeVisibility` (enlace navegable).

- [ ] **Step 1: Escribir el test de integración del selector (falla)**

Añadir al final del `main()` de `test/ui/features/homes/home_selector_widget_test.dart`:

```dart
  // ── Hallazgo #09: aviso de transparencia en el form de unión del selector ──
  UserProfile _profile({required bool phoneShared}) => UserProfile(
        uid: 'uid1',
        nickname: 'User',
        photoUrl: null,
        bio: null,
        phone: phoneShared ? '+34600000000' : null,
        phoneVisibility: phoneShared ? 'sameHomeMembers' : 'hidden',
        locale: 'es',
      );

  Widget _wrapJoinSheetHost({required bool phoneShared}) => ProviderScope(
        overrides: [
          authProvider.overrideWith(
              () => _FakeAuth(const AuthState.authenticated(_fakeUser))),
          userProfileProvider('uid1')
              .overrideWith((ref) => Stream.value(_profile(phoneShared: phoneShared))),
          availableSlotsProvider.overrideWith((ref) => Future.value(5)),
          adBannerConfigProvider
              .overrideWithValue(const AdBannerConfig(show: false, unitId: '')),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('es')],
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  key: const Key('open_join'),
                  onPressed: () => showJoinHomeSheet(context, ref, 1),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

  testWidgets(
      'selector (#09): el form de unión muestra el aviso con enlace Cambiar; '
      'teléfono oculto no se promete', (tester) async {
    await tester.pumpWidget(_wrapJoinSheetHost(phoneShared: false));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open_join')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('join_privacy_notice')), findsOneWidget);
    // En el selector hay enlace navegable a editar perfil.
    expect(find.byKey(const Key('join_privacy_change_visibility')), findsOneWidget);
    expect(find.text('Tu teléfono permanece oculto.'), findsOneWidget);
    expect(find.text('Tu teléfono también será visible para ellos.'),
        findsNothing);
  });

  testWidgets(
      'selector (#09): con teléfono visible el aviso lo refleja',
      (tester) async {
    await tester.pumpWidget(_wrapJoinSheetHost(phoneShared: true));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open_join')));
    await tester.pumpAndSettle();

    expect(find.text('Tu teléfono también será visible para ellos.'),
        findsOneWidget);
    expect(find.text('Tu teléfono permanece oculto.'), findsNothing);
  });
```

Añadir los imports necesarios al principio del archivo de test (junto a los `package:toka/...`):

```dart
import 'package:toka/features/homes/application/home_slot_provider.dart';
import 'package:toka/features/profile/application/profile_provider.dart';
import 'package:toka/features/profile/domain/user_profile.dart';
import 'package:toka/shared/widgets/ad_banner_config_provider.dart';
```

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `flutter test test/ui/features/homes/home_selector_widget_test.dart -n "#09"`
Expected: FAIL — `join_privacy_notice` no se encuentra en el sheet (el `_buildJoinCode` aún no lo renderiza).

- [ ] **Step 3: Importar dependencias en el selector**

En `lib/features/homes/presentation/home_selector_widget.dart`, añadir junto a los imports existentes:

```dart
import '../../profile/application/profile_provider.dart';
import 'widgets/join_privacy_notice.dart';
```

(`authProvider`, `AppRoutes` y `go_router` ya están importados en el archivo.)

- [ ] **Step 4: Renderizar el aviso en `_buildJoinCode`**

En `_AddHomeSheetState._buildJoinCode`, calcular `phoneShared` al inicio del método y renderizar el aviso encima del botón de envío. Sustituir el inicio del método:

```dart
  Widget _buildJoinCode(BuildContext context, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
```

por:

```dart
  Widget _buildJoinCode(BuildContext context, AppLocalizations l10n) {
    // Hallazgo #09: el aviso refleja el estado REAL de visibilidad del
    // teléfono del usuario (perfil en Firestore). Si aún no resolvió, se
    // trata como no compartido para no prometer de más.
    final uid =
        ref.read(authProvider).whenOrNull(authenticated: (u) => u.uid);
    final profile =
        uid != null ? ref.watch(userProfileProvider(uid)).valueOrNull : null;
    final phoneShared = (profile?.phone?.trim().isNotEmpty ?? false) &&
        profile?.phoneVisibility == 'sameHomeMembers';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
```

Insertar el aviso justo antes del `FilledButton` de envío. Sustituir:

```dart
        if (_error != null) ...[
          const SizedBox(height: 4),
          Text(_error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('btn_join_submit'),
```

por:

```dart
        if (_error != null) ...[
          const SizedBox(height: 4),
          Text(_error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 12),
        JoinPrivacyNotice(
          phoneShared: phoneShared,
          onChangeVisibility: () {
            Navigator.of(context).pop();
            context.push(AppRoutes.editProfile);
          },
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('btn_join_submit'),
```

- [ ] **Step 5: Correr el test del selector y verificar que pasa**

Run: `flutter test test/ui/features/homes/home_selector_widget_test.dart`
Expected: PASS (los existentes + los 2 nuevos del #09).

- [ ] **Step 6: Analyze**

Run: `flutter analyze lib/features/homes/presentation/home_selector_widget.dart test/ui/features/homes/home_selector_widget_test.dart`
Expected: No issues.

- [ ] **Step 7: Commit**

```bash
git add lib/features/homes/presentation/home_selector_widget.dart test/ui/features/homes/home_selector_widget_test.dart
git commit -m "feat(h09): aviso de transparencia en el form de unión del selector + enlace a visibilidad

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: Gates de cierre + verificación en dispositivo + INDICE

**Files:**
- Modify: `Arreglos/ux_hallazgos_2026-06-25/INDICE.md`

- [ ] **Step 1: Analyze global de los archivos del hallazgo**

Run: `flutter analyze lib/features/homes lib/features/onboarding lib/l10n`
Expected: No issues (ni errores ni warnings nuevos en los archivos tocados).

- [ ] **Step 2: Correr la batería de tests del hallazgo**

Run: `flutter test test/ui/features/homes/join_privacy_notice_test.dart test/ui/features/onboarding/onboarding_flow_test.dart test/ui/features/homes/home_selector_widget_test.dart`
Expected: PASS. (Si algún golden del selector/onboarding cambia por el nuevo bloque, regenerar con `--update-goldens` SOLO esos archivos y revisar el diff visual antes de aceptar; documentar cuáles.)

- [ ] **Step 3: Suite unit completa (regresión)**

Run: `flutter test test/unit/`
Expected: PASS, salvo los ~6 fallos golden ambientales preexistentes del WIP del lote (documentar cuáles y confirmar que no los introduce este cambio).

- [ ] **Step 4: Verificación en dispositivo (Firebase real, dos perfiles)**

Build de `lib/main.dart` (NO `main_dev`) en Windows; confirmar en `logcat` que NO aparece `Mapping Auth Emulator host`. Luego:

1. **Emulador** (cuenta con teléfono **visible**: `phoneVisibility = sameHomeMembers` + teléfono no vacío) y **MI_9** (cuenta con teléfono **oculto**): abrir el flujo de unión (selector → Añadir hogar → Unirse a un hogar; y/o onboarding con cuenta nueva). Capturar el aviso en cada device:
   - Emulador → "Tu teléfono también será visible para ellos."
   - MI_9 → "Tu teléfono permanece oculto."
2. Completar la unión a un hogar compartido y, **en el otro dispositivo**, comprobar en la lista de miembros que lo que se ve del recién llegado coincide con lo prometido (teléfono visible solo cuando se prometió). Captura.
3. En el selector, tocar "Cambiar" del aviso → debe cerrar el sheet y abrir Editar perfil (`/profile/edit`). Captura.

Guardar capturas en `toka_qa_session/` (redimensionar a ≤1900px antes de adjuntarlas/leerlas).

- [ ] **Step 5: Cerrar el INDICE**

En `Arreglos/ux_hallazgos_2026-06-25/INDICE.md`, fila del hallazgo 09: cambiar estado a `✅ Completado`, fecha `2026-06-27`, y nota de cierre (commits clave + capturas + "UI/copy, sin tocar reglas/backend").

- [ ] **Step 6: Commit del cierre**

```bash
git add Arreglos/ux_hallazgos_2026-06-25/INDICE.md
git commit -m "docs(h09): cierre del hallazgo #09 (transparencia al unirse) en INDICE

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Notas de cierre (para la respuesta final del ejecutor)

- **Archivos nuevos:** `join_privacy_notice.dart` (+ su test), plan y spec en `docs/superpowers/`.
- **Archivos modificados:** 3 ARB + 4 generados l10n, `home_join_form.dart`, `home_choice_step_v2.dart`, `home_choice_step.dart`, `onboarding_flow_screen.dart`, `home_selector_widget.dart`, 2 archivos de test, `INDICE.md`.
- **No marcar DONE** si analyze/tests/verificación en dispositivo no están verdes.
- **Camino QR**: el auto-join al escanear no intercepta el aviso (el banner ya es visible en el modo código previo); es un no-objetivo documentado en la spec, no un fallo.
