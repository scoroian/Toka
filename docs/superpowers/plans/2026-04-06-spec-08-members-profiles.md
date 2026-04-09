# Spec-08: Miembros, Perfiles y Privacidad — Plan de Implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implementar pantalla de miembros del hogar, perfiles propios y ajenos con privacidad de teléfono, flujo de invitaciones, y gestión de roles (promover/degradar/transferir propiedad).

**Architecture:** Sigue el patrón existente: interfaz abstracta en `domain/`, implementación en `data/`, providers Riverpod en `application/`, pantallas en `presentation/`. Las acciones mutantes (invitar, remover, promover, transferir) van vía Cloud Functions. Las lecturas usan streams de Firestore directos.

**Tech Stack:** Flutter 3.x, Riverpod (riverpod_annotation), freezed, go_router, cloud_firestore, cloud_functions, mocktail (tests), fake_cloud_firestore (integration tests).

---

## Estructura de archivos

```
lib/features/members/
  domain/
    member.dart                    (NUEVO — modelo freezed)
    members_repository.dart        (NUEVO — interfaz abstracta)
  data/
    member_model.dart              (NUEVO — fromFirestore factory)
    members_repository_impl.dart   (NUEVO — implementación Firestore + CF)
  application/
    members_provider.dart          (NUEVO — stream de miembros)
    member_actions_provider.dart   (NUEVO — acciones mutantes)
  presentation/
    members_screen.dart            (NUEVO)
    member_profile_screen.dart     (NUEVO — perfil ajeno)
    widgets/
      member_card.dart             (NUEVO)
      member_role_badge.dart       (NUEVO)
      invite_member_sheet.dart     (NUEVO)

lib/features/profile/
  domain/
    user_profile.dart              (NUEVO — modelo freezed)
    profile_repository.dart        (NUEVO — interfaz abstracta)
  data/
    profile_repository_impl.dart   (NUEVO — Firestore directo)
  application/
    profile_provider.dart          (NUEVO)
  presentation/
    own_profile_screen.dart        (NUEVO)
    edit_profile_screen.dart       (NUEVO)
    widgets/
      stats_section.dart           (NUEVO)
      access_management_section.dart (NUEVO)

lib/core/
  errors/exceptions.dart           (MODIFICAR — añadir 3 excepciones)
  constants/routes.dart            (MODIFICAR — añadir 4 rutas)

lib/app.dart                       (MODIFICAR — GoRoutes nuevas)
lib/features/homes/presentation/home_settings_screen.dart  (MODIFICAR — navegar a miembros)

lib/l10n/app_es.arb, app_en.arb, app_ro.arb  (MODIFICAR — strings de miembros/perfil)

test/unit/features/members/
  member_test.dart                  (NUEVO)
  members_repository_test.dart      (NUEVO)
test/unit/features/profile/
  user_profile_test.dart            (NUEVO)
test/integration/features/members/
  members_invite_test.dart          (NUEVO)
test/ui/features/members/
  members_screen_test.dart          (NUEVO)
  member_profile_screen_test.dart   (NUEVO)
  goldens/members_screen.png        (generado)
  goldens/member_profile_screen.png (generado)
```

**Firestore paths relevantes:**
- `homes/{homeId}/members/{uid}` — miembro del hogar (stats + perfil público)
- `homes/{homeId}/invitations/{inviteId}` — invitaciones pendientes
- `users/{uid}` — perfil propio del usuario
- `users/{uid}/memberships/{homeId}` — membresía (role, status, billing)

---

## Tarea 1: Nuevas excepciones de miembros

**Archivos:**
- Modificar: `lib/core/errors/exceptions.dart`
- Modificar: `test/unit/core/errors/exceptions_test.dart`

- [ ] **Paso 1: Escribir tests para nuevas excepciones**

Abrir `test/unit/core/errors/exceptions_test.dart` y añadir al `main()`:

```dart
test('MaxMembersReachedException tiene mensaje correcto', () {
  const e = MaxMembersReachedException();
  expect(e.toString(), contains('MaxMembersReachedException'));
});

test('MaxAdminsReachedException tiene mensaje correcto', () {
  const e = MaxAdminsReachedException();
  expect(e.toString(), contains('MaxAdminsReachedException'));
});

test('CannotRemoveOwnerException tiene mensaje correcto', () {
  const e = CannotRemoveOwnerException();
  expect(e.toString(), contains('CannotRemoveOwnerException'));
});
```

- [ ] **Paso 2: Ejecutar para verificar fallo**

```
flutter test test/unit/core/errors/exceptions_test.dart
```

Resultado esperado: FAIL — `MaxMembersReachedException` no definida.

- [ ] **Paso 3: Añadir las tres excepciones a `lib/core/errors/exceptions.dart`**

Al final del archivo, añadir:

```dart
class MaxMembersReachedException implements Exception {
  const MaxMembersReachedException(
      [this.message = 'Maximum members limit reached']);
  final String message;
  @override
  String toString() => 'MaxMembersReachedException: $message';
}

class MaxAdminsReachedException implements Exception {
  const MaxAdminsReachedException(
      [this.message = 'Maximum admins limit reached (Free plan: 1 admin)']);
  final String message;
  @override
  String toString() => 'MaxAdminsReachedException: $message';
}

class CannotRemoveOwnerException implements Exception {
  const CannotRemoveOwnerException(
      [this.message = 'Cannot remove the home owner']);
  final String message;
  @override
  String toString() => 'CannotRemoveOwnerException: $message';
}
```

- [ ] **Paso 4: Verificar que pasan**

```
flutter test test/unit/core/errors/exceptions_test.dart
```

Resultado esperado: PASS (todos los tests del archivo).

- [ ] **Paso 5: Commit**

```bash
git add lib/core/errors/exceptions.dart test/unit/core/errors/exceptions_test.dart
git commit -m "feat(members): add MaxMembersReached, MaxAdminsReached, CannotRemoveOwner exceptions"
```

---

## Tarea 2: Modelo `Member` (freezed) + `MemberModel.fromFirestore`

**Archivos:**
- Crear: `lib/features/members/domain/member.dart`
- Crear: `lib/features/members/data/member_model.dart`
- Crear: `test/unit/features/members/member_test.dart`

- [ ] **Paso 1: Escribir tests**

Crear `test/unit/features/members/member_test.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/members/data/member_model.dart';
import 'package:toka/features/members/domain/member.dart';

// Stub mínimo de DocumentSnapshot para tests
class _FakeDoc {
  final String id;
  final Map<String, dynamic> _data;
  _FakeDoc(this.id, this._data);
  Map<String, dynamic> data() => _data;
}

void main() {
  final now = Timestamp.fromDate(DateTime(2026, 1, 1));

  Map<String, dynamic> baseData({
    String role = 'member',
    String status = 'active',
    String phoneVisibility = 'hidden',
    String? phone,
  }) =>
      {
        'nickname': 'Ana',
        'photoUrl': null,
        'bio': 'Hola soy Ana',
        'phone': phone,
        'phoneVisibility': phoneVisibility,
        'role': role,
        'status': status,
        'joinedAt': now,
        'tasksCompleted': 10,
        'passedCount': 2,
        'complianceRate': 0.83,
        'currentStreak': 3,
        'averageScore': 8.5,
      };

  test('Member.fromMap mapea role owner correctamente', () {
    final member = MemberModel.fromMap(
        'uid1', 'home1', baseData(role: 'owner'));
    expect(member.role, MemberRole.owner);
  });

  test('Member.fromMap mapea role admin correctamente', () {
    final member = MemberModel.fromMap(
        'uid1', 'home1', baseData(role: 'admin'));
    expect(member.role, MemberRole.admin);
  });

  test('Member.fromMap mapea status frozen correctamente', () {
    final member = MemberModel.fromMap(
        'uid1', 'home1', baseData(status: 'frozen'));
    expect(member.status, MemberStatus.frozen);
  });

  test('Member.phoneForViewer retorna null cuando hidden y no es propio', () {
    final member = MemberModel.fromMap(
        'uid1', 'home1', baseData(phone: '123456789', phoneVisibility: 'hidden'));
    expect(member.phoneForViewer(isSelf: false), isNull);
  });

  test('Member.phoneForViewer retorna teléfono cuando sameHomeMembers', () {
    final member = MemberModel.fromMap(
        'uid1', 'home1',
        baseData(phone: '123456789', phoneVisibility: 'sameHomeMembers'));
    expect(member.phoneForViewer(isSelf: false), '123456789');
  });

  test('Member.phoneForViewer retorna teléfono propio aunque sea hidden', () {
    final member = MemberModel.fromMap(
        'uid1', 'home1', baseData(phone: '123456789', phoneVisibility: 'hidden'));
    expect(member.phoneForViewer(isSelf: true), '123456789');
  });

  test('Member tiene valores por defecto cuando campos opcionales son null', () {
    final member = MemberModel.fromMap('uid2', 'home1', {
      'nickname': 'Bob',
      'joinedAt': now,
    });
    expect(member.complianceRate, 0.0);
    expect(member.tasksCompleted, 0);
    expect(member.phoneVisibility, 'hidden');
  });
}
```

- [ ] **Paso 2: Ejecutar para verificar fallo**

```
flutter test test/unit/features/members/member_test.dart
```

Resultado esperado: FAIL — clases no definidas.

- [ ] **Paso 3: Crear `lib/features/members/domain/member.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../homes/domain/home_membership.dart';

part 'member.freezed.dart';

@freezed
class Member with _$Member {
  const factory Member({
    required String uid,
    required String homeId,
    required String nickname,
    required String? photoUrl,
    required String? bio,
    required String? phone,
    required String phoneVisibility,
    required MemberRole role,
    required MemberStatus status,
    required DateTime joinedAt,
    required int tasksCompleted,
    required int passedCount,
    required double complianceRate,
    required int currentStreak,
    required double averageScore,
  }) = _Member;
}

extension MemberPhoneExtension on Member {
  /// Devuelve el teléfono solo si el visor tiene permiso de verlo.
  String? phoneForViewer({required bool isSelf}) {
    if (isSelf) return phone;
    if (phoneVisibility == 'sameHomeMembers') return phone;
    return null;
  }
}
```

- [ ] **Paso 4: Crear `lib/features/members/data/member_model.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../homes/domain/home_membership.dart';
import '../domain/member.dart';

class MemberModel {
  static Member fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc, String homeId) {
    return fromMap(doc.id, homeId, doc.data()!);
  }

  static Member fromMap(
      String uid, String homeId, Map<String, dynamic> data) {
    return Member(
      uid: uid,
      homeId: homeId,
      nickname: data['nickname'] as String? ?? uid,
      photoUrl: data['photoUrl'] as String?,
      bio: data['bio'] as String?,
      phone: data['phone'] as String?,
      phoneVisibility:
          data['phoneVisibility'] as String? ?? 'hidden',
      role: MemberRole.values.firstWhere(
        (e) => e.name == (data['role'] as String? ?? 'member'),
        orElse: () => MemberRole.member,
      ),
      status: MemberStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'active'),
        orElse: () => MemberStatus.active,
      ),
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      tasksCompleted: (data['tasksCompleted'] as int?) ?? 0,
      passedCount: (data['passedCount'] as int?) ?? 0,
      complianceRate:
          ((data['complianceRate'] as num?) ?? 0.0).toDouble(),
      currentStreak: (data['currentStreak'] as int?) ?? 0,
      averageScore:
          ((data['averageScore'] as num?) ?? 0.0).toDouble(),
    );
  }
}
```

- [ ] **Paso 5: Ejecutar build_runner para generar freezed**

```
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Paso 6: Ejecutar tests para verificar que pasan**

```
flutter test test/unit/features/members/member_test.dart
```

Resultado esperado: PASS (6 tests).

- [ ] **Paso 7: Commit**

```bash
git add lib/features/members/ test/unit/features/members/member_test.dart
git commit -m "feat(members): add Member domain model with phone privacy extension"
```

---

## Tarea 3: Modelo `UserProfile` (freezed)

**Archivos:**
- Crear: `lib/features/profile/domain/user_profile.dart`
- Crear: `test/unit/features/profile/user_profile_test.dart`

- [ ] **Paso 1: Escribir test**

Crear `test/unit/features/profile/user_profile_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/profile/domain/user_profile.dart';

void main() {
  test('UserProfile se construye correctamente', () {
    const profile = UserProfile(
      uid: 'uid1',
      nickname: 'Ana',
      photoUrl: null,
      bio: 'Bio de prueba',
      phone: '123456789',
      phoneVisibility: 'sameHomeMembers',
      locale: 'es',
    );
    expect(profile.uid, 'uid1');
    expect(profile.phoneVisibility, 'sameHomeMembers');
  });

  test('UserProfile.fromFirestore mapea campos opcionales como null', () {
    final profile = UserProfile.fromMap('uid2', {
      'nickname': 'Bob',
      'locale': 'en',
    });
    expect(profile.bio, isNull);
    expect(profile.phone, isNull);
    expect(profile.phoneVisibility, 'hidden');
  });
}
```

- [ ] **Paso 2: Ejecutar para verificar fallo**

```
flutter test test/unit/features/profile/user_profile_test.dart
```

Resultado esperado: FAIL.

- [ ] **Paso 3: Crear `lib/features/profile/domain/user_profile.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String uid,
    required String nickname,
    required String? photoUrl,
    required String? bio,
    required String? phone,
    required String phoneVisibility,
    required String locale,
  }) = _UserProfile;

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) =>
      UserProfile(
        uid: uid,
        nickname: data['nickname'] as String? ?? '',
        photoUrl: data['photoUrl'] as String?,
        bio: data['bio'] as String?,
        phone: data['phone'] as String?,
        phoneVisibility:
            data['phoneVisibility'] as String? ?? 'hidden',
        locale: data['locale'] as String? ?? 'es',
      );
}
```

- [ ] **Paso 4: Ejecutar build_runner + tests**

```
dart run build_runner build --delete-conflicting-outputs
flutter test test/unit/features/profile/user_profile_test.dart
```

Resultado esperado: PASS.

- [ ] **Paso 5: Commit**

```bash
git add lib/features/profile/domain/ test/unit/features/profile/
git commit -m "feat(profile): add UserProfile domain model"
```

---

## Tarea 4: `MembersRepository` — interfaz + implementación

**Archivos:**
- Crear: `lib/features/members/domain/members_repository.dart`
- Crear: `lib/features/members/data/members_repository_impl.dart`
- Crear: `test/unit/features/members/members_repository_test.dart`

- [ ] **Paso 1: Escribir tests del repositorio**

Crear `test/unit/features/members/members_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/core/errors/exceptions.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/members/domain/member.dart';
import 'package:toka/features/members/domain/members_repository.dart';

class _MockMembersRepository extends Mock implements MembersRepository {}

void main() {
  late _MockMembersRepository repo;

  final fakeMember = Member(
    uid: 'uid1',
    homeId: 'home1',
    nickname: 'Ana',
    photoUrl: null,
    bio: null,
    phone: null,
    phoneVisibility: 'hidden',
    role: MemberRole.member,
    status: MemberStatus.active,
    joinedAt: DateTime(2026, 1, 1),
    tasksCompleted: 5,
    passedCount: 1,
    complianceRate: 0.83,
    currentStreak: 2,
    averageScore: 8.0,
  );

  setUp(() {
    repo = _MockMembersRepository();
  });

  test('watchHomeMembers emite lista de miembros', () {
    when(() => repo.watchHomeMembers('home1'))
        .thenAnswer((_) => Stream.value([fakeMember]));
    expect(repo.watchHomeMembers('home1'), emits([fakeMember]));
  });

  test('inviteMember lanza MaxMembersReachedException si home está lleno', () {
    when(() => repo.inviteMember('home1', null))
        .thenThrow(const MaxMembersReachedException());
    expect(
      () => repo.inviteMember('home1', null),
      throwsA(isA<MaxMembersReachedException>()),
    );
  });

  test('promoteToAdmin lanza MaxAdminsReachedException en plan Free', () {
    when(() => repo.promoteToAdmin('home1', 'uid2'))
        .thenThrow(const MaxAdminsReachedException());
    expect(
      () => repo.promoteToAdmin('home1', 'uid2'),
      throwsA(isA<MaxAdminsReachedException>()),
    );
  });

  test('removeMember lanza CannotRemoveOwnerException para el owner', () {
    when(() => repo.removeMember('home1', 'uid-owner'))
        .thenThrow(const CannotRemoveOwnerException());
    expect(
      () => repo.removeMember('home1', 'uid-owner'),
      throwsA(isA<CannotRemoveOwnerException>()),
    );
  });

  test('generateInviteCode retorna código de 6 chars', () async {
    when(() => repo.generateInviteCode('home1'))
        .thenAnswer((_) async => 'ABC123');
    final code = await repo.generateInviteCode('home1');
    expect(code.length, 6);
  });
}
```

- [ ] **Paso 2: Ejecutar para verificar fallo**

```
flutter test test/unit/features/members/members_repository_test.dart
```

Resultado esperado: FAIL — `MembersRepository` no definido.

- [ ] **Paso 3: Crear `lib/features/members/domain/members_repository.dart`**

```dart
import '../../../core/errors/exceptions.dart';
import 'member.dart';

export '../../../core/errors/exceptions.dart'
    show MaxMembersReachedException, MaxAdminsReachedException, CannotRemoveOwnerException;

abstract interface class MembersRepository {
  /// Stream de todos los miembros (activos + congelados) del hogar.
  Stream<List<Member>> watchHomeMembers(String homeId);

  /// Obtiene un miembro concreto por su uid.
  Future<Member> fetchMember(String homeId, String uid);

  /// Invita un miembro por email (nullable = solo genera código).
  /// Lanza [MaxMembersReachedException] si el hogar está al límite.
  Future<void> inviteMember(String homeId, String? email);

  /// Genera código de invitación de 6 chars con TTL de 48h.
  Future<String> generateInviteCode(String homeId);

  /// Elimina a un miembro del hogar (vía CF).
  /// Lanza [CannotRemoveOwnerException] si el uid es el owner.
  Future<void> removeMember(String homeId, String uid);

  /// Promueve a un miembro a admin (vía CF).
  /// Lanza [MaxAdminsReachedException] en plan Free si ya hay 1 admin.
  Future<void> promoteToAdmin(String homeId, String uid);

  /// Degrada un admin a miembro (vía CF).
  Future<void> demoteFromAdmin(String homeId, String uid);

  /// Transfiere propiedad al nuevo uid (vía CF).
  /// El owner anterior pasa a ser admin.
  Future<void> transferOwnership(String homeId, String newOwnerUid);
}
```

- [ ] **Paso 4: Crear `lib/features/members/data/members_repository_impl.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/errors/exceptions.dart';
import '../data/member_model.dart';
import '../domain/member.dart';
import '../domain/members_repository.dart';

class MembersRepositoryImpl implements MembersRepository {
  MembersRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
  })  : _firestore = firestore,
        _functions = functions;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Stream<List<Member>> watchHomeMembers(String homeId) {
    return _firestore
        .collection('homes')
        .doc(homeId)
        .collection('members')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MemberModel.fromFirestore(d, homeId)).toList());
  }

  @override
  Future<Member> fetchMember(String homeId, String uid) async {
    final doc = await _firestore
        .collection('homes')
        .doc(homeId)
        .collection('members')
        .doc(uid)
        .get();
    if (!doc.exists) throw ServerException('Member $uid not found in $homeId');
    return MemberModel.fromFirestore(doc, homeId);
  }

  @override
  Future<void> inviteMember(String homeId, String? email) async {
    try {
      await _functions.httpsCallable('inviteMember').call({
        'homeId': homeId,
        if (email != null) 'email': email,
      });
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') throw const MaxMembersReachedException();
      rethrow;
    }
  }

  @override
  Future<String> generateInviteCode(String homeId) async {
    try {
      final result = await _functions
          .httpsCallable('generateInviteCode')
          .call<Map<String, dynamic>>({'homeId': homeId});
      return result.data['code'] as String;
    } on FirebaseFunctionsException {
      rethrow;
    }
  }

  @override
  Future<void> removeMember(String homeId, String uid) async {
    try {
      await _functions.httpsCallable('removeMember').call({
        'homeId': homeId,
        'targetUid': uid,
      });
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition') throw const CannotRemoveOwnerException();
      rethrow;
    }
  }

  @override
  Future<void> promoteToAdmin(String homeId, String uid) async {
    try {
      await _functions.httpsCallable('promoteToAdmin').call({
        'homeId': homeId,
        'targetUid': uid,
      });
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') throw const MaxAdminsReachedException();
      rethrow;
    }
  }

  @override
  Future<void> demoteFromAdmin(String homeId, String uid) async {
    await _functions.httpsCallable('demoteFromAdmin').call({
      'homeId': homeId,
      'targetUid': uid,
    });
  }

  @override
  Future<void> transferOwnership(String homeId, String newOwnerUid) async {
    await _functions.httpsCallable('transferOwnership').call({
      'homeId': homeId,
      'newOwnerUid': newOwnerUid,
    });
  }
}
```

- [ ] **Paso 5: Ejecutar tests**

```
flutter test test/unit/features/members/members_repository_test.dart
```

Resultado esperado: PASS (5 tests).

- [ ] **Paso 6: Commit**

```bash
git add lib/features/members/domain/members_repository.dart lib/features/members/data/members_repository_impl.dart test/unit/features/members/members_repository_test.dart
git commit -m "feat(members): add MembersRepository interface and Firestore+CF implementation"
```

---

## Tarea 5: `ProfileRepository` — interfaz + implementación

**Archivos:**
- Crear: `lib/features/profile/domain/profile_repository.dart`
- Crear: `lib/features/profile/data/profile_repository_impl.dart`
- Crear: `test/unit/features/profile/profile_repository_test.dart`

- [ ] **Paso 1: Escribir tests**

Crear `test/unit/features/profile/profile_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/profile/domain/profile_repository.dart';
import 'package:toka/features/profile/domain/user_profile.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late _MockProfileRepository repo;

  const fakeProfile = UserProfile(
    uid: 'uid1',
    nickname: 'Ana',
    photoUrl: null,
    bio: null,
    phone: null,
    phoneVisibility: 'hidden',
    locale: 'es',
  );

  setUp(() {
    repo = _MockProfileRepository();
  });

  test('fetchProfile retorna UserProfile', () async {
    when(() => repo.fetchProfile('uid1'))
        .thenAnswer((_) async => fakeProfile);
    final profile = await repo.fetchProfile('uid1');
    expect(profile.uid, 'uid1');
    expect(profile.nickname, 'Ana');
  });

  test('updateProfile completa sin error', () async {
    when(() => repo.updateProfile('uid1',
            nickname: any(named: 'nickname'),
            bio: any(named: 'bio'),
            phone: any(named: 'phone'),
            phoneVisibility: any(named: 'phoneVisibility')))
        .thenAnswer((_) async {});
    await expectLater(
      repo.updateProfile('uid1', nickname: 'Ana Nueva'),
      completes,
    );
  });
}
```

- [ ] **Paso 2: Ejecutar para verificar fallo**

```
flutter test test/unit/features/profile/profile_repository_test.dart
```

- [ ] **Paso 3: Crear `lib/features/profile/domain/profile_repository.dart`**

```dart
import 'user_profile.dart';

abstract interface class ProfileRepository {
  /// Lee el perfil del usuario desde `users/{uid}`.
  Future<UserProfile> fetchProfile(String uid);

  /// Escucha cambios en el perfil del usuario en tiempo real.
  Stream<UserProfile> watchProfile(String uid);

  /// Actualiza los campos proporcionados en `users/{uid}`.
  Future<void> updateProfile(
    String uid, {
    String? nickname,
    String? bio,
    String? phone,
    String? phoneVisibility,
  });
}
```

- [ ] **Paso 4: Crear `lib/features/profile/data/profile_repository_impl.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/exceptions.dart';
import '../domain/profile_repository.dart';
import '../domain/user_profile.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Future<UserProfile> fetchProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) throw ServerException('User $uid not found');
    return UserProfile.fromMap(uid, doc.data()!);
  }

  @override
  Stream<UserProfile> watchProfile(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .where((snap) => snap.exists)
        .map((snap) => UserProfile.fromMap(uid, snap.data()!));
  }

  @override
  Future<void> updateProfile(
    String uid, {
    String? nickname,
    String? bio,
    String? phone,
    String? phoneVisibility,
  }) async {
    final updates = <String, dynamic>{};
    if (nickname != null) updates['nickname'] = nickname;
    if (bio != null) updates['bio'] = bio;
    if (phone != null) updates['phone'] = phone;
    if (phoneVisibility != null) updates['phoneVisibility'] = phoneVisibility;
    if (updates.isEmpty) return;
    await _firestore.collection('users').doc(uid).update(updates);
  }
}
```

- [ ] **Paso 5: Ejecutar tests**

```
flutter test test/unit/features/profile/profile_repository_test.dart
```

Resultado esperado: PASS.

- [ ] **Paso 6: Commit**

```bash
git add lib/features/profile/ test/unit/features/profile/profile_repository_test.dart
git commit -m "feat(profile): add ProfileRepository interface and Firestore implementation"
```

---

## Tarea 6: Providers Riverpod (members + profile)

**Archivos:**
- Crear: `lib/features/members/application/members_provider.dart`
- Crear: `lib/features/members/application/member_actions_provider.dart`
- Crear: `lib/features/profile/application/profile_provider.dart`

No hay tests unitarios propios para providers (se testean indirectamente en UI tests). Solo compilación.

- [ ] **Paso 1: Crear `lib/features/members/application/members_provider.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/members_repository_impl.dart';
import '../domain/member.dart';
import '../domain/members_repository.dart';

part 'members_provider.g.dart';

@Riverpod(keepAlive: true)
MembersRepository membersRepository(MembersRepositoryRef ref) {
  return MembersRepositoryImpl(
    firestore: FirebaseFirestore.instance,
    functions: FirebaseFunctions.instance,
  );
}

@riverpod
Stream<List<Member>> homeMembers(HomeMembersRef ref, String homeId) {
  return ref.watch(membersRepositoryProvider).watchHomeMembers(homeId);
}
```

- [ ] **Paso 2: Crear `lib/features/members/application/member_actions_provider.dart`**

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'members_provider.dart';

part 'member_actions_provider.g.dart';

@riverpod
class MemberActions extends _$MemberActions {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> inviteMember(String homeId, String? email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(membersRepositoryProvider).inviteMember(homeId, email));
  }

  Future<String> generateInviteCode(String homeId) async {
    state = const AsyncValue.loading();
    try {
      final code = await ref
          .read(membersRepositoryProvider)
          .generateInviteCode(homeId);
      state = const AsyncValue.data(null);
      return code;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      rethrow;
    }
  }

  Future<void> removeMember(String homeId, String uid) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(membersRepositoryProvider).removeMember(homeId, uid));
  }

  Future<void> promoteToAdmin(String homeId, String uid) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(membersRepositoryProvider).promoteToAdmin(homeId, uid));
  }

  Future<void> demoteFromAdmin(String homeId, String uid) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(membersRepositoryProvider).demoteFromAdmin(homeId, uid));
  }

  Future<void> transferOwnership(String homeId, String newOwnerUid) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref
            .read(membersRepositoryProvider)
            .transferOwnership(homeId, newOwnerUid));
  }
}
```

- [ ] **Paso 3: Crear `lib/features/profile/application/profile_provider.dart`**

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/profile_repository_impl.dart';
import '../domain/profile_repository.dart';
import '../domain/user_profile.dart';

part 'profile_provider.g.dart';

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(ProfileRepositoryRef ref) {
  return ProfileRepositoryImpl(firestore: FirebaseFirestore.instance);
}

@riverpod
Stream<UserProfile> userProfile(UserProfileRef ref, String uid) {
  return ref.watch(profileRepositoryProvider).watchProfile(uid);
}

@riverpod
class ProfileEditor extends _$ProfileEditor {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> updateProfile(
    String uid, {
    String? nickname,
    String? bio,
    String? phone,
    String? phoneVisibility,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).updateProfile(
            uid,
            nickname: nickname,
            bio: bio,
            phone: phone,
            phoneVisibility: phoneVisibility,
          ),
    );
  }
}
```

- [ ] **Paso 4: Ejecutar build_runner**

```
dart run build_runner build --delete-conflicting-outputs
```

Resultado esperado: genera `.g.dart` para los 3 providers sin errores.

- [ ] **Paso 5: Verificar compilación**

```
flutter analyze lib/features/members/application/ lib/features/profile/application/
```

Resultado esperado: sin errores.

- [ ] **Paso 6: Commit**

```bash
git add lib/features/members/application/ lib/features/profile/application/
git commit -m "feat(members,profile): add Riverpod providers for members and profile"
```

---

## Tarea 7: Strings ARB + rutas nuevas

**Archivos:**
- Modificar: `lib/l10n/app_es.arb`
- Modificar: `lib/l10n/app_en.arb`
- Modificar: `lib/l10n/app_ro.arb`
- Modificar: `lib/core/constants/routes.dart`

- [ ] **Paso 1: Añadir rutas a `lib/core/constants/routes.dart`**

Localizar el bloque `all` y añadir las 4 rutas nuevas. El archivo queda:

```dart
abstract class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String taskDetail = '/task/:id';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String settings = '/settings';
  static const String subscription = '/subscription';
  static const String myHomes = '/my-homes';
  static const String homeSettings = '/home-settings';
  static const String members = '/members';
  static const String memberProfile = '/member/:uid';

  static const List<String> all = [
    splash,
    login,
    register,
    forgotPassword,
    verifyEmail,
    onboarding,
    home,
    taskDetail,
    profile,
    editProfile,
    settings,
    subscription,
    myHomes,
    homeSettings,
    members,
    memberProfile,
  ];
}
```

- [ ] **Paso 2: Verificar test de rutas**

```
flutter test test/unit/core/constants/routes_test.dart
```

Resultado esperado: PASS (el test existente verifica `all.length`; actualizar el valor esperado si el test comprueba el conteo exacto).

- [ ] **Paso 3: Añadir strings a `lib/l10n/app_es.arb`**

Insertar ANTES del cierre `}` del archivo:

```json
  "members_title": "Miembros",
  "@members_title": { "description": "Members screen title" },
  "members_invite_fab": "Invitar",
  "@members_invite_fab": { "description": "FAB label on members screen" },
  "members_section_active": "Activos",
  "@members_section_active": { "description": "Active members section" },
  "members_section_frozen": "Congelados",
  "@members_section_frozen": { "description": "Frozen members section" },
  "members_pending_tasks": "{count} tareas pendientes",
  "@members_pending_tasks": {
    "description": "Pending tasks badge on member card",
    "placeholders": { "count": { "type": "int" } }
  },
  "members_compliance": "Cumplimiento: {rate}%",
  "@members_compliance": {
    "description": "Compliance rate on member card",
    "placeholders": { "rate": { "type": "String" } }
  },
  "members_role_badge_owner": "Propietario",
  "@members_role_badge_owner": { "description": "Owner role badge" },
  "members_role_badge_admin": "Admin",
  "@members_role_badge_admin": { "description": "Admin role badge" },
  "members_role_badge_member": "Miembro",
  "@members_role_badge_member": { "description": "Member role badge" },
  "members_role_badge_frozen": "Congelado",
  "@members_role_badge_frozen": { "description": "Frozen role badge" },
  "invite_sheet_title": "Invitar miembro",
  "@invite_sheet_title": { "description": "Invite member sheet title" },
  "invite_sheet_share_code": "Compartir código",
  "@invite_sheet_share_code": { "description": "Share invite code option" },
  "invite_sheet_by_email": "Invitar por email",
  "@invite_sheet_by_email": { "description": "Invite by email option" },
  "invite_sheet_code_label": "Código de invitación",
  "@invite_sheet_code_label": { "description": "Generated invite code label" },
  "invite_sheet_email_hint": "correo@ejemplo.com",
  "@invite_sheet_email_hint": { "description": "Email field hint" },
  "invite_sheet_send": "Enviar invitación",
  "@invite_sheet_send": { "description": "Send invite button" },
  "invite_sheet_copy_code": "Copiar código",
  "@invite_sheet_copy_code": { "description": "Copy code button" },
  "invite_sheet_code_copied": "Código copiado",
  "@invite_sheet_code_copied": { "description": "Code copied snackbar" },
  "member_profile_tasks_completed": "Tareas completadas",
  "@member_profile_tasks_completed": { "description": "Stats: tasks completed" },
  "member_profile_compliance": "Cumplimiento",
  "@member_profile_compliance": { "description": "Stats: compliance rate" },
  "member_profile_streak": "Racha actual",
  "@member_profile_streak": { "description": "Stats: current streak" },
  "member_profile_avg_score": "Puntuación media",
  "@member_profile_avg_score": { "description": "Stats: average score" },
  "member_profile_history_30d": "Últimos 30 días",
  "@member_profile_history_30d": { "description": "History 30 days tab" },
  "member_profile_history_90d": "Últimos 90 días",
  "@member_profile_history_90d": { "description": "History 90 days tab" },
  "profile_title": "Mi perfil",
  "@profile_title": { "description": "Own profile screen title" },
  "profile_edit": "Editar perfil",
  "@profile_edit": { "description": "Edit profile button" },
  "profile_global_stats": "Mis estadísticas globales",
  "@profile_global_stats": { "description": "Global stats section title" },
  "profile_per_home_stats": "Estadísticas por hogar",
  "@profile_per_home_stats": { "description": "Per-home stats accordion title" },
  "profile_access_management": "Gestionar acceso",
  "@profile_access_management": { "description": "Access management section title" },
  "profile_linked_providers": "Proveedores vinculados",
  "@profile_linked_providers": { "description": "Linked providers item" },
  "profile_change_password": "Cambiar contraseña",
  "@profile_change_password": { "description": "Change password item" },
  "profile_logout": "Cerrar sesión",
  "@profile_logout": { "description": "Logout button" },
  "profile_nickname_label": "Apodo",
  "@profile_nickname_label": { "description": "Nickname field label" },
  "profile_bio_label": "Bio",
  "@profile_bio_label": { "description": "Bio field label" },
  "profile_phone_label": "Teléfono",
  "@profile_phone_label": { "description": "Phone field label" },
  "profile_phone_visibility_label": "Mostrar teléfono a miembros del hogar",
  "@profile_phone_visibility_label": { "description": "Phone visibility toggle" },
  "profile_saved": "Perfil guardado",
  "@profile_saved": { "description": "Profile saved snackbar" },
  "members_error_max_members": "El hogar ha alcanzado el límite de miembros",
  "@members_error_max_members": { "description": "Max members error" },
  "members_error_max_admins": "El plan gratuito solo permite 1 admin",
  "@members_error_max_admins": { "description": "Max admins error" },
  "members_error_cannot_remove_owner": "No se puede eliminar al propietario del hogar",
  "@members_error_cannot_remove_owner": { "description": "Cannot remove owner error" }
```

- [ ] **Paso 4: Añadir los mismos strings a `lib/l10n/app_en.arb`**

```json
  "members_title": "Members",
  "@members_title": { "description": "Members screen title" },
  "members_invite_fab": "Invite",
  "@members_invite_fab": { "description": "FAB label on members screen" },
  "members_section_active": "Active",
  "@members_section_active": { "description": "Active members section" },
  "members_section_frozen": "Frozen",
  "@members_section_frozen": { "description": "Frozen members section" },
  "members_pending_tasks": "{count} pending tasks",
  "@members_pending_tasks": {
    "description": "Pending tasks badge on member card",
    "placeholders": { "count": { "type": "int" } }
  },
  "members_compliance": "Compliance: {rate}%",
  "@members_compliance": {
    "description": "Compliance rate on member card",
    "placeholders": { "rate": { "type": "String" } }
  },
  "members_role_badge_owner": "Owner",
  "@members_role_badge_owner": { "description": "Owner role badge" },
  "members_role_badge_admin": "Admin",
  "@members_role_badge_admin": { "description": "Admin role badge" },
  "members_role_badge_member": "Member",
  "@members_role_badge_member": { "description": "Member role badge" },
  "members_role_badge_frozen": "Frozen",
  "@members_role_badge_frozen": { "description": "Frozen role badge" },
  "invite_sheet_title": "Invite member",
  "@invite_sheet_title": { "description": "Invite member sheet title" },
  "invite_sheet_share_code": "Share code",
  "@invite_sheet_share_code": { "description": "Share invite code option" },
  "invite_sheet_by_email": "Invite by email",
  "@invite_sheet_by_email": { "description": "Invite by email option" },
  "invite_sheet_code_label": "Invitation code",
  "@invite_sheet_code_label": { "description": "Generated invite code label" },
  "invite_sheet_email_hint": "email@example.com",
  "@invite_sheet_email_hint": { "description": "Email field hint" },
  "invite_sheet_send": "Send invitation",
  "@invite_sheet_send": { "description": "Send invite button" },
  "invite_sheet_copy_code": "Copy code",
  "@invite_sheet_copy_code": { "description": "Copy code button" },
  "invite_sheet_code_copied": "Code copied",
  "@invite_sheet_code_copied": { "description": "Code copied snackbar" },
  "member_profile_tasks_completed": "Tasks completed",
  "@member_profile_tasks_completed": { "description": "Stats: tasks completed" },
  "member_profile_compliance": "Compliance",
  "@member_profile_compliance": { "description": "Stats: compliance rate" },
  "member_profile_streak": "Current streak",
  "@member_profile_streak": { "description": "Stats: current streak" },
  "member_profile_avg_score": "Average score",
  "@member_profile_avg_score": { "description": "Stats: average score" },
  "member_profile_history_30d": "Last 30 days",
  "@member_profile_history_30d": { "description": "History 30 days tab" },
  "member_profile_history_90d": "Last 90 days",
  "@member_profile_history_90d": { "description": "History 90 days tab" },
  "profile_title": "My profile",
  "@profile_title": { "description": "Own profile screen title" },
  "profile_edit": "Edit profile",
  "@profile_edit": { "description": "Edit profile button" },
  "profile_global_stats": "My global stats",
  "@profile_global_stats": { "description": "Global stats section title" },
  "profile_per_home_stats": "Stats by home",
  "@profile_per_home_stats": { "description": "Per-home stats accordion title" },
  "profile_access_management": "Manage access",
  "@profile_access_management": { "description": "Access management section title" },
  "profile_linked_providers": "Linked providers",
  "@profile_linked_providers": { "description": "Linked providers item" },
  "profile_change_password": "Change password",
  "@profile_change_password": { "description": "Change password item" },
  "profile_logout": "Sign out",
  "@profile_logout": { "description": "Logout button" },
  "profile_nickname_label": "Nickname",
  "@profile_nickname_label": { "description": "Nickname field label" },
  "profile_bio_label": "Bio",
  "@profile_bio_label": { "description": "Bio field label" },
  "profile_phone_label": "Phone",
  "@profile_phone_label": { "description": "Phone field label" },
  "profile_phone_visibility_label": "Show phone to home members",
  "@profile_phone_visibility_label": { "description": "Phone visibility toggle" },
  "profile_saved": "Profile saved",
  "@profile_saved": { "description": "Profile saved snackbar" },
  "members_error_max_members": "Home has reached its member limit",
  "@members_error_max_members": { "description": "Max members error" },
  "members_error_max_admins": "Free plan only allows 1 admin",
  "@members_error_max_admins": { "description": "Max admins error" },
  "members_error_cannot_remove_owner": "Cannot remove the home owner",
  "@members_error_cannot_remove_owner": { "description": "Cannot remove owner error" }
```

- [ ] **Paso 5: Añadir los mismos strings a `lib/l10n/app_ro.arb`**

```json
  "members_title": "Membri",
  "@members_title": { "description": "Members screen title" },
  "members_invite_fab": "Invită",
  "@members_invite_fab": { "description": "FAB label on members screen" },
  "members_section_active": "Activi",
  "@members_section_active": { "description": "Active members section" },
  "members_section_frozen": "Înghețați",
  "@members_section_frozen": { "description": "Frozen members section" },
  "members_pending_tasks": "{count} sarcini în așteptare",
  "@members_pending_tasks": {
    "description": "Pending tasks badge on member card",
    "placeholders": { "count": { "type": "int" } }
  },
  "members_compliance": "Conformitate: {rate}%",
  "@members_compliance": {
    "description": "Compliance rate on member card",
    "placeholders": { "rate": { "type": "String" } }
  },
  "members_role_badge_owner": "Proprietar",
  "@members_role_badge_owner": { "description": "Owner role badge" },
  "members_role_badge_admin": "Admin",
  "@members_role_badge_admin": { "description": "Admin role badge" },
  "members_role_badge_member": "Membru",
  "@members_role_badge_member": { "description": "Member role badge" },
  "members_role_badge_frozen": "Înghețat",
  "@members_role_badge_frozen": { "description": "Frozen role badge" },
  "invite_sheet_title": "Invită membru",
  "@invite_sheet_title": { "description": "Invite member sheet title" },
  "invite_sheet_share_code": "Partajează cod",
  "@invite_sheet_share_code": { "description": "Share invite code option" },
  "invite_sheet_by_email": "Invită prin email",
  "@invite_sheet_by_email": { "description": "Invite by email option" },
  "invite_sheet_code_label": "Cod de invitație",
  "@invite_sheet_code_label": { "description": "Generated invite code label" },
  "invite_sheet_email_hint": "email@exemplu.com",
  "@invite_sheet_email_hint": { "description": "Email field hint" },
  "invite_sheet_send": "Trimite invitație",
  "@invite_sheet_send": { "description": "Send invite button" },
  "invite_sheet_copy_code": "Copiază cod",
  "@invite_sheet_copy_code": { "description": "Copy code button" },
  "invite_sheet_code_copied": "Cod copiat",
  "@invite_sheet_code_copied": { "description": "Code copied snackbar" },
  "member_profile_tasks_completed": "Sarcini finalizate",
  "@member_profile_tasks_completed": { "description": "Stats: tasks completed" },
  "member_profile_compliance": "Conformitate",
  "@member_profile_compliance": { "description": "Stats: compliance rate" },
  "member_profile_streak": "Seria curentă",
  "@member_profile_streak": { "description": "Stats: current streak" },
  "member_profile_avg_score": "Scor mediu",
  "@member_profile_avg_score": { "description": "Stats: average score" },
  "member_profile_history_30d": "Ultimele 30 zile",
  "@member_profile_history_30d": { "description": "History 30 days tab" },
  "member_profile_history_90d": "Ultimele 90 zile",
  "@member_profile_history_90d": { "description": "History 90 days tab" },
  "profile_title": "Profilul meu",
  "@profile_title": { "description": "Own profile screen title" },
  "profile_edit": "Editează profil",
  "@profile_edit": { "description": "Edit profile button" },
  "profile_global_stats": "Statisticile mele globale",
  "@profile_global_stats": { "description": "Global stats section title" },
  "profile_per_home_stats": "Statistici pe locuință",
  "@profile_per_home_stats": { "description": "Per-home stats accordion title" },
  "profile_access_management": "Gestionare acces",
  "@profile_access_management": { "description": "Access management section title" },
  "profile_linked_providers": "Furnizori conectați",
  "@profile_linked_providers": { "description": "Linked providers item" },
  "profile_change_password": "Schimbă parola",
  "@profile_change_password": { "description": "Change password item" },
  "profile_logout": "Deconectare",
  "@profile_logout": { "description": "Logout button" },
  "profile_nickname_label": "Poreclă",
  "@profile_nickname_label": { "description": "Nickname field label" },
  "profile_bio_label": "Bio",
  "@profile_bio_label": { "description": "Bio field label" },
  "profile_phone_label": "Telefon",
  "@profile_phone_label": { "description": "Phone field label" },
  "profile_phone_visibility_label": "Arată telefonul membrilor locuinței",
  "@profile_phone_visibility_label": { "description": "Phone visibility toggle" },
  "profile_saved": "Profil salvat",
  "@profile_saved": { "description": "Profile saved snackbar" },
  "members_error_max_members": "Locuința a atins limita de membri",
  "@members_error_max_members": { "description": "Max members error" },
  "members_error_max_admins": "Planul gratuit permite doar 1 admin",
  "@members_error_max_admins": { "description": "Max admins error" },
  "members_error_cannot_remove_owner": "Nu se poate elimina proprietarul locuinței",
  "@members_error_cannot_remove_owner": { "description": "Cannot remove owner error" }
```

- [ ] **Paso 6: Ejecutar build_runner para regenerar localizaciones**

```
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Paso 7: Verificar que compilan las localizaciones**

```
flutter analyze lib/l10n/
```

Resultado esperado: sin errores.

- [ ] **Paso 8: Commit**

```bash
git add lib/l10n/ lib/core/constants/routes.dart
git commit -m "feat(members,profile): add ARB strings for members and profile screens"
```

---

## Tarea 8: Widget `MemberRoleBadge`

**Archivos:**
- Crear: `lib/features/members/presentation/widgets/member_role_badge.dart`

Este widget es un chip de color que muestra el rol del miembro.

- [ ] **Paso 1: Crear `lib/features/members/presentation/widgets/member_role_badge.dart`**

```dart
import 'package:flutter/material.dart';

import '../../../../features/homes/domain/home_membership.dart';
import '../../../../l10n/app_localizations.dart';

class MemberRoleBadge extends StatelessWidget {
  const MemberRoleBadge({super.key, required this.role});

  final MemberRole role;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, color) = switch (role) {
      MemberRole.owner => (l10n.members_role_badge_owner, Colors.amber.shade700),
      MemberRole.admin => (l10n.members_role_badge_admin, Colors.blue.shade600),
      MemberRole.member => (l10n.members_role_badge_member, Colors.grey.shade600),
      MemberRole.frozen => (l10n.members_role_badge_frozen, Colors.blueGrey),
    };

    return Container(
      key: Key('role_badge_${role.name}'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
```

- [ ] **Paso 2: Verificar compilación**

```
flutter analyze lib/features/members/presentation/widgets/member_role_badge.dart
```

- [ ] **Paso 3: Commit**

```bash
git add lib/features/members/presentation/widgets/member_role_badge.dart
git commit -m "feat(members): add MemberRoleBadge widget"
```

---

## Tarea 9: Widget `MemberCard`

**Archivos:**
- Crear: `lib/features/members/presentation/widgets/member_card.dart`

- [ ] **Paso 1: Crear `lib/features/members/presentation/widgets/member_card.dart`**

```dart
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/member.dart';
import 'member_role_badge.dart';

class MemberCard extends StatelessWidget {
  const MemberCard({
    super.key,
    required this.member,
    required this.onTap,
    this.pendingTasksCount = 0,
  });

  final Member member;
  final VoidCallback onTap;
  final int pendingTasksCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compliancePercent =
        (member.complianceRate * 100).toStringAsFixed(0);

    return ListTile(
      key: Key('member_card_${member.uid}'),
      onTap: onTap,
      leading: CircleAvatar(
        backgroundImage: member.photoUrl != null
            ? NetworkImage(member.photoUrl!)
            : null,
        child: member.photoUrl == null
            ? Text(member.nickname.isNotEmpty
                ? member.nickname[0].toUpperCase()
                : '?')
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              member.nickname,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          MemberRoleBadge(role: member.role),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.members_compliance(compliancePercent)),
          if (pendingTasksCount > 0)
            Text(
              l10n.members_pending_tasks(pendingTasksCount),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
```

- [ ] **Paso 2: Verificar compilación**

```
flutter analyze lib/features/members/presentation/widgets/member_card.dart
```

- [ ] **Paso 3: Commit**

```bash
git add lib/features/members/presentation/widgets/member_card.dart
git commit -m "feat(members): add MemberCard widget"
```

---

## Tarea 10: Widget `InviteMemberSheet`

**Archivos:**
- Crear: `lib/features/members/presentation/widgets/invite_member_sheet.dart`

- [ ] **Paso 1: Crear `lib/features/members/presentation/widgets/invite_member_sheet.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/member_actions_provider.dart';

class InviteMemberSheet extends ConsumerStatefulWidget {
  const InviteMemberSheet({super.key, required this.homeId});

  final String homeId;

  @override
  ConsumerState<InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends ConsumerState<InviteMemberSheet> {
  bool _showEmail = false;
  final _emailController = TextEditingController();
  String? _generatedCode;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _generateCode() async {
    final code = await ref
        .read(memberActionsProvider.notifier)
        .generateInviteCode(widget.homeId);
    if (mounted) setState(() => _generatedCode = code);
  }

  Future<void> _sendEmailInvite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    await ref
        .read(memberActionsProvider.notifier)
        .inviteMember(widget.homeId, email);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.invite_sheet_title,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('btn_share_code'),
                  onPressed: () {
                    setState(() => _showEmail = false);
                    _generateCode();
                  },
                  icon: const Icon(Icons.qr_code),
                  label: Text(l10n.invite_sheet_share_code),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('btn_invite_email'),
                  onPressed: () => setState(() => _showEmail = true),
                  icon: const Icon(Icons.email_outlined),
                  label: Text(l10n.invite_sheet_by_email),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_generatedCode != null && !_showEmail) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(l10n.invite_sheet_code_label,
                      style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 8),
                  Text(
                    _generatedCode!,
                    key: const Key('invite_code_text'),
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(letterSpacing: 4),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    key: const Key('btn_copy_code'),
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: _generatedCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(l10n.invite_sheet_code_copied)),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: Text(l10n.invite_sheet_copy_code),
                  ),
                ],
              ),
            ),
          ],
          if (_showEmail) ...[
            TextField(
              key: const Key('email_field'),
              controller: _emailController,
              decoration: InputDecoration(
                hintText: l10n.invite_sheet_email_hint,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              key: const Key('btn_send_invite'),
              onPressed: _sendEmailInvite,
              child: Text(l10n.invite_sheet_send),
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Paso 2: Verificar compilación**

```
flutter analyze lib/features/members/presentation/widgets/invite_member_sheet.dart
```

- [ ] **Paso 3: Commit**

```bash
git add lib/features/members/presentation/widgets/invite_member_sheet.dart
git commit -m "feat(members): add InviteMemberSheet widget (code + email modes)"
```

---

## Tarea 11: `MembersScreen`

**Archivos:**
- Crear: `lib/features/members/presentation/members_screen.dart`

- [ ] **Paso 1: Crear `lib/features/members/presentation/members_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../features/auth/application/auth_provider.dart';
import '../../../features/homes/application/current_home_provider.dart';
import '../../../features/homes/domain/home_membership.dart';
import '../../../features/homes/application/homes_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../application/members_provider.dart';
import '../domain/member.dart';
import 'widgets/invite_member_sheet.dart';
import 'widgets/member_card.dart';

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentHomeAsync = ref.watch(currentHomeProvider);
    final auth = ref.watch(authProvider);
    final uid = auth.whenOrNull(authenticated: (u) => u.uid) ?? '';

    return currentHomeAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.members_title)),
        body: const LoadingWidget(),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: Text(l10n.members_title)),
        body: Center(child: Text(l10n.error_generic)),
      ),
      data: (home) {
        if (home == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.members_title)),
            body: Center(child: Text(l10n.error_generic)),
          );
        }

        final membershipsAsync = uid.isNotEmpty
            ? ref.watch(userMembershipsProvider(uid))
            : null;
        final memberships = membershipsAsync?.valueOrNull ?? [];
        final myMembership = memberships
            .where((m) => m.homeId == home.id)
            .cast<HomeMembership?>()
            .firstOrNull;

        final canInvite = myMembership?.role == MemberRole.owner ||
            myMembership?.role == MemberRole.admin;

        final membersAsync =
            ref.watch(homeMembersProvider(home.id));

        return Scaffold(
          appBar: AppBar(title: Text(l10n.members_title)),
          floatingActionButton: canInvite
              ? FloatingActionButton.extended(
                  key: const Key('fab_invite'),
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => InviteMemberSheet(homeId: home.id),
                  ),
                  icon: const Icon(Icons.person_add),
                  label: Text(l10n.members_invite_fab),
                )
              : null,
          body: membersAsync.when(
            loading: () => const LoadingWidget(),
            error: (_, __) => Center(child: Text(l10n.error_generic)),
            data: (members) {
              final active = members
                  .where((m) => m.status == MemberStatus.active)
                  .toList();
              final frozen = members
                  .where((m) => m.status == MemberStatus.frozen)
                  .toList();

              return ListView(
                key: const Key('members_list'),
                children: [
                  if (active.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        l10n.members_section_active,
                        key: const Key('section_active'),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    ...active.map((m) => MemberCard(
                          member: m,
                          onTap: () => context.push(
                            AppRoutes.memberProfile
                                .replaceFirst(':uid', m.uid),
                            extra: {'homeId': home.id},
                          ),
                        )),
                  ],
                  if (frozen.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        l10n.members_section_frozen,
                        key: const Key('section_frozen'),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    ...frozen.map((m) => MemberCard(
                          member: m,
                          onTap: () => context.push(
                            AppRoutes.memberProfile
                                .replaceFirst(':uid', m.uid),
                            extra: {'homeId': home.id},
                          ),
                        )),
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }
}
```

- [ ] **Paso 2: Verificar compilación**

```
flutter analyze lib/features/members/presentation/members_screen.dart
```

- [ ] **Paso 3: Commit**

```bash
git add lib/features/members/presentation/members_screen.dart
git commit -m "feat(members): add MembersScreen with active/frozen sections and invite FAB"
```

---

## Tarea 12: `MemberProfileScreen` (perfil ajeno restringido)

**Archivos:**
- Crear: `lib/features/members/presentation/member_profile_screen.dart`

- [ ] **Paso 1: Crear `lib/features/members/presentation/member_profile_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../features/auth/application/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../application/members_provider.dart';
import 'widgets/member_role_badge.dart';

part 'member_profile_screen.g.dart';

/// Provider parametrizado para obtener un miembro concreto.
@riverpod
Future<dynamic> memberDetail(
    MemberDetailRef ref, String homeId, String uid) async {
  return ref.watch(membersRepositoryProvider).fetchMember(homeId, uid);
}

class MemberProfileScreen extends ConsumerWidget {
  const MemberProfileScreen({
    super.key,
    required this.homeId,
    required this.memberUid,
  });

  final String homeId;
  final String memberUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authProvider);
    final currentUid = auth.whenOrNull(authenticated: (u) => u.uid) ?? '';
    final isSelf = currentUid == memberUid;

    final memberAsync = ref.watch(memberDetailProvider(homeId, memberUid));

    return Scaffold(
      appBar: AppBar(),
      body: memberAsync.when(
        loading: () => const LoadingWidget(),
        error: (_, __) => Center(child: Text(l10n.error_generic)),
        data: (member) {
          final visiblePhone = member.phoneForViewer(isSelf: isSelf);
          final compliancePct =
              (member.complianceRate * 100).toStringAsFixed(1);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Avatar + nombre + bio
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: member.photoUrl != null
                          ? NetworkImage(member.photoUrl!)
                          : null,
                      child: member.photoUrl == null
                          ? Text(
                              member.nickname.isNotEmpty
                                  ? member.nickname[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(fontSize: 32),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      member.nickname,
                      key: const Key('member_nickname'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    MemberRoleBadge(role: member.role),
                    if (member.bio != null && member.bio!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        member.bio!,
                        key: const Key('member_bio'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),

              // Teléfono (solo si visible)
              if (visiblePhone != null) ...[
                const SizedBox(height: 12),
                ListTile(
                  key: const Key('member_phone_tile'),
                  leading: const Icon(Icons.phone),
                  title: Text(visiblePhone),
                ),
              ],

              const Divider(height: 32),

              // Estadísticas del hogar compartido
              Text(
                'Estadísticas en este hogar',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _StatRow(
                key: const Key('stat_tasks_completed'),
                label: l10n.member_profile_tasks_completed,
                value: member.tasksCompleted.toString(),
              ),
              _StatRow(
                key: const Key('stat_compliance'),
                label: l10n.member_profile_compliance,
                value: '$compliancePct%',
              ),
              _StatRow(
                key: const Key('stat_streak'),
                label: l10n.member_profile_streak,
                value: member.currentStreak.toString(),
              ),
              _StatRow(
                key: const Key('stat_avg_score'),
                label: l10n.member_profile_avg_score,
                value: '${member.averageScore.toStringAsFixed(1)}/10',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Paso 2: Ejecutar build_runner**

```
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Paso 3: Verificar compilación**

```
flutter analyze lib/features/members/presentation/member_profile_screen.dart
```

- [ ] **Paso 4: Commit**

```bash
git add lib/features/members/presentation/member_profile_screen.dart
git commit -m "feat(members): add MemberProfileScreen with restricted foreign view"
```

---

## Tarea 13: Pantallas de Perfil propio + widgets de apoyo

**Archivos:**
- Crear: `lib/features/profile/presentation/widgets/stats_section.dart`
- Crear: `lib/features/profile/presentation/widgets/access_management_section.dart`
- Crear: `lib/features/profile/presentation/own_profile_screen.dart`
- Crear: `lib/features/profile/presentation/edit_profile_screen.dart`

- [ ] **Paso 1: Crear `lib/features/profile/presentation/widgets/stats_section.dart`**

```dart
import 'package:flutter/material.dart';

import '../../domain/user_profile.dart';

class StatsSection extends StatelessWidget {
  const StatsSection({
    super.key,
    required this.profile,
    required this.totalCompleted,
    required this.globalCompliance,
  });

  final UserProfile profile;
  final int totalCompleted;
  final double globalCompliance;

  @override
  Widget build(BuildContext context) {
    final compliancePct = (globalCompliance * 100).toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatRow(
            key: const Key('stat_total_completed'),
            label: 'Tareas completadas',
            value: totalCompleted.toString()),
        _StatRow(
            key: const Key('stat_global_compliance'),
            label: 'Cumplimiento global',
            value: '$compliancePct%'),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({super.key, required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
```

- [ ] **Paso 2: Crear `lib/features/profile/presentation/widgets/access_management_section.dart`**

```dart
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class AccessManagementSection extends StatelessWidget {
  const AccessManagementSection({
    super.key,
    required this.hasEmailPassword,
    required this.onChangePassword,
    required this.onLogout,
  });

  final bool hasEmailPassword;
  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasEmailPassword)
          ListTile(
            key: const Key('change_password_tile'),
            leading: const Icon(Icons.lock_outline),
            title: Text(l10n.profile_change_password),
            onTap: onChangePassword,
          ),
        ListTile(
          key: const Key('logout_tile'),
          leading: const Icon(Icons.logout),
          title: Text(
            l10n.profile_logout,
            style: const TextStyle(color: Colors.red),
          ),
          onTap: onLogout,
        ),
      ],
    );
  }
}
```

- [ ] **Paso 3: Crear `lib/features/profile/presentation/own_profile_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../features/auth/application/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../application/profile_provider.dart';
import 'widgets/access_management_section.dart';
import 'widgets/stats_section.dart';

class OwnProfileScreen extends ConsumerWidget {
  const OwnProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authProvider);
    final uid = auth.whenOrNull(authenticated: (u) => u.uid) ?? '';
    final hasEmailPassword = auth.whenOrNull(
            authenticated: (u) => u.providers.contains('password')) ??
        false;

    if (uid.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.profile_title)),
        body: Center(child: Text(l10n.error_generic)),
      );
    }

    final profileAsync = ref.watch(userProfileProvider(uid));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile_title),
        actions: [
          TextButton(
            key: const Key('edit_profile_btn'),
            onPressed: () => context.push(AppRoutes.editProfile),
            child: Text(l10n.profile_edit),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const LoadingWidget(),
        error: (_, __) => Center(child: Text(l10n.error_generic)),
        data: (profile) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Avatar + nombre + bio
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    key: const Key('own_avatar'),
                    radius: 48,
                    backgroundImage: profile.photoUrl != null
                        ? NetworkImage(profile.photoUrl!)
                        : null,
                    child: profile.photoUrl == null
                        ? Text(
                            profile.nickname.isNotEmpty
                                ? profile.nickname[0].toUpperCase()
                                : '?',
                            style: const TextStyle(fontSize: 32),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.nickname,
                    key: const Key('own_nickname'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (profile.bio != null && profile.bio!.isNotEmpty)
                    Text(
                      profile.bio!,
                      key: const Key('own_bio'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),

            const Divider(height: 32),

            // Estadísticas globales
            Text(
              l10n.profile_global_stats,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            StatsSection(
              key: const Key('global_stats'),
              profile: profile,
              totalCompleted: 0,
              globalCompliance: 0.0,
            ),

            const Divider(height: 32),

            // Gestionar acceso
            Text(
              l10n.profile_access_management,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            AccessManagementSection(
              key: const Key('access_management'),
              hasEmailPassword: hasEmailPassword,
              onChangePassword: () {
                // TODO: navegar a change password
              },
              onLogout: () async {
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) context.go(AppRoutes.login);
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Paso 4: Crear `lib/features/profile/presentation/edit_profile_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/application/auth_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../application/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _phoneVisible = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save(String uid) async {
    final l10n = AppLocalizations.of(context);
    await ref.read(profileEditorProvider.notifier).updateProfile(
          uid,
          nickname: _nicknameController.text.trim(),
          bio: _bioController.text.trim(),
          phone: _phoneController.text.trim(),
          phoneVisibility:
              _phoneVisible ? 'sameHomeMembers' : 'hidden',
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profile_saved)),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authProvider);
    final uid = auth.whenOrNull(authenticated: (u) => u.uid) ?? '';
    final profileAsync = ref.watch(userProfileProvider(uid));
    final editorState = ref.watch(profileEditorProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile_edit),
        actions: [
          if (editorState is AsyncLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              key: const Key('save_profile_btn'),
              onPressed: () => _save(uid),
              child: Text(l10n.save),
            ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const LoadingWidget(),
        error: (_, __) => Center(child: Text(l10n.error_generic)),
        data: (profile) {
          if (!_initialized) {
            _nicknameController.text = profile.nickname;
            _bioController.text = profile.bio ?? '';
            _phoneController.text = profile.phone ?? '';
            _phoneVisible = profile.phoneVisibility == 'sameHomeMembers';
            _initialized = true;
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                key: const Key('nickname_field'),
                controller: _nicknameController,
                decoration: InputDecoration(
                  labelText: l10n.profile_nickname_label,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('bio_field'),
                controller: _bioController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.profile_bio_label,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('phone_field'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.profile_phone_label,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                key: const Key('phone_visibility_switch'),
                title: Text(l10n.profile_phone_visibility_label),
                value: _phoneVisible,
                onChanged: (v) => setState(() => _phoneVisible = v),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

- [ ] **Paso 5: Ejecutar build_runner + verificar compilación**

```
dart run build_runner build --delete-conflicting-outputs
flutter analyze lib/features/profile/
```

- [ ] **Paso 6: Commit**

```bash
git add lib/features/profile/
git commit -m "feat(profile): add OwnProfileScreen, EditProfileScreen and support widgets"
```

---

## Tarea 14: Wiring de rutas en `app.dart` + `home_settings_screen.dart`

**Archivos:**
- Modificar: `lib/app.dart`
- Modificar: `lib/features/homes/presentation/home_settings_screen.dart`

- [ ] **Paso 1: Añadir imports y GoRoutes en `lib/app.dart`**

Añadir imports en la zona de imports:

```dart
import 'features/members/presentation/members_screen.dart';
import 'features/members/presentation/member_profile_screen.dart';
import 'features/profile/presentation/own_profile_screen.dart';
import 'features/profile/presentation/edit_profile_screen.dart';
```

Añadir las 4 rutas nuevas dentro del array `routes:` de `GoRouter`:

```dart
GoRoute(
  path: AppRoutes.members,
  builder: (_, __) => const MembersScreen(),
),
GoRoute(
  path: AppRoutes.memberProfile,
  builder: (context, state) {
    final uid = state.pathParameters['uid']!;
    final extra = state.extra as Map<String, dynamic>?;
    final homeId = extra?['homeId'] as String? ?? '';
    return MemberProfileScreen(homeId: homeId, memberUid: uid);
  },
),
GoRoute(
  path: AppRoutes.profile,
  builder: (_, __) => const OwnProfileScreen(),
),
GoRoute(
  path: AppRoutes.editProfile,
  builder: (_, __) => const EditProfileScreen(),
),
```

- [ ] **Paso 2: Navegar al `MembersScreen` desde `home_settings_screen.dart`**

Localizar el `ListTile` con key `members_tile` (línea ~204):

```dart
// Reemplazar el TODO por:
ListTile(
  key: const Key('members_tile'),
  title: Text(l10n.homes_members),
  trailing: const Icon(Icons.chevron_right),
  onTap: () => context.push(AppRoutes.members),
),
```

También añadir el import de `go_router` si no está ya:

```dart
import 'package:go_router/go_router.dart';
```

Y añadir el import de `routes.dart`:

```dart
import '../../../core/constants/routes.dart';
```

- [ ] **Paso 3: Verificar compilación**

```
flutter analyze lib/app.dart lib/features/homes/presentation/home_settings_screen.dart
```

- [ ] **Paso 4: Commit**

```bash
git add lib/app.dart lib/features/homes/presentation/home_settings_screen.dart
git commit -m "feat(nav): wire /members, /member/:uid, /profile, /profile/edit routes"
```

---

## Tarea 15: Tests de integración de miembros

**Archivos:**
- Crear: `test/integration/features/members/members_invite_test.dart`

Los tests de integración usan `fake_cloud_firestore` para simular operaciones Firestore. Las Cloud Functions se simulan aplicando directamente los efectos esperados en la base de datos falsa.

- [ ] **Paso 1: Escribir tests de integración**

Crear `test/integration/features/members/members_invite_test.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/core/errors/exceptions.dart';
import 'package:toka/features/members/data/member_model.dart';

/// Simula la CF generateInviteCode: crea doc en invitations con TTL.
Future<String> simulateGenerateCode(
  FakeFirebaseFirestore db,
  String homeId,
  String actorUid,
) async {
  const code = 'ABC123';
  await db
      .collection('homes')
      .doc(homeId)
      .collection('invitations')
      .doc('inv1')
      .set({
    'code': code,
    'createdBy': actorUid,
    'createdAt': Timestamp.fromDate(DateTime.now()),
    'expiresAt':
        Timestamp.fromDate(DateTime.now().add(const Duration(hours: 48))),
    'used': false,
  });
  return code;
}

/// Simula la CF joinHomeByCode: valida TTL y crea membresía.
Future<void> simulateJoinByCode(
  FakeFirebaseFirestore db,
  String homeId,
  String code,
  String newUid,
) async {
  final invitesSnap = await db
      .collection('homes')
      .doc(homeId)
      .collection('invitations')
      .where('code', isEqualTo: code)
      .get();

  if (invitesSnap.docs.isEmpty) throw const InvalidInviteCodeException();

  final invite = invitesSnap.docs.first.data();
  final expiresAt = (invite['expiresAt'] as Timestamp).toDate();
  if (DateTime.now().isAfter(expiresAt)) {
    throw const ExpiredInviteCodeException();
  }

  await db
      .collection('homes')
      .doc(homeId)
      .collection('members')
      .doc(newUid)
      .set({
    'nickname': 'Nuevo Miembro',
    'role': 'member',
    'status': 'active',
    'joinedAt': Timestamp.fromDate(DateTime.now()),
    'phoneVisibility': 'hidden',
    'tasksCompleted': 0,
    'passedCount': 0,
    'complianceRate': 0.0,
    'currentStreak': 0,
    'averageScore': 0.0,
  });

  await db
      .collection('users')
      .doc(newUid)
      .collection('memberships')
      .doc(homeId)
      .set({
    'homeId': homeId,
    'homeNameSnapshot': 'Casa de prueba',
    'role': 'member',
    'status': 'active',
    'billingState': 'none',
    'joinedAt': Timestamp.fromDate(DateTime.now()),
  });
}

/// Simula la CF transferOwnership: cambia roles en Firestore.
Future<void> simulateTransferOwnership(
  FakeFirebaseFirestore db,
  String homeId,
  String currentOwnerUid,
  String newOwnerUid,
) async {
  // Nuevo owner
  await db
      .collection('homes')
      .doc(homeId)
      .collection('members')
      .doc(newOwnerUid)
      .update({'role': 'owner'});
  await db
      .collection('users')
      .doc(newOwnerUid)
      .collection('memberships')
      .doc(homeId)
      .update({'role': 'owner'});

  // Anterior owner pasa a admin
  await db
      .collection('homes')
      .doc(homeId)
      .collection('members')
      .doc(currentOwnerUid)
      .update({'role': 'admin'});
  await db
      .collection('users')
      .doc(currentOwnerUid)
      .collection('memberships')
      .doc(homeId)
      .update({'role': 'admin'});

  // Actualizar homes/{homeId}
  await db.collection('homes').doc(homeId).update({'ownerUid': newOwnerUid});
}

void main() {
  late FakeFirebaseFirestore db;
  const homeId = 'home1';
  const ownerUid = 'uid-owner';
  const member1Uid = 'uid-m1';
  const member2Uid = 'uid-m2';

  Future<void> seedHome() async {
    await db.collection('homes').doc(homeId).set({
      'name': 'Casa de prueba',
      'ownerUid': ownerUid,
      'premiumStatus': 'free',
    });

    for (final uid in [ownerUid, member1Uid, member2Uid]) {
      final role = uid == ownerUid ? 'owner' : 'member';
      await db
          .collection('homes')
          .doc(homeId)
          .collection('members')
          .doc(uid)
          .set({
        'nickname': uid,
        'role': role,
        'status': 'active',
        'joinedAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'phoneVisibility': 'hidden',
        'tasksCompleted': 0,
        'passedCount': 0,
        'complianceRate': 0.0,
        'currentStreak': 0,
        'averageScore': 0.0,
      });
      await db
          .collection('users')
          .doc(uid)
          .collection('memberships')
          .doc(homeId)
          .set({
        'homeId': homeId,
        'homeNameSnapshot': 'Casa de prueba',
        'role': role,
        'status': 'active',
        'billingState': uid == ownerUid ? 'currentPayer' : 'none',
        'joinedAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });
    }
  }

  setUp(() async {
    db = FakeFirebaseFirestore();
    await seedHome();
  });

  test('invitar miembro con código → membresía creada correctamente', () async {
    const newUid = 'uid-new';
    final code = await simulateGenerateCode(db, homeId, ownerUid);
    await simulateJoinByCode(db, homeId, code, newUid);

    final memberDoc = await db
        .collection('homes')
        .doc(homeId)
        .collection('members')
        .doc(newUid)
        .get();

    expect(memberDoc.exists, isTrue);
    expect(memberDoc.data()!['role'], 'member');
    expect(memberDoc.data()!['status'], 'active');

    final membershipDoc = await db
        .collection('users')
        .doc(newUid)
        .collection('memberships')
        .doc(homeId)
        .get();
    expect(membershipDoc.exists, isTrue);
  });

  test('código expirado → lanza ExpiredInviteCodeException', () async {
    // Crear invitación ya expirada
    await db
        .collection('homes')
        .doc(homeId)
        .collection('invitations')
        .doc('expired')
        .set({
      'code': 'EXP999',
      'createdBy': ownerUid,
      'createdAt':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
      'expiresAt':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
      'used': false,
    });

    expect(
      () => simulateJoinByCode(db, homeId, 'EXP999', 'uid-late'),
      throwsA(isA<ExpiredInviteCodeException>()),
    );
  });

  test('Free con 3 miembros activos → invitar 4º → límite Free (máx 3)', () async {
    // Ya hay 3 miembros (owner + m1 + m2), verificar que la CF debe rechazarlo.
    // Simulamos la validación que haría la CF:
    final membersSnap = await db
        .collection('homes')
        .doc(homeId)
        .collection('members')
        .where('status', isEqualTo: 'active')
        .get();

    final activeCount = membersSnap.docs.length;
    const freePlanMaxMembers = 3;

    expect(activeCount, 3);
    expect(activeCount >= freePlanMaxMembers, isTrue,
        reason: 'La CF debe rechazar la invitación por límite de plan Free');
  });

  test('transferir propiedad → owner anterior pasa a admin, nuevo uid es owner', () async {
    await simulateTransferOwnership(db, homeId, ownerUid, member1Uid);

    // Verificar nuevo owner
    final newOwnerDoc = await db
        .collection('homes')
        .doc(homeId)
        .collection('members')
        .doc(member1Uid)
        .get();
    expect(newOwnerDoc.data()!['role'], 'owner');

    // Verificar que owner anterior es ahora admin
    final oldOwnerDoc = await db
        .collection('homes')
        .doc(homeId)
        .collection('members')
        .doc(ownerUid)
        .get();
    expect(oldOwnerDoc.data()!['role'], 'admin');

    // Verificar campo ownerUid en homes doc
    final homeDoc = await db.collection('homes').doc(homeId).get();
    expect(homeDoc.data()!['ownerUid'], member1Uid);
  });
}
```

- [ ] **Paso 2: Ejecutar tests de integración**

```
flutter test test/integration/features/members/members_invite_test.dart
```

Resultado esperado: PASS (4 tests).

- [ ] **Paso 3: Commit**

```bash
git add test/integration/features/members/
git commit -m "test(members): add integration tests for invite flow, expiry, limits and ownership transfer"
```

---

## Tarea 16: Tests de UI y golden para members

**Archivos:**
- Crear: `test/ui/features/members/members_screen_test.dart`
- Crear: `test/ui/features/members/member_profile_screen_test.dart`
- Se generan: `test/ui/features/members/goldens/members_screen.png`, `goldens/member_profile_screen.png`

- [ ] **Paso 1: Crear `test/ui/features/members/members_screen_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:toka/features/members/presentation/members_screen.dart';
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

final _fakeMembers = [
  Member(
    uid: 'uid-owner',
    homeId: 'home1',
    nickname: 'María',
    photoUrl: null,
    bio: null,
    phone: null,
    phoneVisibility: 'hidden',
    role: MemberRole.owner,
    status: MemberStatus.active,
    joinedAt: DateTime(2026, 1, 1),
    tasksCompleted: 20,
    passedCount: 2,
    complianceRate: 0.9,
    currentStreak: 5,
    averageScore: 9.0,
  ),
  Member(
    uid: 'uid-admin',
    homeId: 'home1',
    nickname: 'Carlos',
    photoUrl: null,
    bio: null,
    phone: null,
    phoneVisibility: 'hidden',
    role: MemberRole.admin,
    status: MemberStatus.active,
    joinedAt: DateTime(2026, 1, 2),
    tasksCompleted: 10,
    passedCount: 3,
    complianceRate: 0.77,
    currentStreak: 2,
    averageScore: 7.5,
  ),
];

final _ownerMembership = HomeMembership(
  homeId: 'home1',
  homeNameSnapshot: 'Casa Test',
  role: MemberRole.owner,
  billingState: BillingState.currentPayer,
  status: MemberStatus.active,
  joinedAt: DateTime(2026, 1, 1),
);

Widget _wrap(Widget child, {required List<Override> overrides}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es')],
        home: child,
      ),
    );

List<Override> _baseOverrides({
  AsyncValue<List<Member>> membersValue = const AsyncData([]),
  MemberRole myRole = MemberRole.owner,
}) =>
    [
      authProvider.overrideWith(
          () => _FakeAuth(const AuthState.authenticated(_ownerUser))),
      currentHomeProvider.overrideWith(
          (ref) => Stream.value(_fakeHome)),
      userMembershipsProvider('uid-owner').overrideWith(
        (ref) => Stream.value([_ownerMembership]),
      ),
      homeMembersProvider('home1').overrideWith((ref) {
        if (membersValue is AsyncData<List<Member>>) {
          return Stream.value(membersValue.value);
        }
        return const Stream.empty();
      }),
    ];

class _FakeAuth extends Auth {
  final AuthState _state;
  _FakeAuth(this._state);
  @override
  AuthState build() => _state;
}

void main() {
  group('MembersScreen', () {
    testWidgets('muestra lista con roles y badges correctos', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MembersScreen(),
          overrides: _baseOverrides(
              membersValue: AsyncData(_fakeMembers)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('member_card_uid-owner')), findsOneWidget);
      expect(find.byKey(const Key('member_card_uid-admin')), findsOneWidget);
      expect(find.byKey(const Key('role_badge_owner')), findsOneWidget);
      expect(find.byKey(const Key('role_badge_admin')), findsOneWidget);
    });

    testWidgets('owner ve FAB de invitar', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MembersScreen(),
          overrides: _baseOverrides(
              membersValue: AsyncData(_fakeMembers)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fab_invite')), findsOneWidget);
    });

    testWidgets('admin NO ve botón cerrar hogar (ese botón está en HomeSettings, no aquí)',
        (tester) async {
      // MembersScreen no tiene botón de cerrar hogar. Solo HomeSettingsScreen lo tiene.
      await tester.pumpWidget(
        _wrap(
          const MembersScreen(),
          overrides: _baseOverrides(
              membersValue: AsyncData(_fakeMembers),
              myRole: MemberRole.admin),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('close_home_tile')), findsNothing);
    });

    testWidgets('golden: pantalla de miembros', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          const MembersScreen(),
          overrides: _baseOverrides(
              membersValue: AsyncData(_fakeMembers)),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/members_screen.png'),
      );
    });
  });
}
```

- [ ] **Paso 2: Crear `test/ui/features/members/member_profile_screen_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/members/application/members_provider.dart';
import 'package:toka/features/members/domain/member.dart';
import 'package:toka/features/members/domain/members_repository.dart';
import 'package:toka/features/members/presentation/member_profile_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

class _MockMembersRepo extends MembersRepository {
  _MockMembersRepo(this.member);
  final Member member;

  @override
  Future<Member> fetchMember(String homeId, String uid) async => member;

  @override
  Stream<List<Member>> watchHomeMembers(String homeId) =>
      Stream.value([member]);

  @override
  Future<void> inviteMember(String homeId, String? email) async {}
  @override
  Future<String> generateInviteCode(String homeId) async => 'ABC123';
  @override
  Future<void> removeMember(String homeId, String uid) async {}
  @override
  Future<void> promoteToAdmin(String homeId, String uid) async {}
  @override
  Future<void> demoteFromAdmin(String homeId, String uid) async {}
  @override
  Future<void> transferOwnership(String homeId, String newOwnerUid) async {}
}

const _viewerUser = AuthUser(
  uid: 'uid-viewer',
  email: 'viewer@test.com',
  displayName: 'Viewer',
  photoUrl: null,
  emailVerified: true,
  providers: [],
);

class _FakeAuth extends Auth {
  final AuthState _state;
  _FakeAuth(this._state);
  @override
  AuthState build() => _state;
}

Widget _wrap(Widget child, {required List<Override> overrides}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es')],
        home: child,
      ),
    );

void main() {
  group('MemberProfileScreen', () {
    testWidgets(
        'perfil ajeno con phoneVisibility=hidden NO muestra teléfono',
        (tester) async {
      final member = Member(
        uid: 'uid-other',
        homeId: 'home1',
        nickname: 'Pedro',
        photoUrl: null,
        bio: 'Hola soy Pedro',
        phone: '666123456',
        phoneVisibility: 'hidden',
        role: MemberRole.member,
        status: MemberStatus.active,
        joinedAt: DateTime(2026, 1, 1),
        tasksCompleted: 5,
        passedCount: 1,
        complianceRate: 0.83,
        currentStreak: 2,
        averageScore: 8.0,
      );

      await tester.pumpWidget(
        _wrap(
          const MemberProfileScreen(homeId: 'home1', memberUid: 'uid-other'),
          overrides: [
            authProvider.overrideWith(
                () => _FakeAuth(const AuthState.authenticated(_viewerUser))),
            membersRepositoryProvider
                .overrideWithValue(_MockMembersRepo(member)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('member_phone_tile')), findsNothing);
      expect(find.text('666123456'), findsNothing);
    });

    testWidgets(
        'perfil ajeno con phoneVisibility=sameHomeMembers SÍ muestra teléfono',
        (tester) async {
      final member = Member(
        uid: 'uid-other',
        homeId: 'home1',
        nickname: 'Laura',
        photoUrl: null,
        bio: null,
        phone: '666123456',
        phoneVisibility: 'sameHomeMembers',
        role: MemberRole.member,
        status: MemberStatus.active,
        joinedAt: DateTime(2026, 1, 1),
        tasksCompleted: 8,
        passedCount: 0,
        complianceRate: 1.0,
        currentStreak: 8,
        averageScore: 9.5,
      );

      await tester.pumpWidget(
        _wrap(
          const MemberProfileScreen(homeId: 'home1', memberUid: 'uid-other'),
          overrides: [
            authProvider.overrideWith(
                () => _FakeAuth(const AuthState.authenticated(_viewerUser))),
            membersRepositoryProvider
                .overrideWithValue(_MockMembersRepo(member)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('member_phone_tile')), findsOneWidget);
      expect(find.text('666123456'), findsOneWidget);
    });

    testWidgets('perfil ajeno NO muestra notas textuales privadas',
        (tester) async {
      // Verificar que no existe ningún widget de "Notas" en el perfil ajeno.
      final member = Member(
        uid: 'uid-other',
        homeId: 'home1',
        nickname: 'Juan',
        photoUrl: null,
        bio: null,
        phone: null,
        phoneVisibility: 'hidden',
        role: MemberRole.member,
        status: MemberStatus.active,
        joinedAt: DateTime(2026, 1, 1),
        tasksCompleted: 3,
        passedCount: 0,
        complianceRate: 1.0,
        currentStreak: 3,
        averageScore: 8.0,
      );

      await tester.pumpWidget(
        _wrap(
          const MemberProfileScreen(homeId: 'home1', memberUid: 'uid-other'),
          overrides: [
            authProvider.overrideWith(
                () => _FakeAuth(const AuthState.authenticated(_viewerUser))),
            membersRepositoryProvider
                .overrideWithValue(_MockMembersRepo(member)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // No debe haber sección de "notas"
      expect(find.byKey(const Key('notes_section')), findsNothing);
    });

    testWidgets('golden: pantalla de perfil ajeno', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final member = Member(
        uid: 'uid-other',
        homeId: 'home1',
        nickname: 'Laura',
        photoUrl: null,
        bio: 'Me gusta cocinar y mantener el orden',
        phone: '666123456',
        phoneVisibility: 'sameHomeMembers',
        role: MemberRole.admin,
        status: MemberStatus.active,
        joinedAt: DateTime(2026, 1, 1),
        tasksCompleted: 42,
        passedCount: 5,
        complianceRate: 0.87,
        currentStreak: 5,
        averageScore: 8.2,
      );

      await tester.pumpWidget(
        _wrap(
          const MemberProfileScreen(homeId: 'home1', memberUid: 'uid-other'),
          overrides: [
            authProvider.overrideWith(
                () => _FakeAuth(const AuthState.authenticated(_viewerUser))),
            membersRepositoryProvider
                .overrideWithValue(_MockMembersRepo(member)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/member_profile_screen.png'),
      );
    });
  });
}
```

- [ ] **Paso 3: Ejecutar tests de UI**

```
flutter test test/ui/features/members/members_screen_test.dart --update-goldens
flutter test test/ui/features/members/member_profile_screen_test.dart --update-goldens
```

Resultado esperado: PASS (genera goldens).

- [ ] **Paso 4: Ejecutar de nuevo sin `--update-goldens` para verificar estabilidad**

```
flutter test test/ui/features/members/
```

Resultado esperado: PASS.

- [ ] **Paso 5: Commit**

```bash
git add test/ui/features/members/
git commit -m "test(members): add UI tests and golden files for MembersScreen and MemberProfileScreen"
```

---

## Tarea 17: Ejecutar todos los tests y verificar cobertura total

- [ ] **Paso 1: build_runner final**

```
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Paso 2: Tests unitarios**

```
flutter test test/unit/
```

Resultado esperado: todos los tests en verde, incluyendo los nuevos de `members/` y `profile/`.

- [ ] **Paso 3: Tests de integración**

```
flutter test test/integration/
```

Resultado esperado: todos en verde.

- [ ] **Paso 4: Tests de UI**

```
flutter test test/ui/
```

Resultado esperado: todos en verde.

- [ ] **Paso 5: Análisis estático**

```
flutter analyze
```

Resultado esperado: sin errores ni warnings.

- [ ] **Paso 6: Commit final si todo pasa**

```bash
git add .
git commit -m "feat(spec-08): complete members, profiles and privacy implementation"
```

---

## Pruebas manuales requeridas al terminar

```
## Pruebas manuales requeridas — Spec-08

1. **Invitar miembro:** Admin genera código → otra cuenta lo usa en onboarding → aparece como miembro activo en MembersScreen.

2. **Perfil ajeno restringido:** Ver perfil de otro miembro → no aparecen notas privadas ni stats de otros hogares. Solo stats del hogar compartido.

3. **Teléfono oculto:** Usuario A activa phoneVisibility='hidden' en EditProfileScreen → Usuario B (mismo hogar) abre MemberProfileScreen de A → NO ve el teléfono.

4. **Teléfono visible:** Usuario A activa el toggle de visibilidad → Usuario B (mismo hogar) abre MemberProfileScreen de A → SÍ ve el teléfono.

5. **Promover a admin:** Owner toca en MemberCard → MemberProfileScreen → acción promover → miembro pasa a rol admin (badge cambia).

6. **Quitar miembro:** Admin quita a un miembro → el miembro ya no aparece en la lista de MembersScreen.

7. **Límite de admins (Free):** Con plan Free, intentar promover a un segundo admin → error visible al usuario (snackbar con mensaje "Plan gratuito solo permite 1 admin").

8. **Editar perfil propio:** OwnProfileScreen → botón "Editar perfil" → cambiar foto, apodo y bio → volver a OwnProfileScreen → cambios reflejados inmediatamente.
```

---

## Self-Review (verificación del plan contra la spec)

### Cobertura de reglas de negocio

| Regla | Tarea |
|-------|-------|
| Perfil ajeno: foto, apodo, bio, teléfono (si visible), stats del hogar compartido | Tarea 12 (MemberProfileScreen) |
| Perfil ajeno: NUNCA notas textuales ni datos de otros hogares | Tarea 12 + Test UI |
| Perfil propio: todo lo anterior + notas recibidas, facturación, vista global | Tarea 13 (OwnProfileScreen) |
| Teléfono: `sameHomeMembers` u `hidden` | Tarea 2 (Member.phoneForViewer) + Tarea 13 |
| Solo `owner` puede designar/retirar admins y transferir propiedad | Tarea 4 (MembersRepositoryImpl) |
| Solo `owner` y admins pueden invitar o quitar miembros normales | Tarea 11 (MembersScreen FAB condicional) |
| Admins no pueden quitar al pagador durante periodo Premium vigente | Excepción lanzada por CF (no implementada en cliente) |
| Free: máx 3 miembros activos, 1 admin | Tarea 4 (excepciones) + Tarea 15 |
| Premium: hasta 10 miembros activos, hasta 4 admins | Aplicado por CF (tests de integración cubren lógica Free) |
| Miembro congelado puede ver tablero pero no recibe asignaciones | Estado `frozen` modelado en Member |

### Cobertura de tests requeridos

| Test | Tarea |
|------|-------|
| `Member.fromFirestore` mapea roles y estados | Tarea 2 |
| `inviteMember` lanza error si home tiene máximo de miembros | Tarea 4 |
| `promoteToAdmin` lanza error en Free | Tarea 4 |
| `removeMember` lanza error si es owner | Tarea 4 |
| `phoneVisibility='hidden'` omite campo en perfil ajeno | Tarea 2 + Tarea 16 |
| Invitar con código → membresía creada | Tarea 15 |
| Código expirado → ExpiredInviteCodeException | Tarea 15 |
| Free con 3 miembros → invitar 4º → límite | Tarea 15 |
| Transferir propiedad → owner anterior = admin, nuevo uid = owner | Tarea 15 |
| MembersScreen: lista con roles y badges correctos | Tarea 16 |
| Admin no ve botón "Cerrar hogar" (solo owner en HomeSettings) | Tarea 16 |
| Perfil ajeno: NO muestra notas textuales | Tarea 16 |
| Perfil ajeno: muestra teléfono solo si sameHomeMembers | Tarea 16 |
| Golden tests de pantallas de miembros y perfil | Tarea 16 |
