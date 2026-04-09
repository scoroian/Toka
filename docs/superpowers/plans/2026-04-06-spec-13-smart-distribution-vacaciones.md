# Spec-13: Smart Distribution + Vacaciones — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar `SmartAssignmentCalculator` para asignación ponderada por carga, el modelo `Vacation` para excluir miembros ausentes de la rotación, la pantalla `VacationScreen`, y la función `manualReassign` para que admins reasignen manualmente con auditoría.

**Architecture:** `SmartAssignmentCalculator` es una utilidad pura en Dart (testable sin Flutter). Las vacaciones se almacenan como campo `vacation` embebido en `homes/{homeId}/members/{uid}`; cuando se activan, se cambia `status = 'absent'` en el mismo documento. El backend ya filtra `absent` en `pass_task_turn`; se actualizará `apply_task_completion` para hacer lo mismo y soporte de `distributionMode = 'smart'`.

**Tech Stack:** Flutter/Dart 3, freezed, Riverpod, Cloud Functions TypeScript, Firestore

---

## Archivos

| Acción | Ruta |
|--------|------|
| Crear | `lib/core/utils/smart_assignment_calculator.dart` |
| Crear | `lib/features/members/domain/vacation.dart` |
| Crear | `lib/features/members/application/vacation_provider.dart` |
| Crear | `lib/features/members/presentation/vacation_screen.dart` |
| Crear | `functions/src/tasks/manual_reassign.ts` |
| Modificar | `lib/features/members/domain/members_repository.dart` |
| Modificar | `lib/features/members/data/members_repository_impl.dart` |
| Modificar | `functions/src/tasks/apply_task_completion.ts` |
| Modificar | `functions/src/tasks/index.ts` |
| Modificar | `lib/core/constants/routes.dart` |
| Modificar | `lib/app.dart` |
| Modificar | `lib/l10n/app_es.arb` + `app_en.arb` + `app_ro.arb` |
| Crear | `test/unit/features/tasks/smart_assignment_calculator_test.dart` |
| Crear | `test/unit/features/members/vacation_test.dart` |
| Crear | `test/integration/features/members/vacation_integration_test.dart` |
| Crear | `test/ui/features/members/vacation_screen_test.dart` |

---

### Task 1: SmartAssignmentCalculator

**Files:**
- Create: `lib/core/utils/smart_assignment_calculator.dart`
- Create: `test/unit/features/tasks/smart_assignment_calculator_test.dart`

- [ ] **Step 1: Escribir tests fallidos**

```dart
// test/unit/features/tasks/smart_assignment_calculator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/core/utils/smart_assignment_calculator.dart';

void main() {
  MemberLoadData load({int completions = 0, double weight = 1.0, int days = 0}) =>
      MemberLoadData(completionsRecent: completions, difficultyWeight: weight, daysSinceLastExecution: days);

  group('SmartAssignmentCalculator.selectNextAssignee', () {
    test('selecciona al menos cargado (menos completions)', () {
      final loadData = {
        'A': load(completions: 10),
        'B': load(completions: 2),
        'C': load(completions: 7),
      };
      final result = SmartAssignmentCalculator.selectNextAssignee(
        order: ['A', 'B', 'C'],
        currentUid: 'A',
        loadData: loadData,
        frozenUids: [],
        absentUids: [],
      );
      expect(result, 'B');
    });

    test('excluye miembros ausentes', () {
      final loadData = {
        'A': load(completions: 0),
        'B': load(completions: 0),
        'C': load(completions: 0),
      };
      final result = SmartAssignmentCalculator.selectNextAssignee(
        order: ['A', 'B', 'C'],
        currentUid: 'A',
        loadData: loadData,
        frozenUids: [],
        absentUids: ['B'],
      );
      expect(result, isNot('B'));
    });

    test('excluye miembros congelados', () {
      final loadData = {
        'A': load(completions: 5),
        'B': load(completions: 1),
        'C': load(completions: 3),
      };
      final result = SmartAssignmentCalculator.selectNextAssignee(
        order: ['A', 'B', 'C'],
        currentUid: 'A',
        loadData: loadData,
        frozenUids: ['B'],
        absentUids: [],
      );
      expect(result, 'C');
    });

    test('con todos ausentes/congelados: retorna currentUid', () {
      final loadData = {'A': load(), 'B': load(), 'C': load()};
      final result = SmartAssignmentCalculator.selectNextAssignee(
        order: ['A', 'B', 'C'],
        currentUid: 'A',
        loadData: loadData,
        frozenUids: ['B', 'C'],
        absentUids: [],
      );
      expect(result, 'A');
    });

    test('prioriza mayor daysSinceLastExecution cuando completions igual', () {
      final loadData = {
        'A': load(completions: 5, days: 1),
        'B': load(completions: 5, days: 10), // más días sin hacer → menor score
      };
      final result = SmartAssignmentCalculator.selectNextAssignee(
        order: ['A', 'B'],
        currentUid: 'A',
        loadData: loadData,
        frozenUids: [],
        absentUids: [],
      );
      expect(result, 'B');
    });
  });
}
```

- [ ] **Step 2: Confirmar que los tests fallan**

```bash
flutter test test/unit/features/tasks/smart_assignment_calculator_test.dart
```
Resultado esperado: `Error: uri 'package:toka/core/utils/smart_assignment_calculator.dart' doesn't exist`

- [ ] **Step 3: Implementar SmartAssignmentCalculator**

```dart
// lib/core/utils/smart_assignment_calculator.dart

class MemberLoadData {
  const MemberLoadData({
    required this.completionsRecent,
    required this.difficultyWeight,
    required this.daysSinceLastExecution,
  });

  final int completionsRecent;
  final double difficultyWeight;
  final int daysSinceLastExecution;
}

abstract class SmartAssignmentCalculator {
  /// Selecciona el siguiente asignado basándose en carga reciente.
  /// score = completionsRecent * difficultyWeight + daysSinceLastExecution * -0.1
  /// Menor score = más prioritario.
  static String selectNextAssignee({
    required List<String> order,
    required String currentUid,
    required Map<String, MemberLoadData> loadData,
    required List<String> frozenUids,
    required List<String> absentUids,
  }) {
    final eligible = order
        .where((uid) => !frozenUids.contains(uid) && !absentUids.contains(uid))
        .toList();

    if (eligible.isEmpty) return currentUid;

    return eligible.reduce((a, b) => _score(loadData[a]) <= _score(loadData[b]) ? a : b);
  }

  static double _score(MemberLoadData? data) {
    if (data == null) return 0.0;
    return data.completionsRecent * data.difficultyWeight +
        data.daysSinceLastExecution * -0.1;
  }
}
```

- [ ] **Step 4: Confirmar que los tests pasan**

```bash
flutter test test/unit/features/tasks/smart_assignment_calculator_test.dart
```
Resultado esperado: `All tests passed`

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils/smart_assignment_calculator.dart test/unit/features/tasks/smart_assignment_calculator_test.dart
git commit -m "feat(tasks): add SmartAssignmentCalculator with load-based scoring"
```

---

### Task 2: Vacation model (freezed)

**Files:**
- Create: `lib/features/members/domain/vacation.dart`
- Create: `test/unit/features/members/vacation_test.dart`

- [ ] **Step 1: Escribir tests fallidos**

```dart
// test/unit/features/members/vacation_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/members/domain/vacation.dart';

void main() {
  group('Vacation.isAbsent', () {
    test('isActive false → isAbsent false', () {
      final v = Vacation(
        uid: 'u1', homeId: 'h1',
        isActive: false,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(v.isAbsent, false);
    });

    test('isActive true sin rango de fechas → isAbsent true', () {
      final v = Vacation(
        uid: 'u1', homeId: 'h1',
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(v.isAbsent, true);
    });

    test('isActive true, fecha actual en rango → isAbsent true', () {
      final now = DateTime.now();
      final v = Vacation(
        uid: 'u1', homeId: 'h1',
        isActive: true,
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 1)),
        createdAt: DateTime(2026, 1, 1),
      );
      expect(v.isAbsent, true);
    });

    test('isActive true, endDate ya pasó → isAbsent false', () {
      final now = DateTime.now();
      final v = Vacation(
        uid: 'u1', homeId: 'h1',
        isActive: true,
        endDate: now.subtract(const Duration(days: 1)),
        createdAt: DateTime(2026, 1, 1),
      );
      expect(v.isAbsent, false);
    });

    test('isActive true, startDate en el futuro → isAbsent false', () {
      final now = DateTime.now();
      final v = Vacation(
        uid: 'u1', homeId: 'h1',
        isActive: true,
        startDate: now.add(const Duration(days: 2)),
        createdAt: DateTime(2026, 1, 1),
      );
      expect(v.isAbsent, false);
    });
  });
}
```

- [ ] **Step 2: Confirmar que los tests fallan**

```bash
flutter test test/unit/features/members/vacation_test.dart
```
Resultado esperado: `Error: 'Vacation' not found`

- [ ] **Step 3: Crear el modelo Vacation**

```dart
// lib/features/members/domain/vacation.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'vacation.freezed.dart';

@freezed
class Vacation with _$Vacation {
  const factory Vacation({
    required String uid,
    required String homeId,
    DateTime? startDate,
    DateTime? endDate,
    @Default(false) bool isActive,
    String? reason,
    required DateTime createdAt,
  }) = _Vacation;

  const Vacation._();

  bool get isAbsent {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  factory Vacation.fromMap(String uid, String homeId, Map<String, dynamic> map) {
    return Vacation(
      uid: uid,
      homeId: homeId,
      isActive: map['isActive'] as bool? ?? false,
      startDate: (map['startDate'] as Timestamp?)?.toDate(),
      endDate: (map['endDate'] as Timestamp?)?.toDate(),
      reason: map['reason'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'isActive': isActive,
    'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
    'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    'reason': reason,
    'createdAt': createdAt != null ? Timestamp.fromDate(createdAt) : FieldValue.serverTimestamp(),
  };
}
```

- [ ] **Step 4: Generar código freezed**

```bash
dart run build_runner build --delete-conflicting-outputs
```
Resultado esperado: `vacation.freezed.dart` generado sin errores.

- [ ] **Step 5: Confirmar que los tests pasan**

```bash
flutter test test/unit/features/members/vacation_test.dart
```
Resultado esperado: `All tests passed`

- [ ] **Step 6: Commit**

```bash
git add lib/features/members/domain/vacation.dart lib/features/members/domain/vacation.freezed.dart test/unit/features/members/vacation_test.dart
git commit -m "feat(members): add Vacation model with isAbsent computed property"
```

---

### Task 3: Vacation Repository (interfaz + implementación)

**Files:**
- Modify: `lib/features/members/domain/members_repository.dart`
- Modify: `lib/features/members/data/members_repository_impl.dart`

- [ ] **Step 1: Extender la interfaz del repositorio**

Añadir al final de `lib/features/members/domain/members_repository.dart`:

```dart
// Añadir al import y a la interfaz abstracta:
import 'vacation.dart';

// Dentro del abstract interface class MembersRepository:

  /// Actualiza los datos de vacaciones del miembro autenticado.
  Future<void> saveVacation(String homeId, String uid, Vacation vacation);

  /// Stream de los datos de vacaciones del miembro.
  Stream<Vacation?> watchVacation(String homeId, String uid);
```

El archivo completo modificado queda:
```dart
import '../../../core/errors/exceptions.dart';
import 'member.dart';
import 'vacation.dart';

export '../../../core/errors/exceptions.dart'
    show
        MaxMembersReachedException,
        MaxAdminsReachedException,
        CannotRemoveOwnerException;

abstract interface class MembersRepository {
  Stream<List<Member>> watchHomeMembers(String homeId);
  Future<Member> fetchMember(String homeId, String uid);
  Future<void> inviteMember(String homeId, String? email);
  Future<String> generateInviteCode(String homeId);
  Future<void> removeMember(String homeId, String uid);
  Future<void> promoteToAdmin(String homeId, String uid);
  Future<void> demoteFromAdmin(String homeId, String uid);
  Future<void> transferOwnership(String homeId, String newOwnerUid);
  Future<void> saveVacation(String homeId, String uid, Vacation vacation);
  Stream<Vacation?> watchVacation(String homeId, String uid);
}
```

- [ ] **Step 2: Implementar en MembersRepositoryImpl**

Añadir al final de `lib/features/members/data/members_repository_impl.dart`:

```dart
// Añadir import al inicio del archivo:
import '../domain/vacation.dart';

// Añadir los métodos dentro de la clase MembersRepositoryImpl:

  @override
  Future<void> saveVacation(String homeId, String uid, Vacation vacation) async {
    final memberRef = _firestore
        .collection('homes')
        .doc(homeId)
        .collection('members')
        .doc(uid);

    // Actualizar campo `vacation` embebido + status del miembro
    await memberRef.update({
      'vacation': vacation.toMap(),
      'status': vacation.isAbsent ? 'absent' : 'active',
    });
  }

  @override
  Stream<Vacation?> watchVacation(String homeId, String uid) {
    return _firestore
        .collection('homes')
        .doc(homeId)
        .collection('members')
        .doc(uid)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return null;
      final data = snap.data()!;
      final vacMap = data['vacation'] as Map<String, dynamic>?;
      if (vacMap == null) return null;
      return Vacation.fromMap(uid, homeId, vacMap);
    });
  }
```

- [ ] **Step 3: Verificar compilación**

```bash
flutter analyze lib/features/members/
```
Resultado esperado: sin errores.

- [ ] **Step 4: Commit**

```bash
git add lib/features/members/domain/members_repository.dart lib/features/members/data/members_repository_impl.dart
git commit -m "feat(members): extend MembersRepository with vacation save/watch methods"
```

---

### Task 4: VacationProvider

**Files:**
- Create: `lib/features/members/application/vacation_provider.dart`

- [ ] **Step 1: Crear el provider**

```dart
// lib/features/members/application/vacation_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../features/auth/application/auth_provider.dart';
import '../data/members_repository_impl.dart';
import '../domain/vacation.dart';
import 'members_provider.dart';

part 'vacation_provider.g.dart';

@riverpod
Stream<Vacation?> memberVacation(
  MemberVacationRef ref, {
  required String homeId,
  required String uid,
}) {
  return ref.watch(membersRepositoryProvider).watchVacation(homeId, uid);
}

@riverpod
class VacationNotifier extends _$VacationNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> save(String homeId, String uid, Vacation vacation) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(membersRepositoryProvider).saveVacation(homeId, uid, vacation);
    });
  }
}
```

- [ ] **Step 2: Generar código Riverpod**

```bash
dart run build_runner build --delete-conflicting-outputs
```
Resultado esperado: `vacation_provider.g.dart` generado.

- [ ] **Step 3: Commit**

```bash
git add lib/features/members/application/vacation_provider.dart lib/features/members/application/vacation_provider.g.dart
git commit -m "feat(members): add VacationProvider with stream and save notifier"
```

---

### Task 5: Strings ARB + Rutas

**Files:**
- Modify: `lib/l10n/app_es.arb`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_ro.arb`
- Modify: `lib/core/constants/routes.dart`
- Modify: `lib/app.dart`

- [ ] **Step 1: Añadir claves ARB en app_es.arb**

Añadir al final (antes del cierre `}`):
```json
  "vacation_title": "Vacaciones / Ausencia",
  "@vacation_title": { "description": "Vacation screen title" },
  "vacation_toggle_label": "Estoy de vacaciones / ausente",
  "@vacation_toggle_label": { "description": "Vacation toggle label" },
  "vacation_start_date": "Fecha de inicio (opcional)",
  "@vacation_start_date": { "description": "Vacation start date label" },
  "vacation_end_date": "Fecha de fin (opcional)",
  "@vacation_end_date": { "description": "Vacation end date label" },
  "vacation_reason": "Motivo (opcional)",
  "@vacation_reason": { "description": "Vacation reason label" },
  "vacation_save": "Guardar cambios",
  "@vacation_save": { "description": "Save vacation button" },
  "vacation_chip_until": "De vacaciones hasta {date}",
  "@vacation_chip_until": {
    "description": "Vacation chip with end date",
    "placeholders": { "date": { "type": "String" } }
  },
  "vacation_chip_indefinite": "De vacaciones",
  "@vacation_chip_indefinite": { "description": "Vacation chip without end date" }
```

- [ ] **Step 2: Añadir las mismas claves en app_en.arb**

```json
  "vacation_title": "Vacation / Absence",
  "@vacation_title": { "description": "Vacation screen title" },
  "vacation_toggle_label": "I'm on vacation / absent",
  "@vacation_toggle_label": { "description": "Vacation toggle label" },
  "vacation_start_date": "Start date (optional)",
  "@vacation_start_date": { "description": "Vacation start date label" },
  "vacation_end_date": "End date (optional)",
  "@vacation_end_date": { "description": "Vacation end date label" },
  "vacation_reason": "Reason (optional)",
  "@vacation_reason": { "description": "Vacation reason label" },
  "vacation_save": "Save changes",
  "@vacation_save": { "description": "Save vacation button" },
  "vacation_chip_until": "On vacation until {date}",
  "@vacation_chip_until": {
    "description": "Vacation chip with end date",
    "placeholders": { "date": { "type": "String" } }
  },
  "vacation_chip_indefinite": "On vacation",
  "@vacation_chip_indefinite": { "description": "Vacation chip without end date" }
```

- [ ] **Step 3: Añadir las mismas claves en app_ro.arb**

```json
  "vacation_title": "Concediu / Absență",
  "@vacation_title": { "description": "Vacation screen title" },
  "vacation_toggle_label": "Sunt în concediu / absent",
  "@vacation_toggle_label": { "description": "Vacation toggle label" },
  "vacation_start_date": "Data de început (opțional)",
  "@vacation_start_date": { "description": "Vacation start date label" },
  "vacation_end_date": "Data de sfârșit (opțional)",
  "@vacation_end_date": { "description": "Vacation end date label" },
  "vacation_reason": "Motiv (opțional)",
  "@vacation_reason": { "description": "Vacation reason label" },
  "vacation_save": "Salvează modificările",
  "@vacation_save": { "description": "Save vacation button" },
  "vacation_chip_until": "În concediu până pe {date}",
  "@vacation_chip_until": {
    "description": "Vacation chip with end date",
    "placeholders": { "date": { "type": "String" } }
  },
  "vacation_chip_indefinite": "În concediu",
  "@vacation_chip_indefinite": { "description": "Vacation chip without end date" }
```

- [ ] **Step 4: Añadir ruta en routes.dart**

Añadir en `lib/core/constants/routes.dart`:
```dart
  static const String vacation = '/vacation';
```
Y añadir `vacation` a la lista `all`.

- [ ] **Step 5: Registrar ruta en app.dart**

Añadir import:
```dart
import 'features/members/presentation/vacation_screen.dart';
```

Añadir dentro del router (después de la ruta de `memberProfile`):
```dart
GoRoute(
  path: AppRoutes.vacation,
  builder: (_, __) => const VacationScreen(),
),
```

- [ ] **Step 6: Regenerar localización**

```bash
flutter gen-l10n
```

- [ ] **Step 7: Commit**

```bash
git add lib/l10n/ lib/core/constants/routes.dart lib/app.dart
git commit -m "feat(members): add vacation ARB strings and route"
```

---

### Task 6: VacationScreen

**Files:**
- Create: `lib/features/members/presentation/vacation_screen.dart`
- Create: `test/ui/features/members/vacation_screen_test.dart`

- [ ] **Step 1: Escribir test UI fallido**

```dart
// test/ui/features/members/vacation_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/members/application/vacation_provider.dart';
import 'package:toka/features/members/domain/vacation.dart';
import 'package:toka/features/members/presentation/vacation_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

class MockVacationNotifier extends AutoDisposeNotifier<AsyncValue<void>>
    with Mock
    implements VacationNotifier {}

void main() {
  testWidgets('VacationScreen muestra toggle de vacaciones', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          memberVacationProvider(homeId: 'h1', uid: 'u1')
              .overrideWith((_) => Stream.value(null)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const VacationScreen(homeId: 'h1', uid: 'u1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SwitchListTile), findsOneWidget);
  });

  testWidgets('Toggle activo muestra selectores de fecha', (tester) async {
    final activeVacation = Vacation(
      uid: 'u1',
      homeId: 'h1',
      isActive: true,
      createdAt: DateTime(2026, 1, 1),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          memberVacationProvider(homeId: 'h1', uid: 'u1')
              .overrideWith((_) => Stream.value(activeVacation)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const VacationScreen(homeId: 'h1', uid: 'u1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('vacation_date_pickers')), findsOneWidget);
  });
}
```

- [ ] **Step 2: Confirmar que el test falla**

```bash
flutter test test/ui/features/members/vacation_screen_test.dart
```
Resultado esperado: `Error: 'VacationScreen' not found`

- [ ] **Step 3: Crear VacationScreen**

```dart
// lib/features/members/presentation/vacation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../application/vacation_provider.dart';
import '../domain/vacation.dart';

class VacationScreen extends ConsumerStatefulWidget {
  const VacationScreen({super.key, required this.homeId, required this.uid});

  final String homeId;
  final String uid;

  @override
  ConsumerState<VacationScreen> createState() => _VacationScreenState();
}

class _VacationScreenState extends ConsumerState<VacationScreen> {
  bool _isActive = false;
  DateTime? _startDate;
  DateTime? _endDate;
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _initFromVacation(Vacation? v) {
    if (v == null) return;
    _isActive = v.isActive;
    _startDate = v.startDate;
    _endDate = v.endDate;
    _reasonController.text = v.reason ?? '';
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _save() async {
    final vacation = Vacation(
      uid: widget.uid,
      homeId: widget.homeId,
      isActive: _isActive,
      startDate: _startDate,
      endDate: _endDate,
      reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
      createdAt: DateTime.now(),
    );
    await ref.read(vacationNotifierProvider.notifier).save(widget.homeId, widget.uid, vacation);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt = DateFormat.yMd();

    ref.watch(memberVacationProvider(homeId: widget.homeId, uid: widget.uid)).whenData(
      (v) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) => _initFromVacation(v));
      },
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.vacation_title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            key: const Key('vacation_toggle'),
            title: Text(l10n.vacation_toggle_label),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
          if (_isActive)
            Column(
              key: const Key('vacation_date_pickers'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(l10n.vacation_start_date),
                  subtitle: Text(_startDate != null ? fmt.format(_startDate!) : '—'),
                  onTap: () => _pickDate(true),
                ),
                ListTile(
                  leading: const Icon(Icons.event_available),
                  title: Text(l10n.vacation_end_date),
                  subtitle: Text(_endDate != null ? fmt.format(_endDate!) : '—'),
                  onTap: () => _pickDate(false),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: l10n.vacation_reason,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('btn_save_vacation'),
            onPressed: _save,
            child: Text(l10n.vacation_save),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Confirmar que los tests pasan**

```bash
flutter test test/ui/features/members/vacation_screen_test.dart
```
Resultado esperado: `All tests passed`

- [ ] **Step 5: Commit**

```bash
git add lib/features/members/presentation/vacation_screen.dart test/ui/features/members/vacation_screen_test.dart
git commit -m "feat(members): add VacationScreen with toggle, date pickers, reason field"
```

---

### Task 7: manualReassign Cloud Function

**Files:**
- Create: `functions/src/tasks/manual_reassign.ts`
- Modify: `functions/src/tasks/index.ts`

- [ ] **Step 1: Crear la función**

```typescript
// functions/src/tasks/manual_reassign.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { updateHomeDashboard } from "./update_dashboard";

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

export const manualReassign = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Not authenticated");
  }

  const { homeId, taskId, newAssigneeUid, reason } = request.data as {
    homeId: string;
    taskId: string;
    newAssigneeUid: string;
    reason?: string;
  };
  const callerUid = request.auth.uid;

  if (!homeId || !taskId || !newAssigneeUid) {
    throw new HttpsError("invalid-argument", "homeId, taskId, newAssigneeUid required");
  }

  // Validar que el caller es admin u owner
  const callerRef = db.collection("homes").doc(homeId).collection("members").doc(callerUid);
  const callerSnap = await callerRef.get();
  if (!callerSnap.exists) {
    throw new HttpsError("permission-denied", "Not a member of this home");
  }
  const callerRole = callerSnap.data()!["role"] as string;
  if (callerRole !== "admin" && callerRole !== "owner") {
    throw new HttpsError("permission-denied", "Only admins can manually reassign");
  }

  await db.runTransaction(async (tx) => {
    const taskRef = db.collection("homes").doc(homeId).collection("tasks").doc(taskId);
    const taskSnap = await tx.get(taskRef);
    if (!taskSnap.exists) throw new HttpsError("not-found", "Task not found");

    const task = taskSnap.data()!;
    const previousUid = task["currentAssigneeUid"] as string;

    // Evento auditable
    const eventRef = db.collection("homes").doc(homeId).collection("taskEvents").doc();
    tx.set(eventRef, {
      eventType: "manual_reassign",
      taskId,
      taskTitleSnapshot: task["title"] ?? "",
      taskVisualSnapshot: {
        kind: task["visualKind"] ?? "emoji",
        value: task["visualValue"] ?? "",
      },
      actorUid: callerUid,
      fromUid: previousUid,
      toUid: newAssigneeUid,
      reason: reason ?? null,
      createdAt: FieldValue.serverTimestamp(),
    });

    tx.update(taskRef, {
      currentAssigneeUid: newAssigneeUid,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  logger.info(`manualReassign: task ${taskId} reassigned from ... to ${newAssigneeUid} by ${callerUid}`);
  updateHomeDashboard(homeId).catch((err) =>
    logger.error("Dashboard update failed after manual reassign", err)
  );

  return { success: true };
});
```

- [ ] **Step 2: Exportar desde index.ts**

Reemplazar el contenido de `functions/src/tasks/index.ts`:
```typescript
export * from "./update_dashboard";
export * from "./apply_task_completion";
export * from "./pass_task_turn";
export * from "./manual_reassign";
```

- [ ] **Step 3: Verificar compilación TypeScript**

```bash
cd functions && npm run build
```
Resultado esperado: sin errores de TypeScript.

- [ ] **Step 4: Commit**

```bash
git add functions/src/tasks/manual_reassign.ts functions/src/tasks/index.ts
git commit -m "feat(tasks): add manualReassign callable function with audit event"
```

---

### Task 8: Actualizar apply_task_completion para excluir ausentes

**Files:**
- Modify: `functions/src/tasks/apply_task_completion.ts`

- [ ] **Step 1: Actualizar getNextAssigneeTs para excluir ausentes y soportar smart**

Reemplazar el contenido de `functions/src/tasks/apply_task_completion.ts`:

```typescript
// functions/src/tasks/apply_task_completion.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { updateHomeDashboard } from "./update_dashboard";

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

interface MemberLoadData {
  completionsRecent: number;
  difficultyWeight: number;
  daysSinceLastExecution: number;
}

function scoreOf(data: MemberLoadData): number {
  return data.completionsRecent * data.difficultyWeight + data.daysSinceLastExecution * -0.1;
}

function getNextAssigneeRoundRobin(
  order: string[],
  currentUid: string,
  excludedUids: string[]
): string | null {
  if (!order.length) return null;
  const eligible = order.filter((uid) => !excludedUids.includes(uid));
  if (!eligible.length) return currentUid;
  const idx = eligible.indexOf(currentUid);
  const nextIdx = (idx + 1) % eligible.length;
  return eligible[nextIdx];
}

function getNextAssigneeSmart(
  order: string[],
  currentUid: string,
  excludedUids: string[],
  loadData: Map<string, MemberLoadData>
): string {
  const eligible = order.filter((uid) => !excludedUids.includes(uid));
  if (!eligible.length) return currentUid;
  return eligible.reduce((a, b) => {
    const aData = loadData.get(a) ?? { completionsRecent: 0, difficultyWeight: 1.0, daysSinceLastExecution: 0 };
    const bData = loadData.get(b) ?? { completionsRecent: 0, difficultyWeight: 1.0, daysSinceLastExecution: 0 };
    return scoreOf(aData) <= scoreOf(bData) ? a : b;
  });
}

function addRecurrenceInterval(base: Date, recurrenceType: string): Date {
  const d = new Date(base);
  switch (recurrenceType) {
    case "hourly":  d.setHours(d.getHours() + 1); break;
    case "daily":   d.setDate(d.getDate() + 1); break;
    case "weekly":  d.setDate(d.getDate() + 7); break;
    case "monthly": d.setMonth(d.getMonth() + 1); break;
    case "yearly":  d.setFullYear(d.getFullYear() + 1); break;
  }
  return d;
}

export const applyTaskCompletion = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Not authenticated");
  }

  const { homeId, taskId } = request.data as { homeId: string; taskId: string };
  const uid = request.auth.uid;

  if (!homeId || !taskId) {
    throw new HttpsError("invalid-argument", "homeId and taskId are required");
  }

  const result = await db.runTransaction(async (tx) => {
    const taskRef = db.collection("homes").doc(homeId).collection("tasks").doc(taskId);
    const taskSnap = await tx.get(taskRef);
    if (!taskSnap.exists) throw new HttpsError("not-found", "Task not found");

    const task = taskSnap.data()!;
    if (task["currentAssigneeUid"] !== uid) {
      throw new HttpsError("permission-denied", "Not your turn");
    }
    if (task["status"] !== "active") {
      throw new HttpsError("failed-precondition", "Task not active");
    }

    // Leer miembros para conocer excluidos (frozen + absent)
    const membersSnap = await tx.get(
      db.collection("homes").doc(homeId).collection("members")
    );
    const excludedUids: string[] = [];
    const loadDataMap = new Map<string, MemberLoadData>();

    for (const mDoc of membersSnap.docs) {
      const mData = mDoc.data();
      if (mData["status"] === "frozen" || mData["status"] === "absent") {
        excludedUids.push(mDoc.id);
      }
      // Construir load data para smart distribution
      const completions60d: number = (mData["completions60d"] as number) ?? 0;
      const lastCompletedAt: admin.firestore.Timestamp | undefined = mData["lastCompletedAt"];
      const daysSince = lastCompletedAt
        ? Math.floor((Date.now() - lastCompletedAt.toMillis()) / (1000 * 60 * 60 * 24))
        : 0;
      loadDataMap.set(mDoc.id, {
        completionsRecent: completions60d,
        difficultyWeight: 1.0,
        daysSinceLastExecution: daysSince,
      });
    }

    const assignmentOrder: string[] = task["assignmentOrder"] ?? [uid];
    const frozenUids: string[] = task["frozenUids"] ?? [];
    const allExcluded = [...new Set([...frozenUids, ...excludedUids])];
    const distributionMode: string = task["distributionMode"] ?? "round_robin";

    let nextAssigneeUid: string;
    if (distributionMode === "smart") {
      nextAssigneeUid = getNextAssigneeSmart(assignmentOrder, uid, allExcluded, loadDataMap);
    } else {
      nextAssigneeUid = getNextAssigneeRoundRobin(assignmentOrder, uid, allExcluded) ?? uid;
    }

    const currentDue = (task["nextDueAt"] as admin.firestore.Timestamp | undefined)
      ?.toDate() ?? new Date();
    const recurrenceType: string = task["recurrenceType"] ?? "daily";
    const nextDueAt = addRecurrenceInterval(currentDue, recurrenceType);

    const eventRef = db.collection("homes").doc(homeId).collection("taskEvents").doc();
    tx.set(eventRef, {
      eventType: "completed",
      taskId,
      taskTitleSnapshot: task["title"] ?? "",
      taskVisualSnapshot: {
        kind: task["visualKind"] ?? "emoji",
        value: task["visualValue"] ?? "",
      },
      actorUid: uid,
      performerUid: uid,
      completedAt: FieldValue.serverTimestamp(),
      createdAt: FieldValue.serverTimestamp(),
      penaltyApplied: false,
    });

    tx.update(taskRef, {
      currentAssigneeUid: nextAssigneeUid,
      nextDueAt: admin.firestore.Timestamp.fromDate(nextDueAt),
      completedCount90d: FieldValue.increment(1),
      updatedAt: FieldValue.serverTimestamp(),
    });

    const memberRef = db.collection("homes").doc(homeId).collection("members").doc(uid);
    const memberSnap = await tx.get(memberRef);
    const member = memberSnap.data() ?? {};
    const newCompleted = ((member["completedCount"] as number) ?? 0) + 1;
    const newPassed: number = (member["passedCount"] as number) ?? 0;
    const newCompliance = newCompleted / (newCompleted + newPassed);

    tx.update(memberRef, {
      completedCount: FieldValue.increment(1),
      completions60d: FieldValue.increment(1),
      complianceRate: newCompliance,
      lastCompletedAt: FieldValue.serverTimestamp(),
      lastActiveAt: FieldValue.serverTimestamp(),
    });

    return { eventId: eventRef.id, nextAssigneeUid };
  });

  updateHomeDashboard(homeId).catch((err) =>
    logger.error("Failed to update dashboard after completion", err)
  );

  return result;
});
```

- [ ] **Step 2: Compilar**

```bash
cd functions && npm run build
```
Resultado esperado: sin errores.

- [ ] **Step 3: Commit**

```bash
git add functions/src/tasks/apply_task_completion.ts
git commit -m "feat(tasks): apply_task_completion respects absent members and smart distribution mode"
```

---

### Task 9: Test de integración para vacaciones

**Files:**
- Create: `test/integration/features/members/vacation_integration_test.dart`

- [ ] **Step 1: Crear test de integración**

```dart
// test/integration/features/members/vacation_integration_test.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/members/data/members_repository_impl.dart';
import 'package:toka/features/members/domain/vacation.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseFunctions mockFunctions;
  late MembersRepositoryImpl repo;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockFunctions = MockFirebaseFunctions();
    repo = MembersRepositoryImpl(
      firestore: fakeFirestore,
      functions: mockFunctions,
    );
  });

  group('Vacation integration', () {
    test('saveVacation guarda el campo vacation y cambia status a absent', () async {
      // Setup: crear documento de miembro
      await fakeFirestore
          .collection('homes').doc('h1')
          .collection('members').doc('u1')
          .set({'status': 'active', 'nickname': 'Test'});

      final vacation = Vacation(
        uid: 'u1',
        homeId: 'h1',
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
      );

      await repo.saveVacation('h1', 'u1', vacation);

      final doc = await fakeFirestore
          .collection('homes').doc('h1')
          .collection('members').doc('u1')
          .get();
      expect(doc.data()!['status'], 'absent');
      expect(doc.data()!['vacation']['isActive'], true);
    });

    test('saveVacation con isAbsent false restaura status a active', () async {
      await fakeFirestore
          .collection('homes').doc('h1')
          .collection('members').doc('u1')
          .set({'status': 'absent', 'nickname': 'Test'});

      final vacation = Vacation(
        uid: 'u1',
        homeId: 'h1',
        isActive: false,
        createdAt: DateTime(2026, 1, 1),
      );

      await repo.saveVacation('h1', 'u1', vacation);

      final doc = await fakeFirestore
          .collection('homes').doc('h1')
          .collection('members').doc('u1')
          .get();
      expect(doc.data()!['status'], 'active');
    });

    test('watchVacation emite null si no hay campo vacation', () async {
      await fakeFirestore
          .collection('homes').doc('h1')
          .collection('members').doc('u1')
          .set({'status': 'active'});

      final stream = repo.watchVacation('h1', 'u1');
      expect(await stream.first, isNull);
    });
  });
}
```

- [ ] **Step 2: Ejecutar tests**

```bash
flutter test test/integration/features/members/vacation_integration_test.dart
```
Resultado esperado: `All tests passed`

- [ ] **Step 3: Commit**

```bash
git add test/integration/features/members/vacation_integration_test.dart
git commit -m "test(members): add vacation integration tests"
```

---

### Task 10: Ejecutar suite completa y verificar

- [ ] **Step 1: Ejecutar todos los tests**

```bash
flutter test test/unit/ test/integration/ test/ui/
```
Resultado esperado: todos pasan.

- [ ] **Step 2: Análisis estático**

```bash
flutter analyze
```
Resultado esperado: sin errores ni warnings.

- [ ] **Step 3: Commit final**

```bash
git add -A
git commit -m "feat(spec-13): complete smart distribution + vacaciones implementation"
```

---

## Pruebas manuales requeridas (Spec-13)

1. **Smart Distribution:** Crear tarea con `distributionMode = 'smart'` en Firestore, 3 miembros con distintas cargas (`completions60d`) → completar la tarea → verificar que se asigna al miembro con menor carga.
2. **Vacaciones simples:** Navegar a `/vacation`, activar toggle → guardar → completar varias tareas → confirmar que la persona en vacaciones no es asignada.
3. **Vacaciones con rango de fechas:** Configurar `startDate` = hoy, `endDate` = mañana → el miembro es excluido hoy; pasado mañana, desactivar manualmente y el miembro vuelve.
4. **Reasignación manual:** Como admin, llamar `manualReassign` desde consola Firebase → verificar evento `manual_reassign` en `taskEvents`.
5. **Chip de vacaciones:** En pantalla Hoy, verificar que el miembro en vacaciones muestra el chip "De vacaciones".
