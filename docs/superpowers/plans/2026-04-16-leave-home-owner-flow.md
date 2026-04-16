# Leave Home Owner Flow – Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cuando el propietario de un hogar pulsa "Abandonar hogar", mostrar el diálogo correcto según cuántos miembros activos/congelados hay, en lugar del snackbar de error actual.

**Architecture:** La clasificación (Caso A/B/C/D) ocurre en el `onTap` de `settings_screen.dart` con una lectura one-shot del stream de miembros. Los diálogos son widgets `StatefulWidget` privados en el mismo archivo. El backend añade la Cloud Function `transferOwnership` que aún no existe. No se crea ningún ViewModel nuevo.

**Tech Stack:** Flutter 3.x · Riverpod · Firestore Cloud Functions (Node 20 / TypeScript) · mocktail · flutter_test

---

## Mapa de archivos

| Archivo | Acción |
|---|---|
| `functions/src/homes/index.ts` | Añadir `export const transferOwnership` al final |
| `lib/l10n/app_es.arb` | +8 claves tras `homes_error_cannot_leave_as_owner` |
| `lib/l10n/app_en.arb` | +8 claves (ídem posición) |
| `lib/l10n/app_ro.arb` | +8 claves (ídem posición) |
| `lib/l10n/app_localizations.dart` | +8 getters abstractos tras `homes_error_cannot_leave_as_owner` |
| `lib/l10n/app_localizations_es.dart` | +8 implementaciones tras `homes_error_cannot_leave_as_owner` |
| `lib/l10n/app_localizations_en.dart` | +8 implementaciones |
| `lib/l10n/app_localizations_ro.dart` | +8 implementaciones |
| `lib/features/settings/presentation/settings_screen.dart` | Reescribir bloque `onTap` + añadir 2 `StatefulWidget` privados + 2 funciones auxiliares |
| `test/ui/features/settings/settings_screen_test.dart` | +4 widget tests (casos A/B/C/D) |

---

## Task 1: Cloud Function `transferOwnership`

**Files:**
- Modify: `functions/src/homes/index.ts` (añadir al final del archivo)

- [ ] **Paso 1: Añadir la función al final de `functions/src/homes/index.ts`**

```typescript
// ---------------------------------------------------------------------------
// transferOwnership
// Input:  { homeId: string, newOwnerUid: string }
// ---------------------------------------------------------------------------
export const transferOwnership = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be authenticated");
  }

  const uid = request.auth.uid;
  const data = request.data as { homeId?: string; newOwnerUid?: string };
  const homeId = data.homeId?.trim();
  const newOwnerUid = data.newOwnerUid?.trim();

  if (!homeId || !newOwnerUid) {
    throw new HttpsError(
      "invalid-argument",
      "homeId and newOwnerUid are required"
    );
  }

  const homeRef = db.collection("homes").doc(homeId);
  const homeDoc = await homeRef.get();

  if (!homeDoc.exists) {
    throw new HttpsError("not-found", "Home not found");
  }
  if (homeDoc.data()!["ownerUid"] !== uid) {
    throw new HttpsError(
      "permission-denied",
      "Only the current owner can transfer ownership"
    );
  }

  // Verificar que newOwner es miembro del hogar
  const newOwnerMemberRef = db
    .collection("homes")
    .doc(homeId)
    .collection("members")
    .doc(newOwnerUid);
  const newOwnerMemberDoc = await newOwnerMemberRef.get();

  if (!newOwnerMemberDoc.exists) {
    throw new HttpsError("not-found", "New owner is not a member of this home");
  }

  const batch = db.batch();

  // homes/{homeId}: actualizar ownerUid
  batch.update(homeRef, { ownerUid: newOwnerUid });

  // homes/{homeId}/members: cambiar roles
  batch.update(newOwnerMemberRef, { role: "owner" });
  batch.update(
    db.collection("homes").doc(homeId).collection("members").doc(uid),
    { role: "admin" }
  );

  // users/.../memberships: reflejar cambio de rol
  batch.update(
    db
      .collection("users")
      .doc(newOwnerUid)
      .collection("memberships")
      .doc(homeId),
    { role: "owner" }
  );
  batch.update(
    db.collection("users").doc(uid).collection("memberships").doc(homeId),
    { role: "admin" }
  );

  await batch.commit();
  logger.info(
    `transferOwnership: ${uid} → ${newOwnerUid} in home ${homeId}`
  );
});
```

- [ ] **Paso 2: Compilar TypeScript para verificar que no hay errores**

```bash
cd functions && npm run build 2>&1 | tail -10
```

Resultado esperado: sin errores de tipo, archivos `.js` generados en `lib/`.

- [ ] **Paso 3: Commit**

```bash
git add functions/src/homes/index.ts functions/lib/homes/index.js
git commit -m "feat(functions): add transferOwnership callable"
```

---

## Task 2: Claves ARB y archivos de localización

**Files:**
- Modify: `lib/l10n/app_es.arb`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_ro.arb`
- Modify: `lib/l10n/app_localizations.dart`
- Modify: `lib/l10n/app_localizations_es.dart`
- Modify: `lib/l10n/app_localizations_en.dart`
- Modify: `lib/l10n/app_localizations_ro.dart`

- [ ] **Paso 1: Añadir 8 claves a `app_es.arb` tras `homes_error_cannot_leave_as_owner`**

Buscar el bloque:
```json
  "homes_error_cannot_leave_as_owner": "Transfiere la propiedad antes de abandonar el hogar",
  "@homes_error_cannot_leave_as_owner": { "description": "Cannot leave as owner error" },
```

Insertar a continuación:
```json
  "homes_transfer_ownership_title": "Transferir propiedad del hogar",
  "@homes_transfer_ownership_title": { "description": "Transfer ownership dialog title" },
  "homes_transfer_ownership_body": "Para abandonar el hogar, selecciona quién será el nuevo propietario.",
  "@homes_transfer_ownership_body": { "description": "Transfer ownership dialog body" },
  "homes_transfer_btn": "Transferir",
  "@homes_transfer_btn": { "description": "Transfer button label" },
  "homes_delete_home_title": "Eliminar hogar",
  "@homes_delete_home_title": { "description": "Delete home dialog title" },
  "homes_delete_home_body_sole": "Eres el único miembro de este hogar. Al abandonarlo, se eliminará permanentemente y no podrá recuperarse.",
  "@homes_delete_home_body_sole": { "description": "Delete home dialog body when sole member" },
  "homes_delete_btn": "Eliminar",
  "@homes_delete_btn": { "description": "Delete button label" },
  "homes_frozen_only_title": "Abandonar hogar",
  "@homes_frozen_only_title": { "description": "Leave home dialog title when only frozen members exist" },
  "homes_frozen_only_body": "Solo hay miembros congelados. Puedes transferir la propiedad a uno de ellos o eliminar el hogar permanentemente.",
  "@homes_frozen_only_body": { "description": "Leave home dialog body when only frozen members exist" },
```

- [ ] **Paso 2: Añadir 8 claves a `app_en.arb` tras `homes_error_cannot_leave_as_owner`**

```json
  "homes_transfer_ownership_title": "Transfer home ownership",
  "@homes_transfer_ownership_title": { "description": "Transfer ownership dialog title" },
  "homes_transfer_ownership_body": "To leave the home, select who will become the new owner.",
  "@homes_transfer_ownership_body": { "description": "Transfer ownership dialog body" },
  "homes_transfer_btn": "Transfer",
  "@homes_transfer_btn": { "description": "Transfer button label" },
  "homes_delete_home_title": "Delete home",
  "@homes_delete_home_title": { "description": "Delete home dialog title" },
  "homes_delete_home_body_sole": "You are the only member. Leaving will permanently delete the home and it cannot be recovered.",
  "@homes_delete_home_body_sole": { "description": "Delete home dialog body when sole member" },
  "homes_delete_btn": "Delete",
  "@homes_delete_btn": { "description": "Delete button label" },
  "homes_frozen_only_title": "Leave home",
  "@homes_frozen_only_title": { "description": "Leave home dialog title when only frozen members exist" },
  "homes_frozen_only_body": "There are only frozen members. You can transfer ownership to one of them or permanently delete the home.",
  "@homes_frozen_only_body": { "description": "Leave home dialog body when only frozen members exist" },
```

- [ ] **Paso 3: Añadir 8 claves a `app_ro.arb` tras `homes_error_cannot_leave_as_owner`**

```json
  "homes_transfer_ownership_title": "Transferă proprietatea locuinței",
  "@homes_transfer_ownership_title": { "description": "Transfer ownership dialog title" },
  "homes_transfer_ownership_body": "Pentru a părăsi locuința, selectează cine va deveni noul proprietar.",
  "@homes_transfer_ownership_body": { "description": "Transfer ownership dialog body" },
  "homes_transfer_btn": "Transferă",
  "@homes_transfer_btn": { "description": "Transfer button label" },
  "homes_delete_home_title": "Șterge locuința",
  "@homes_delete_home_title": { "description": "Delete home dialog title" },
  "homes_delete_home_body_sole": "Ești singurul membru. Dacă pleci, locuința va fi ștearsă permanent și nu poate fi recuperată.",
  "@homes_delete_home_body_sole": { "description": "Delete home dialog body when sole member" },
  "homes_delete_btn": "Șterge",
  "@homes_delete_btn": { "description": "Delete button label" },
  "homes_frozen_only_title": "Părăsește locuința",
  "@homes_frozen_only_title": { "description": "Leave home dialog title when only frozen members exist" },
  "homes_frozen_only_body": "Există doar membri înghețați. Poți transfera proprietatea unuia dintre ei sau poți șterge locuința permanent.",
  "@homes_frozen_only_body": { "description": "Leave home dialog body when only frozen members exist" },
```

- [ ] **Paso 4: Añadir 8 getters abstractos a `app_localizations.dart` tras `homes_error_cannot_leave_as_owner`**

Buscar:
```dart
  String get homes_error_cannot_leave_as_owner;
```

Insertar después (mantener la misma línea de separación):
```dart
  /// Transfer ownership dialog title
  String get homes_transfer_ownership_title;

  /// Transfer ownership dialog body
  String get homes_transfer_ownership_body;

  /// Transfer button label
  String get homes_transfer_btn;

  /// Delete home dialog title
  String get homes_delete_home_title;

  /// Delete home dialog body when sole member
  String get homes_delete_home_body_sole;

  /// Delete button label
  String get homes_delete_btn;

  /// Leave home dialog title when only frozen members exist
  String get homes_frozen_only_title;

  /// Leave home dialog body when only frozen members exist
  String get homes_frozen_only_body;
```

- [ ] **Paso 5: Añadir 8 implementaciones a `app_localizations_es.dart` tras `homes_error_cannot_leave_as_owner`**

Buscar:
```dart
  String get homes_error_cannot_leave_as_owner =>
      'Transfiere la propiedad antes de abandonar el hogar';
```

Insertar después:
```dart
  @override
  String get homes_transfer_ownership_title => 'Transferir propiedad del hogar';

  @override
  String get homes_transfer_ownership_body =>
      'Para abandonar el hogar, selecciona quién será el nuevo propietario.';

  @override
  String get homes_transfer_btn => 'Transferir';

  @override
  String get homes_delete_home_title => 'Eliminar hogar';

  @override
  String get homes_delete_home_body_sole =>
      'Eres el único miembro de este hogar. Al abandonarlo, se eliminará permanentemente y no podrá recuperarse.';

  @override
  String get homes_delete_btn => 'Eliminar';

  @override
  String get homes_frozen_only_title => 'Abandonar hogar';

  @override
  String get homes_frozen_only_body =>
      'Solo hay miembros congelados. Puedes transferir la propiedad a uno de ellos o eliminar el hogar permanentemente.';
```

- [ ] **Paso 6: Añadir 8 implementaciones a `app_localizations_en.dart` tras `homes_error_cannot_leave_as_owner`**

Buscar la línea con `homes_error_cannot_leave_as_owner` en ese archivo e insertar después:
```dart
  @override
  String get homes_transfer_ownership_title => 'Transfer home ownership';

  @override
  String get homes_transfer_ownership_body =>
      'To leave the home, select who will become the new owner.';

  @override
  String get homes_transfer_btn => 'Transfer';

  @override
  String get homes_delete_home_title => 'Delete home';

  @override
  String get homes_delete_home_body_sole =>
      'You are the only member. Leaving will permanently delete the home and it cannot be recovered.';

  @override
  String get homes_delete_btn => 'Delete';

  @override
  String get homes_frozen_only_title => 'Leave home';

  @override
  String get homes_frozen_only_body =>
      'There are only frozen members. You can transfer ownership to one of them or permanently delete the home.';
```

- [ ] **Paso 7: Añadir 8 implementaciones a `app_localizations_ro.dart` tras `homes_error_cannot_leave_as_owner`**

```dart
  @override
  String get homes_transfer_ownership_title => 'Transferă proprietatea locuinței';

  @override
  String get homes_transfer_ownership_body =>
      'Pentru a părăsi locuința, selectează cine va deveni noul proprietar.';

  @override
  String get homes_transfer_btn => 'Transferă';

  @override
  String get homes_delete_home_title => 'Șterge locuința';

  @override
  String get homes_delete_home_body_sole =>
      'Ești singurul membru. Dacă pleci, locuința va fi ștearsă permanent și nu poate fi recuperată.';

  @override
  String get homes_delete_btn => 'Șterge';

  @override
  String get homes_frozen_only_title => 'Părăsește locuința';

  @override
  String get homes_frozen_only_body =>
      'Există doar membri înghețați. Poți transfera proprietatea unuia dintre ei sau poți șterge locuința permanent.';
```

- [ ] **Paso 8: Verificar que compila**

```bash
flutter analyze lib/l10n/ 2>&1 | tail -5
```

Resultado esperado: `No issues found.`

- [ ] **Paso 9: Commit**

```bash
git add lib/l10n/
git commit -m "feat(i18n): claves ARB para flujo leave-home owner"
```

---

## Task 3: Widget tests (failing)

**Files:**
- Modify: `test/ui/features/settings/settings_screen_test.dart`

Los tests se escriben antes de la implementación. Fallarán hasta que Task 4 y Task 5 estén completas.

- [ ] **Paso 1: Añadir imports y mocks al archivo de test**

Al comienzo del archivo, añadir los imports que faltan (después de los existentes):

```dart
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/application/homes_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/homes/domain/homes_repository.dart';
import 'package:toka/features/members/application/members_provider.dart';
import 'package:toka/features/members/domain/member.dart';
import 'package:toka/features/members/domain/members_repository.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/domain/auth_state.dart';
import 'package:toka/features/settings/application/settings_view_model.dart';
```

Añadir clases mock después de `_setupPackageInfoStub`:

```dart
class _MockHomesRepository extends Mock implements HomesRepository {}
class _MockMembersRepository extends Mock implements MembersRepository {}

/// Construye un [Member] con valores mínimos para tests.
Member _makeMember({
  required String uid,
  String nickname = 'TestUser',
  MemberRole role = MemberRole.member,
  MemberStatus status = MemberStatus.active,
}) =>
    Member(
      uid: uid,
      homeId: 'home1',
      nickname: nickname,
      photoUrl: null,
      bio: null,
      phone: null,
      phoneVisibility: 'none',
      role: role,
      status: status,
      joinedAt: DateTime(2024),
      tasksCompleted: 0,
      passedCount: 0,
      complianceRate: 1.0,
      currentStreak: 0,
      averageScore: 0.0,
    );
```

Actualizar `_wrap` para aceptar los nuevos mocks y un `homeId`/`uid` configurables:

```dart
Widget _wrap({
  SubscriptionState? subscription,
  String homeId = '',
  String uid = '',
  _MockHomesRepository? homesRepo,
  _MockMembersRepository? membersRepo,
}) {
  final fakeVm = _FakeSettingsViewModel(homeId: homeId, uid: uid,
      subscription: subscription ?? const SubscriptionState.free());
  return ProviderScope(
    overrides: [
      if (subscription != null)
        subscriptionStateProvider.overrideWith((ref) => subscription),
      settingsViewModelProvider.overrideWithValue(fakeVm),
      if (homesRepo != null)
        homesRepositoryProvider.overrideWithValue(homesRepo),
      if (membersRepo != null)
        membersRepositoryProvider.overrideWithValue(membersRepo),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      home: const SettingsScreen(),
    ),
  );
}

class _FakeSettingsViewModel implements SettingsViewModel {
  _FakeSettingsViewModel({
    required String homeId,
    required String uid,
    required SubscriptionState subscription,
  }) : viewData = SettingsViewData(
          isPremium: subscription.map(
            free: (_) => false,
            active: (_) => true,
            cancelledPendingEnd: (_) => true,
            rescue: (_) => true,
            expiredFree: (_) => false,
            restorable: (_) => false,
            purged: (_) => false,
          ),
          homeId: homeId,
          uid: uid,
        );

  @override
  final SettingsViewData viewData;
}
```

- [ ] **Paso 2: Añadir los 4 tests de caso al final de `main()`**

```dart
  // ── Tests flujo owner leave home ─────────────────────────────────────────

  testWidgets('Caso A: no-owner muestra diálogo de confirmación genérico',
      (tester) async {
    final homesRepo = _MockHomesRepository();
    final membersRepo = _MockMembersRepository();

    when(() => membersRepo.watchHomeMembers('home1')).thenAnswer(
      (_) => Stream.value([
        _makeMember(uid: 'owner1', role: MemberRole.owner),
        _makeMember(uid: 'user1',  role: MemberRole.member),
      ]),
    );
    when(() => homesRepo.leaveHome('home1', uid: 'user1'))
        .thenAnswer((_) async {});

    await tester.pumpWidget(_wrap(
      homeId: 'home1',
      uid: 'user1',
      homesRepo: homesRepo,
      membersRepo: membersRepo,
    ));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Abandonar hogar'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.tap(find.text('Abandonar hogar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Abandonar hogar?'), findsOneWidget);
    expect(find.text('Transferir propiedad del hogar'), findsNothing);
  });

  testWidgets('Caso B: owner con activos muestra TransferOwnershipDialog',
      (tester) async {
    final homesRepo = _MockHomesRepository();
    final membersRepo = _MockMembersRepository();

    when(() => membersRepo.watchHomeMembers('home1')).thenAnswer(
      (_) => Stream.value([
        _makeMember(uid: 'owner1', role: MemberRole.owner),
        _makeMember(uid: 'active1', nickname: 'Alice', role: MemberRole.member),
      ]),
    );

    await tester.pumpWidget(_wrap(
      homeId: 'home1',
      uid: 'owner1',
      homesRepo: homesRepo,
      membersRepo: membersRepo,
    ));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Abandonar hogar'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.tap(find.text('Abandonar hogar'));
    await tester.pumpAndSettle();

    expect(find.text('Transferir propiedad del hogar'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.byKey(const Key('transfer_confirm_btn')), findsOneWidget);
  });

  testWidgets('Caso C: owner único muestra diálogo eliminar hogar',
      (tester) async {
    final homesRepo = _MockHomesRepository();
    final membersRepo = _MockMembersRepository();

    when(() => membersRepo.watchHomeMembers('home1')).thenAnswer(
      (_) => Stream.value([
        _makeMember(uid: 'owner1', role: MemberRole.owner),
      ]),
    );

    await tester.pumpWidget(_wrap(
      homeId: 'home1',
      uid: 'owner1',
      homesRepo: homesRepo,
      membersRepo: membersRepo,
    ));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Abandonar hogar'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.tap(find.text('Abandonar hogar'));
    await tester.pumpAndSettle();

    expect(find.text('Eliminar hogar'), findsOneWidget);
    expect(find.byKey(const Key('delete_home_confirm_btn')), findsOneWidget);
  });

  testWidgets('Caso D: owner con solo congelados muestra FrozenTransferDialog',
      (tester) async {
    final homesRepo = _MockHomesRepository();
    final membersRepo = _MockMembersRepository();

    when(() => membersRepo.watchHomeMembers('home1')).thenAnswer(
      (_) => Stream.value([
        _makeMember(uid: 'owner1', role: MemberRole.owner),
        _makeMember(
          uid: 'frozen1',
          nickname: 'Bob',
          role: MemberRole.member,
          status: MemberStatus.frozen,
        ),
      ]),
    );

    await tester.pumpWidget(_wrap(
      homeId: 'home1',
      uid: 'owner1',
      homesRepo: homesRepo,
      membersRepo: membersRepo,
    ));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Abandonar hogar'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.tap(find.text('Abandonar hogar'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('frozen_delete_btn')), findsOneWidget);
    expect(find.byKey(const Key('frozen_transfer_btn')), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
  });
```

- [ ] **Paso 3: Verificar que los tests fallan (aún no hay implementación)**

```bash
flutter test test/ui/features/settings/settings_screen_test.dart \
  --name "Caso [ABCD]" 2>&1 | tail -15
```

Resultado esperado: 4 tests fallan con errores de tipo o widget-not-found.

---

## Task 4: Implementación — dialogs y onTap

**Files:**
- Modify: `lib/features/settings/presentation/settings_screen.dart`

- [ ] **Paso 1: Añadir imports que faltan al inicio de `settings_screen.dart`**

Después de los imports existentes, añadir:

```dart
import '../../members/application/members_provider.dart';
import '../../members/domain/member.dart';
import '../../homes/domain/home_membership.dart';
```

- [ ] **Paso 2: Añadir las dos funciones auxiliares privadas antes de la clase `SettingsScreen`**

```dart
/// Caso B/D — transfiere ownership y luego abandona el hogar.
Future<void> _transferAndLeave(
  BuildContext context,
  WidgetRef ref,
  String homeId,
  String uid,
  String newOwnerUid,
) async {
  try {
    await ref
        .read(membersRepositoryProvider)
        .transferOwnership(homeId, newOwnerUid);
    await ref
        .read(homesRepositoryProvider)
        .leaveHome(homeId, uid: uid);
    ref.invalidate(currentHomeProvider);
    if (context.mounted) context.go(AppRoutes.home);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ha ocurrido un error. Inténtalo de nuevo.')),
      );
    }
  }
}

/// Caso C — muestra el diálogo de eliminar y cierra el hogar si el usuario confirma.
Future<void> _confirmAndDeleteHome(
  BuildContext context,
  WidgetRef ref,
  String homeId,
  AppLocalizations l10n,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.homes_delete_home_title),
      content: Text(l10n.homes_delete_home_body_sole),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          key: const Key('delete_home_confirm_btn'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(ctx).colorScheme.error,
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.homes_delete_btn),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    await ref.read(homesRepositoryProvider).closeHome(homeId);
    ref.invalidate(currentHomeProvider);
    if (context.mounted) context.go(AppRoutes.home);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ha ocurrido un error. Inténtalo de nuevo.')),
      );
    }
  }
}
```

- [ ] **Paso 3: Añadir `_TransferOwnershipDialog` al final del archivo (después de la última clase)**

```dart
/// Diálogo Caso B: el owner selecciona un miembro activo como nuevo propietario.
class _TransferOwnershipDialog extends StatefulWidget {
  const _TransferOwnershipDialog({required this.members});

  final List<Member> members;

  @override
  State<_TransferOwnershipDialog> createState() =>
      _TransferOwnershipDialogState();
}

class _TransferOwnershipDialogState extends State<_TransferOwnershipDialog> {
  String? _selectedUid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.homes_transfer_ownership_title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.homes_transfer_ownership_body),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.members.length,
                itemBuilder: (_, i) {
                  final m = widget.members[i];
                  return RadioListTile<String>(
                    key: Key('transfer_member_${m.uid}'),
                    value: m.uid,
                    groupValue: _selectedUid,
                    onChanged: (v) => setState(() => _selectedUid = v),
                    title: Text(m.nickname),
                    secondary: CircleAvatar(
                      backgroundImage: m.photoUrl != null
                          ? NetworkImage(m.photoUrl!)
                          : null,
                      child: m.photoUrl == null
                          ? Text(m.nickname.isNotEmpty
                              ? m.nickname[0].toUpperCase()
                              : '?')
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.cancel),
        ),
        TextButton(
          key: const Key('transfer_confirm_btn'),
          onPressed: _selectedUid == null
              ? null
              : () => Navigator.of(context).pop(_selectedUid),
          child: Text(l10n.homes_transfer_btn),
        ),
      ],
    );
  }
}
```

- [ ] **Paso 4: Añadir `_FrozenTransferDialog` al final del archivo**

```dart
/// Diálogo Caso D: el owner puede transferir a un miembro congelado o eliminar el hogar.
/// Retorna `('transfer', uid)` o `('delete', null)`.
class _FrozenTransferDialog extends StatefulWidget {
  const _FrozenTransferDialog({required this.members});

  final List<Member> members;

  @override
  State<_FrozenTransferDialog> createState() => _FrozenTransferDialogState();
}

class _FrozenTransferDialogState extends State<_FrozenTransferDialog> {
  String? _selectedUid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.homes_frozen_only_title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.homes_frozen_only_body),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.members.length,
                itemBuilder: (_, i) {
                  final m = widget.members[i];
                  return RadioListTile<String>(
                    key: Key('frozen_member_${m.uid}'),
                    value: m.uid,
                    groupValue: _selectedUid,
                    onChanged: (v) => setState(() => _selectedUid = v),
                    title: Text(m.nickname),
                    secondary: CircleAvatar(
                      backgroundImage: m.photoUrl != null
                          ? NetworkImage(m.photoUrl!)
                          : null,
                      child: m.photoUrl == null
                          ? Text(m.nickname.isNotEmpty
                              ? m.nickname[0].toUpperCase()
                              : '?')
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(l10n.cancel),
        ),
        TextButton(
          key: const Key('frozen_delete_btn'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.of(context).pop(('delete', null)),
          child: Text(l10n.homes_delete_btn),
        ),
        TextButton(
          key: const Key('frozen_transfer_btn'),
          onPressed: _selectedUid == null
              ? null
              : () => Navigator.of(context).pop(('transfer', _selectedUid)),
          child: Text(l10n.homes_transfer_btn),
        ),
      ],
    );
  }
}
```

- [ ] **Paso 5: Reemplazar el bloque `onTap` de "Abandonar hogar" en `settings_screen.dart`**

Localizar el `onTap` que comienza con:
```dart
onTap: () async {
  if (homeId.isEmpty || uid.isEmpty) return;
  final confirmed = await showDialog<bool>(
```

Reemplazarlo por completo con:
```dart
onTap: () async {
  if (homeId.isEmpty || uid.isEmpty) return;
  final l10n = AppLocalizations.of(context);

  // Lectura one-shot de miembros para clasificar el caso
  final members = await ref
      .read(membersRepositoryProvider)
      .watchHomeMembers(homeId)
      .first;
  if (!context.mounted) return;

  final isOwner = members.any(
    (m) => m.uid == uid && m.role == MemberRole.owner,
  );
  final activeOthers = members
      .where((m) => m.uid != uid && m.status == MemberStatus.active)
      .toList();
  final frozenOthers = members
      .where((m) => m.uid != uid && m.status == MemberStatus.frozen)
      .toList();

  // ── Caso A: no es owner ────────────────────────────────────────────
  if (!isOwner) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.homes_leave_confirm_title),
        content: Text(l10n.homes_leave_confirm_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(homesRepositoryProvider).leaveHome(homeId, uid: uid);
    ref.invalidate(currentHomeProvider);
    if (context.mounted) context.go(AppRoutes.home);
    return;
  }

  // ── Caso B: owner con miembros activos ────────────────────────────
  if (activeOthers.isNotEmpty) {
    final selectedUid = await showDialog<String>(
      context: context,
      builder: (_) => _TransferOwnershipDialog(members: activeOthers),
    );
    if (selectedUid == null || !context.mounted) return;
    await _transferAndLeave(context, ref, homeId, uid, selectedUid);
    return;
  }

  // ── Caso C: owner único, sin otros miembros ───────────────────────
  if (frozenOthers.isEmpty) {
    await _confirmAndDeleteHome(context, ref, homeId, l10n);
    return;
  }

  // ── Caso D: owner con solo miembros congelados ────────────────────
  final result = await showDialog<(String, String?)>(
    context: context,
    builder: (_) => _FrozenTransferDialog(members: frozenOthers),
  );
  if (result == null || !context.mounted) return;
  final (action, selectedUid) = result;
  if (action == 'transfer' && selectedUid != null) {
    await _transferAndLeave(context, ref, homeId, uid, selectedUid);
  } else if (action == 'delete') {
    await _confirmAndDeleteHome(context, ref, homeId, l10n);
  }
},
```

- [ ] **Paso 6: Eliminar el catch de `CannotLeaveAsOwnerException` que ya no aplica**

El catch estaba en el bloque anterior y ya no existe. Verificar que no quede código muerto referenciando `CannotLeaveAsOwnerException`.

- [ ] **Paso 7: Verificar que compila sin errores**

```bash
flutter analyze lib/features/settings/presentation/settings_screen.dart 2>&1 | tail -5
```

Resultado esperado: `No issues found.`

---

## Task 5: Verificación final

**Files:** ninguno nuevo

- [ ] **Paso 1: Ejecutar los 4 tests nuevos**

```bash
flutter test test/ui/features/settings/settings_screen_test.dart \
  --name "Caso [ABCD]" 2>&1 | tail -20
```

Resultado esperado: `+4: All tests passed.`

- [ ] **Paso 2: Ejecutar la suite completa de settings**

```bash
flutter test test/ui/features/settings/settings_screen_test.dart 2>&1 | tail -10
```

Resultado esperado: todos los tests pasan (incluyendo los previos de renderizado).

- [ ] **Paso 3: Analyze global**

```bash
flutter analyze 2>&1 | grep -E "^error" | head -20
```

Resultado esperado: sin líneas de error (solo info/warning preexistentes).

- [ ] **Paso 4: Commit final**

```bash
git add lib/features/settings/presentation/settings_screen.dart \
        test/ui/features/settings/settings_screen_test.dart
git commit -m "feat(settings): flujo leave-home para propietarios (casos A/B/C/D)"
```

---

## Self-Review

**Cobertura de spec:**
- ✅ Caso A (no-owner): Task 4 Paso 5
- ✅ Caso B (activos): Task 4 Pasos 3 + 5
- ✅ Caso C (único miembro): Task 4 Pasos 2 + 5
- ✅ Caso D (solo congelados): Task 4 Pasos 4 + 5
- ✅ CF `transferOwnership`: Task 1
- ✅ 8 claves ARB × 3 idiomas: Task 2
- ✅ Tests de widget × 4 casos: Task 3

**Consistencia de tipos:**
- `_TransferOwnershipDialog` retorna `String?` (uid) — usado en `showDialog<String>` en Task 4.
- `_FrozenTransferDialog` retorna `(String, String?)?` — usado en `showDialog<(String, String?)>` en Task 4.
- `_transferAndLeave` y `_confirmAndDeleteHome` reciben exactamente los parámetros que se les pasan en Task 4.
- `MemberRole.owner`, `MemberStatus.active`, `MemberStatus.frozen` — todos existen en `home_membership.dart`.

**Sin placeholders:** ningún TBD, TODO ni "similar al anterior".
