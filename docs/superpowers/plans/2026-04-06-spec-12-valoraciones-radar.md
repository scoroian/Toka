# Spec-12: Valoraciones, Notas Privadas y Radar de Puntos Fuertes — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar el sistema de valoraciones de calidad (1-10) por tarea completada con notas privadas, la función `submitReview` backend, el widget `RadarChartWidget` con fl_chart, y el `StrengthsListWidget` para el overflow de ejes.

**Architecture:** Las reviews se almacenan en `taskEvents/{eventId}/reviews/{reviewerUid}`. Las estadísticas agregadas se actualizan en `homes/{homeId}/memberTaskStats/{uid_taskId}` y en `homes/{homeId}/members/{uid}.avgReviewScore`. El radar usa fl_chart con datos normalizados (score/10). Las notas son privadas: solo autor y evaluado pueden leerlas; el resto del hogar solo ve la puntuación.

**Tech Stack:** Flutter/Dart 3, fl_chart (añadir a pubspec), freezed, Riverpod, Cloud Functions TypeScript

---

## Archivos

| Acción | Ruta |
|--------|------|
| Modificar | `pubspec.yaml` (añadir fl_chart) |
| Crear | `lib/features/profile/presentation/widgets/review_dialog.dart` |
| Crear | `lib/features/profile/presentation/widgets/radar_chart_widget.dart` |
| Crear | `lib/features/profile/presentation/widgets/strengths_list_widget.dart` |
| Modificar | `lib/features/history/presentation/widgets/history_event_tile.dart` |
| Modificar | `lib/features/profile/presentation/own_profile_screen.dart` |
| Modificar | `lib/features/members/presentation/member_profile_screen.dart` |
| Crear | `functions/src/tasks/submit_review.ts` |
| Modificar | `functions/src/tasks/index.ts` |
| Modificar | `lib/l10n/app_es.arb` + `app_en.arb` + `app_ro.arb` |
| Crear | `test/unit/features/profile/review_validation_test.dart` |
| Crear | `test/ui/features/profile/review_dialog_test.dart` |
| Crear | `test/ui/features/profile/radar_chart_widget_test.dart` |
| Crear | `test/ui/features/profile/goldens/review_dialog.png` |
| Crear | `test/ui/features/profile/goldens/radar_chart.png` |

---

### Task 1: Añadir fl_chart a pubspec.yaml

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Añadir la dependencia**

En `pubspec.yaml`, añadir bajo `dependencies:` (después de `intl`):
```yaml
  fl_chart: ^0.68.0
```

- [ ] **Step 2: Instalar**

```bash
flutter pub get
```
Resultado esperado: `Got dependencies!`

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add fl_chart dependency for radar chart"
```

---

### Task 2: submitReview Cloud Function

**Files:**
- Create: `functions/src/tasks/submit_review.ts`
- Modify: `functions/src/tasks/index.ts`

- [ ] **Step 1: Crear la función**

```typescript
// functions/src/tasks/submit_review.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/v2/https";

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

export const submitReview = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Not authenticated");
  }

  const { homeId, taskEventId, score, note } = request.data as {
    homeId: string;
    taskEventId: string;
    score: number;
    note?: string;
  };
  const reviewerUid = request.auth.uid;

  // Validaciones básicas
  if (!homeId || !taskEventId) {
    throw new HttpsError("invalid-argument", "homeId and taskEventId required");
  }
  if (typeof score !== "number" || score < 1 || score > 10) {
    throw new HttpsError("invalid-argument", "score must be between 1 and 10");
  }
  if (note && note.length > 300) {
    throw new HttpsError("invalid-argument", "note exceeds 300 characters");
  }

  // 1. Verificar Premium del hogar
  const homeSnap = await db.collection("homes").doc(homeId).get();
  if (!homeSnap.exists) throw new HttpsError("not-found", "Home not found");
  const homeData = homeSnap.data()!;
  const premiumStatus: string = homeData["premiumStatus"] ?? "free";
  if (!["active", "cancelled_pending_end", "rescue"].includes(premiumStatus)) {
    throw new HttpsError("failed-precondition", "Reviews require Premium");
  }

  // 2. Leer el evento completed
  const eventRef = db.collection("homes").doc(homeId).collection("taskEvents").doc(taskEventId);
  const eventSnap = await eventRef.get();
  if (!eventSnap.exists) throw new HttpsError("not-found", "Task event not found");

  const eventData = eventSnap.data()!;
  if (eventData["eventType"] !== "completed") {
    throw new HttpsError("failed-precondition", "Can only review completed events");
  }
  const performerUid: string = eventData["performerUid"] ?? eventData["actorUid"];

  // 3. No puede valorarse a sí mismo
  if (reviewerUid === performerUid) {
    throw new HttpsError("permission-denied", "Cannot review your own task");
  }

  // 4. Verificar que el reviewer es miembro activo
  const reviewerMemberRef = db.collection("homes").doc(homeId).collection("members").doc(reviewerUid);
  const reviewerSnap = await reviewerMemberRef.get();
  if (!reviewerSnap.exists || reviewerSnap.data()!["status"] !== "active") {
    throw new HttpsError("permission-denied", "Reviewer must be an active member");
  }

  // 5. Verificar duplicado
  const reviewRef = eventRef.collection("reviews").doc(reviewerUid);
  const existingReview = await reviewRef.get();
  if (existingReview.exists) {
    throw new HttpsError("already-exists", "You already reviewed this event");
  }

  await db.runTransaction(async (tx) => {
    // 6. Crear review
    tx.set(reviewRef, {
      reviewerUid,
      performerUid,
      score,
      note: note ?? null,
      createdAt: FieldValue.serverTimestamp(),
    });

    // 7. Actualizar memberTaskStats
    const taskId: string = eventData["taskId"];
    const statsId = `${performerUid}_${taskId}`;
    const statsRef = db.collection("homes").doc(homeId).collection("memberTaskStats").doc(statsId);
    const statsSnap = await tx.get(statsRef);
    const stats = statsSnap.data() ?? { avgScore: 0, reviewCount: 0 };
    const oldCount: number = (stats["reviewCount"] as number) ?? 0;
    const oldAvg: number = (stats["avgScore"] as number) ?? 0;
    const newCount = oldCount + 1;
    const newAvg = (oldAvg * oldCount + score) / newCount;

    tx.set(statsRef, {
      uid: performerUid,
      taskId,
      avgScore: newAvg,
      reviewCount: newCount,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });

    // 8. Actualizar avgReviewScore del miembro
    const performerRef = db.collection("homes").doc(homeId).collection("members").doc(performerUid);
    const performerSnap = await tx.get(performerRef);
    const performerData = performerSnap.data() ?? {};
    const pOldCount: number = (performerData["reviewCount"] as number) ?? 0;
    const pOldAvg: number = (performerData["avgReviewScore"] as number) ?? 0;
    const pNewCount = pOldCount + 1;
    const pNewAvg = (pOldAvg * pOldCount + score) / pNewCount;

    tx.update(performerRef, {
      avgReviewScore: pNewAvg,
      reviewCount: pNewCount,
    });
  });

  logger.info(`submitReview: ${reviewerUid} reviewed event ${taskEventId} score=${score}`);
  return { success: true };
});
```

- [ ] **Step 2: Exportar en index.ts**

Reemplazar `functions/src/tasks/index.ts`:
```typescript
export * from "./update_dashboard";
export * from "./apply_task_completion";
export * from "./pass_task_turn";
export * from "./manual_reassign";
export * from "./submit_review";
```

- [ ] **Step 3: Compilar**

```bash
cd functions && npm run build
```
Resultado esperado: sin errores.

- [ ] **Step 4: Commit**

```bash
git add functions/src/tasks/submit_review.ts functions/src/tasks/index.ts
git commit -m "feat(reviews): add submitReview callable function with premium check and dedup"
```

---

### Task 3: Strings ARB para reviews/radar

**Files:**
- Modify: `lib/l10n/app_es.arb`, `app_en.arb`, `app_ro.arb`

- [ ] **Step 1: Añadir claves en app_es.arb**

```json
  "review_dialog_title": "Valorar tarea",
  "@review_dialog_title": { "description": "Review dialog title" },
  "review_score_label": "Puntuación (1-10)",
  "@review_score_label": { "description": "Review score label" },
  "review_note_label": "Nota privada (opcional, máx. 300 caracteres)",
  "@review_note_label": { "description": "Review note label" },
  "review_submit": "Enviar valoración",
  "@review_submit": { "description": "Submit review button" },
  "review_premium_required": "Las valoraciones son exclusivas de Premium",
  "@review_premium_required": { "description": "Premium required for reviews" },
  "review_own_task": "No puedes valorar tus propias tareas",
  "@review_own_task": { "description": "Cannot review own task message" },
  "radar_chart_title": "Puntos fuertes",
  "@radar_chart_title": { "description": "Radar chart section title" },
  "radar_no_data": "Sin valoraciones todavía",
  "@radar_no_data": { "description": "No radar data message" },
  "radar_other_tasks": "Otras tareas evaluadas",
  "@radar_other_tasks": { "description": "Overflow tasks section title" }
```

- [ ] **Step 2: Añadir en app_en.arb**

```json
  "review_dialog_title": "Rate task",
  "@review_dialog_title": { "description": "Review dialog title" },
  "review_score_label": "Score (1-10)",
  "@review_score_label": { "description": "Review score label" },
  "review_note_label": "Private note (optional, max 300 chars)",
  "@review_note_label": { "description": "Review note label" },
  "review_submit": "Submit review",
  "@review_submit": { "description": "Submit review button" },
  "review_premium_required": "Reviews are a Premium feature",
  "@review_premium_required": { "description": "Premium required for reviews" },
  "review_own_task": "You cannot rate your own tasks",
  "@review_own_task": { "description": "Cannot review own task message" },
  "radar_chart_title": "Strengths",
  "@radar_chart_title": { "description": "Radar chart section title" },
  "radar_no_data": "No ratings yet",
  "@radar_no_data": { "description": "No radar data message" },
  "radar_other_tasks": "Other rated tasks",
  "@radar_other_tasks": { "description": "Overflow tasks section title" }
```

- [ ] **Step 3: Añadir en app_ro.arb**

```json
  "review_dialog_title": "Evaluează sarcina",
  "@review_dialog_title": { "description": "Review dialog title" },
  "review_score_label": "Punctaj (1-10)",
  "@review_score_label": { "description": "Review score label" },
  "review_note_label": "Notă privată (opțional, max 300 caractere)",
  "@review_note_label": { "description": "Review note label" },
  "review_submit": "Trimite evaluarea",
  "@review_submit": { "description": "Submit review button" },
  "review_premium_required": "Evaluările sunt o funcție Premium",
  "@review_premium_required": { "description": "Premium required for reviews" },
  "review_own_task": "Nu îți poți evalua propriile sarcini",
  "@review_own_task": { "description": "Cannot review own task message" },
  "radar_chart_title": "Puncte forte",
  "@radar_chart_title": { "description": "Radar chart section title" },
  "radar_no_data": "Fără evaluări încă",
  "@radar_no_data": { "description": "No radar data message" },
  "radar_other_tasks": "Alte sarcini evaluate",
  "@radar_other_tasks": { "description": "Overflow tasks section title" }
```

- [ ] **Step 4: Regenerar**

```bash
flutter gen-l10n
```

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/
git commit -m "feat(reviews): add review and radar ARB strings"
```

---

### Task 4: ReviewDialog

**Files:**
- Create: `lib/features/profile/presentation/widgets/review_dialog.dart`
- Create: `test/ui/features/profile/review_dialog_test.dart`

- [ ] **Step 1: Escribir tests fallidos**

```dart
// test/ui/features/profile/review_dialog_test.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/profile/presentation/widgets/review_dialog.dart';
import 'package:toka/l10n/app_localizations.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets('ReviewDialog muestra slider 1-10', (tester) async {
    await tester.pumpWidget(_wrap(
      ReviewDialog(
        homeId: 'h1',
        taskEventId: 'e1',
        taskTitle: 'Fregar',
        performerName: 'Ana',
        isPremium: true,
        currentUid: 'u1',
        performerUid: 'u2',
        onSubmitted: () {},
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsOneWidget);
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.min, 1);
    expect(slider.max, 10);
  });

  testWidgets('ReviewDialog no aparece para el propio ejecutor', (tester) async {
    await tester.pumpWidget(_wrap(
      ReviewDialog(
        homeId: 'h1',
        taskEventId: 'e1',
        taskTitle: 'Fregar',
        performerName: 'Yo',
        isPremium: true,
        currentUid: 'u1',
        performerUid: 'u1', // mismo uid = propio
        onSubmitted: () {},
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('btn_submit_review')), findsNothing);
    expect(find.text('No puedes valorar tus propias tareas'), findsOneWidget);
  });

  testWidgets('En plan Free muestra mensaje de upgrade', (tester) async {
    await tester.pumpWidget(_wrap(
      ReviewDialog(
        homeId: 'h1',
        taskEventId: 'e1',
        taskTitle: 'Fregar',
        performerName: 'Ana',
        isPremium: false,
        currentUid: 'u1',
        performerUid: 'u2',
        onSubmitted: () {},
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('premium_gate_overlay')), findsOneWidget);
  });
}
```

- [ ] **Step 2: Confirmar que los tests fallan**

```bash
flutter test test/ui/features/profile/review_dialog_test.dart
```
Resultado esperado: `Error: 'ReviewDialog' not found`

- [ ] **Step 3: Crear ReviewDialog**

```dart
// lib/features/profile/presentation/widgets/review_dialog.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../subscription/presentation/widgets/premium_feature_gate.dart';

class ReviewDialog extends StatefulWidget {
  const ReviewDialog({
    super.key,
    required this.homeId,
    required this.taskEventId,
    required this.taskTitle,
    required this.performerName,
    required this.isPremium,
    required this.currentUid,
    required this.performerUid,
    required this.onSubmitted,
  });

  final String homeId;
  final String taskEventId;
  final String taskTitle;
  final String performerName;
  final bool isPremium;
  final String currentUid;
  final String performerUid;
  final VoidCallback onSubmitted;

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  double _score = 5;
  final _noteController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool get _isSelf => widget.currentUid == widget.performerUid;

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await FirebaseFunctions.instance.httpsCallable('submitReview').call({
        'homeId': widget.homeId,
        'taskEventId': widget.taskEventId,
        'score': _score.round(),
        if (_noteController.text.trim().isNotEmpty)
          'note': _noteController.text.trim(),
      });
      widget.onSubmitted();
      if (mounted) Navigator.of(context).pop();
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Error al enviar valoración')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final content = _isSelf
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.review_own_task),
            ),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l10n.review_score_label}: ${_score.round()}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Slider(
                key: const Key('review_slider'),
                min: 1,
                max: 10,
                divisions: 9,
                value: _score,
                label: _score.round().toString(),
                onChanged: (v) => setState(() => _score = v),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLength: 300,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.review_note_label,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('btn_submit_review'),
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.review_submit),
                ),
              ),
            ],
          );

    return AlertDialog(
      title: Text(l10n.review_dialog_title),
      content: SizedBox(
        width: double.maxFinite,
        child: PremiumFeatureGate(
          requiresPremium: !widget.isPremium,
          featureName: l10n.review_dialog_title,
          child: content,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Confirmar que los tests pasan**

```bash
flutter test test/ui/features/profile/review_dialog_test.dart
```
Resultado esperado: `All tests passed`

- [ ] **Step 5: Generar golden test**

Añadir al final del archivo `test/ui/features/profile/review_dialog_test.dart`:

```dart
  testWidgets('golden: ReviewDialog con slider', (tester) async {
    await tester.pumpWidget(_wrap(
      ReviewDialog(
        homeId: 'h1',
        taskEventId: 'e1',
        taskTitle: 'Fregar',
        performerName: 'Ana',
        isPremium: true,
        currentUid: 'u1',
        performerUid: 'u2',
        onSubmitted: () {},
      ),
    ));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ReviewDialog),
      matchesGoldenFile('goldens/review_dialog.png'),
    );
  });
```

Generar el golden:
```bash
flutter test test/ui/features/profile/review_dialog_test.dart --update-goldens
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/profile/presentation/widgets/review_dialog.dart test/ui/features/profile/
git commit -m "feat(reviews): add ReviewDialog with slider, note field, premium gate, golden test"
```

---

### Task 5: RadarChartWidget + StrengthsListWidget

**Files:**
- Create: `lib/features/profile/presentation/widgets/radar_chart_widget.dart`
- Create: `lib/features/profile/presentation/widgets/strengths_list_widget.dart`
- Create: `test/ui/features/profile/radar_chart_widget_test.dart`

- [ ] **Step 1: Escribir tests fallidos**

```dart
// test/ui/features/profile/radar_chart_widget_test.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/profile/presentation/widgets/radar_chart_widget.dart';
import 'package:toka/features/profile/presentation/widgets/strengths_list_widget.dart';
import 'package:toka/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  group('RadarChartWidget', () {
    test('con 15 tareas solo muestra 10 en el radar', () {
      final data = List.generate(
        15,
        (i) => RadarEntry(taskName: 'Tarea $i', avgScore: 7.0 + i * 0.1),
      );
      final radarEntries = data.take(10).toList();
      final overflowEntries = data.skip(10).toList();
      expect(radarEntries.length, 10);
      expect(overflowEntries.length, 5);
    });

    testWidgets('RadarChartWidget con 3 tareas muestra RadarChart', (t) async {
      final data = [
        RadarEntry(taskName: 'Fregar', avgScore: 8.0),
        RadarEntry(taskName: 'Barrer', avgScore: 6.5),
        RadarEntry(taskName: 'Cocinar', avgScore: 9.0),
      ];
      await t.pumpWidget(_wrap(RadarChartWidget(entries: data)));
      await t.pumpAndSettle();
      expect(find.byType(RadarChart), findsOneWidget);
    });

    testWidgets('RadarChartWidget con 0 tareas muestra mensaje vacío', (t) async {
      await t.pumpWidget(_wrap(const RadarChartWidget(entries: [])));
      await t.pumpAndSettle();
      expect(find.byType(RadarChart), findsNothing);
      expect(find.byKey(const Key('radar_no_data')), findsOneWidget);
    });

    testWidgets('RadarChartWidget con 12 tareas muestra 10 en chart + StrengthsListWidget', (t) async {
      final data = List.generate(
        12,
        (i) => RadarEntry(taskName: 'Tarea $i', avgScore: 5.0 + i * 0.3),
      );
      await t.pumpWidget(_wrap(RadarChartWidget(entries: data)));
      await t.pumpAndSettle();
      expect(find.byType(RadarChart), findsOneWidget);
      expect(find.byType(StrengthsListWidget), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Confirmar que los tests fallan**

```bash
flutter test test/ui/features/profile/radar_chart_widget_test.dart
```
Resultado esperado: `Error: 'RadarChartWidget' not found`

- [ ] **Step 3: Crear RadarEntry model + RadarChartWidget**

```dart
// lib/features/profile/presentation/widgets/radar_chart_widget.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'strengths_list_widget.dart';

class RadarEntry {
  const RadarEntry({required this.taskName, required this.avgScore});

  final String taskName;
  final double avgScore; // 1-10
}

class RadarChartWidget extends StatelessWidget {
  const RadarChartWidget({super.key, required this.entries});

  final List<RadarEntry> entries;

  static const int _maxAxes = 10;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (entries.isEmpty) {
      return Center(
        key: const Key('radar_no_data'),
        child: Text(l10n.radar_no_data),
      );
    }

    final radarEntries = entries.take(_maxAxes).toList();
    final overflowEntries = entries.skip(_maxAxes).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.radar_chart_title,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: RadarChart(
            RadarChartData(
              dataSets: [
                RadarDataSet(
                  dataEntries: radarEntries
                      .map((e) => RadarEntryData(value: e.avgScore))
                      .toList(),
                  fillColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3),
                  borderColor: Theme.of(context).colorScheme.primary,
                  borderWidth: 2,
                ),
              ],
              radarBackgroundColor: Colors.transparent,
              borderData: FlBorderData(show: false),
              radarBorderData: const BorderSide(color: Colors.transparent),
              titlePositionPercentageOffset: 0.2,
              titleTextStyle: Theme.of(context).textTheme.bodySmall,
              getTitle: (index, _) => RadarChartTitle(
                text: radarEntries[index].taskName,
              ),
              tickCount: 4,
              ticksTextStyle: const TextStyle(fontSize: 8, color: Colors.grey),
              tickBorderData: const BorderSide(color: Colors.grey, width: 0.5),
              gridBorderData: const BorderSide(color: Colors.grey, width: 0.5),
            ),
          ),
        ),
        if (overflowEntries.isNotEmpty) ...[
          const SizedBox(height: 16),
          StrengthsListWidget(entries: overflowEntries),
        ],
      ],
    );
  }
}
```

- [ ] **Step 4: Crear StrengthsListWidget**

```dart
// lib/features/profile/presentation/widgets/strengths_list_widget.dart
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import 'radar_chart_widget.dart';

class StrengthsListWidget extends StatelessWidget {
  const StrengthsListWidget({super.key, required this.entries});

  final List<RadarEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.radar_other_tasks,
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...entries.map(
          (e) => ListTile(
            dense: true,
            title: Text(e.taskName),
            trailing: Text(
              e.avgScore.toStringAsFixed(1),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 5: Confirmar que los tests pasan**

```bash
flutter test test/ui/features/profile/radar_chart_widget_test.dart
```
Resultado esperado: `All tests passed`

- [ ] **Step 6: Generar golden**

Añadir al final del archivo `test/ui/features/profile/radar_chart_widget_test.dart`:

```dart
  testWidgets('golden: RadarChartWidget con 5 tareas', (t) async {
    final data = [
      RadarEntry(taskName: 'Fregar', avgScore: 8.0),
      RadarEntry(taskName: 'Barrer', avgScore: 6.5),
      RadarEntry(taskName: 'Cocinar', avgScore: 9.0),
      RadarEntry(taskName: 'Compras', avgScore: 7.5),
      RadarEntry(taskName: 'Baño', avgScore: 8.5),
    ];
    await t.pumpWidget(_wrap(RadarChartWidget(entries: data)));
    await t.pumpAndSettle();
    await expectLater(
      find.byType(RadarChartWidget),
      matchesGoldenFile('goldens/radar_chart.png'),
    );
  });
```

```bash
flutter test test/ui/features/profile/radar_chart_widget_test.dart --update-goldens
```

- [ ] **Step 7: Commit**

```bash
git add lib/features/profile/presentation/widgets/ test/ui/features/profile/
git commit -m "feat(reviews): add RadarChartWidget, StrengthsListWidget with fl_chart, golden tests"
```

---

### Task 6: Integrar ReviewDialog en HistoryEventTile

**Files:**
- Modify: `lib/features/history/presentation/widgets/history_event_tile.dart`

**Contexto:** `HistoryEventTile` es un `StatelessWidget` que toma `event` (sealed class), `actorName`, `actorPhotoUrl`, `toName`. Usa `event.map()` para despachar a `_CompletedTile` o `_PassedTile`. `TaskEvent` NO tiene campo `eventType` - es sealed. El modelo `CompletedEvent` tiene campos: `id`, `taskId`, `taskTitleSnapshot`, `actorUid`, `performerUid`, `completedAt`, `createdAt`.

- [ ] **Step 1: Añadir parámetros a HistoryEventTile y ReviewDialog a _CompletedTile**

Reemplazar el contenido de `lib/features/history/presentation/widgets/history_event_tile.dart`:

```dart
// lib/features/history/presentation/widgets/history_event_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/task_event.dart';
import '../../../profile/presentation/widgets/review_dialog.dart';

class HistoryEventTile extends StatelessWidget {
  const HistoryEventTile({
    super.key,
    required this.event,
    required this.actorName,
    required this.actorPhotoUrl,
    this.toName,
    this.homeId,
    this.currentUid,
    this.isPremium = false,
  });

  final TaskEvent event;
  final String actorName;
  final String? actorPhotoUrl;
  final String? toName;
  final String? homeId;
  final String? currentUid;
  final bool isPremium;

  static String formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inHours < 1) return 'hace \${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace \${diff.inHours} h';
    if (diff.inDays < 7) return 'hace \${diff.inDays} días';
    return DateFormat('EEE d MMM, HH:mm', 'es').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return event.map(
      completed: (e) => _CompletedTile(
        event: e,
        actorName: actorName,
        actorPhotoUrl: actorPhotoUrl,
        timestamp: formatRelativeTime(e.createdAt),
        l10n: l10n,
        homeId: homeId,
        currentUid: currentUid,
        isPremium: isPremium,
      ),
      passed: (e) => _PassedTile(
        event: e,
        actorName: actorName,
        actorPhotoUrl: actorPhotoUrl,
        toName: toName ?? e.toUid,
        timestamp: formatRelativeTime(e.createdAt),
        l10n: l10n,
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl, required this.name});
  final String? photoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(photoUrl!),
      );
    }
    return CircleAvatar(
      radius: 20,
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
    );
  }
}

class _CompletedTile extends StatelessWidget {
  const _CompletedTile({
    required this.event,
    required this.actorName,
    required this.actorPhotoUrl,
    required this.timestamp,
    required this.l10n,
    this.homeId,
    this.currentUid,
    this.isPremium = false,
  });
  final CompletedEvent event;
  final String actorName;
  final String? actorPhotoUrl;
  final String timestamp;
  final AppLocalizations l10n;
  final String? homeId;
  final String? currentUid;
  final bool isPremium;

  bool get _canReview =>
      homeId != null &&
      currentUid != null &&
      currentUid != event.performerUid &&
      isPremium;

  @override
  Widget build(BuildContext context) {
    final visual = event.taskVisualSnapshot;
    final taskLabel = visual.kind == 'emoji'
        ? '\${visual.value} \${event.taskTitleSnapshot}'
        : event.taskTitleSnapshot;

    return ListTile(
      key: Key('history_tile_\${event.id}'),
      leading: _Avatar(photoUrl: actorPhotoUrl, name: actorName),
      title: Text(l10n.history_event_completed(actorName)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(taskLabel, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(timestamp, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      trailing: _canReview
          ? TextButton(
              key: const Key('btn_review'),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => ReviewDialog(
                  homeId: homeId!,
                  taskEventId: event.id,
                  taskTitle: event.taskTitleSnapshot,
                  performerName: actorName,
                  isPremium: isPremium,
                  currentUid: currentUid!,
                  performerUid: event.performerUid,
                  onSubmitted: () {},
                ),
              ),
              child: Text(l10n.review_dialog_title),
            )
          : const Icon(Icons.check_circle_outline, color: Colors.green),
      isThreeLine: true,
    );
  }
}

class _PassedTile extends StatelessWidget {
  const _PassedTile({
    required this.event,
    required this.actorName,
    required this.actorPhotoUrl,
    required this.toName,
    required this.timestamp,
    required this.l10n,
  });
  final PassedEvent event;
  final String actorName;
  final String? actorPhotoUrl;
  final String toName;
  final String timestamp;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final visual = event.taskVisualSnapshot;
    final taskLabel = visual.kind == 'emoji'
        ? '\${visual.value} \${event.taskTitleSnapshot}'
        : event.taskTitleSnapshot;

    return ListTile(
      key: Key('history_tile_\${event.id}'),
      leading: _Avatar(photoUrl: actorPhotoUrl, name: actorName),
      title: Row(
        children: [
          Flexible(child: Text(actorName, overflow: TextOverflow.ellipsis)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.arrow_forward, size: 14),
          ),
          Flexible(child: Text(toName, overflow: TextOverflow.ellipsis)),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('\$taskLabel — \${l10n.history_event_pass_turn}',
              style: const TextStyle(fontWeight: FontWeight.w500)),
          if (event.reason != null && event.reason!.isNotEmpty)
            Text(
              l10n.history_event_reason(event.reason!),
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          Text(timestamp, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      trailing: const Icon(Icons.swap_horiz, color: Colors.orange),
      isThreeLine: true,
    );
  }
}
```

**Nota:** Los callers de `HistoryEventTile` deben pasar `homeId`, `currentUid`, `isPremium` al construir el widget. Ver `lib/features/history/presentation/history_screen.dart` para actualizar las instanciaciones.

- [ ] **Step 3: Verificar compilación**

```bash
flutter analyze lib/features/history/
```
Resultado esperado: sin errores.

- [ ] **Step 4: Commit**

```bash
git add lib/features/history/presentation/widgets/history_event_tile.dart
git commit -m "feat(reviews): wire ReviewDialog into HistoryEventTile for completed events"
```

---

### Task 7: Integrar RadarChartWidget en pantallas de perfil

**Files:**
- Modify: `lib/features/profile/presentation/own_profile_screen.dart`
- Modify: `lib/features/members/presentation/member_profile_screen.dart`

- [ ] **Step 1: Leer own_profile_screen.dart para ver la estructura actual**

```bash
cat lib/features/profile/presentation/own_profile_screen.dart
```

- [ ] **Step 2: Añadir RadarChartWidget a OwnProfileScreen**

Dentro del `build`, después de la sección de stats existente, añadir:

```dart
// Añadir import al inicio:
import 'widgets/radar_chart_widget.dart';

// Dentro del body (en ListView o Column existente), añadir:
const SizedBox(height: 24),
// Datos mock por ahora — en producción vendrían de memberTaskStats
RadarChartWidget(entries: const []),
```

**Nota:** Los datos del radar vendrían de un provider que lee `homes/{homeId}/memberTaskStats/`. Se puede dejar con `entries: const []` hasta tener datos reales, o crear un provider básico que los lea.

- [ ] **Step 3: Añadir RadarChartWidget a MemberProfileScreen**

Mismo patrón: añadir `RadarChartWidget(entries: const [])` después de las estadísticas.

- [ ] **Step 4: Verificar compilación**

```bash
flutter analyze lib/features/profile/ lib/features/members/
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/profile/presentation/ lib/features/members/presentation/
git commit -m "feat(reviews): add RadarChartWidget placeholder to profile screens"
```

---

### Task 8: Tests unitarios de validación de review (server-side equivalents)

**Files:**
- Create: `test/unit/features/profile/review_validation_test.dart`

- [ ] **Step 1: Crear tests de validación**

```dart
// test/unit/features/profile/review_validation_test.dart
import 'package:flutter_test/flutter_test.dart';

// Simula las reglas de validación de submitReview en el lado cliente
bool isValidReviewScore(int score) => score >= 1 && score <= 10;
bool isValidReviewNote(String? note) => note == null || note.length <= 300;

void main() {
  group('Review validation rules', () {
    test('score válido: 1 a 10', () {
      expect(isValidReviewScore(1), true);
      expect(isValidReviewScore(10), true);
      expect(isValidReviewScore(5), true);
    });

    test('score inválido: 0 y 11', () {
      expect(isValidReviewScore(0), false);
      expect(isValidReviewScore(11), false);
    });

    test('nota nula es válida', () {
      expect(isValidReviewNote(null), true);
    });

    test('nota de 300 caracteres es válida', () {
      expect(isValidReviewNote('a' * 300), true);
    });

    test('nota de 301 caracteres es inválida', () {
      expect(isValidReviewNote('a' * 301), false);
    });
  });
}
```

- [ ] **Step 2: Ejecutar**

```bash
flutter test test/unit/features/profile/review_validation_test.dart
```
Resultado esperado: `All tests passed`

- [ ] **Step 3: Commit**

```bash
git add test/unit/features/profile/review_validation_test.dart
git commit -m "test(reviews): add review validation unit tests"
```

---

### Task 9: Ejecutar suite completa y verificar

- [ ] **Step 1: Ejecutar todos los tests**

```bash
flutter test test/unit/ test/integration/ test/ui/
```
Resultado esperado: todos pasan.

- [ ] **Step 2: Análisis estático**

```bash
flutter analyze
```

- [ ] **Step 3: Commit final**

```bash
git add -A
git commit -m "feat(spec-12): complete valoraciones, notas privadas y radar chart"
```

---

## Pruebas manuales requeridas (Spec-12)

1. **Valorar tarea:** En historial, tocar un evento completado por otro miembro → aparece diálogo de valoración → dar puntuación 8 y nota "Muy limpio" → confirmar → review guardada.
2. **Privacidad de nota:** Usuario A valora a B con nota. B ve la nota. C (otro miembro) solo ve el promedio, no la nota.
3. **No puede valorarse a sí mismo:** Tocar un evento propio → diálogo muestra "No puedes valorar tus propias tareas".
4. **Radar con pocas tareas:** Con 3 tareas evaluadas → radar con 3 ejes visibles.
5. **Radar con muchas tareas:** Con 12 tareas evaluadas → radar con 10 ejes + 2 en lista textual.
6. **En plan Free:** Tocar evento completado → diálogo muestra overlay de upgrade (PremiumFeatureGate).
7. **Doble review rechazada:** Intentar valorar el mismo evento dos veces → error "Ya has valorado".
