# Onboarding (Spec-03) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the complete 4-step onboarding flow: Welcome → Language → Profile → Create/Join Home, with SharedPreferences resumption, Firestore profile save, Firebase Storage photo upload, and a Cloud Function call for home creation.

**Architecture:** Clean architecture per feature. Domain has two abstract repositories (`OnboardingRepository`, `HomeCreationRepository`). Data layer implements them: `OnboardingRepositoryImpl` writes to Firestore + Storage; `HomeCreationRepositoryImpl` calls the `createHome` Callable Function and queries Firestore for join-by-code. Application layer: `OnboardingState` (freezed), `OnboardingNotifier` orchestrates steps + SharedPreferences persistence, `HomeCreationProvider` exposes the repository. Presentation: `OnboardingFlowScreen` wraps a `PageView` with 4 steps, a progress bar, and navigation buttons. `app.dart` is updated to replace the placeholder.

**Tech Stack:** Flutter/Dart, Riverpod (riverpod_annotation), freezed, GoRouter, Firebase Auth, Cloud Firestore (fake_cloud_firestore for tests), Firebase Storage, Cloud Functions (cloud_functions package), shared_preferences, image_picker, mocktail.

---

## File Map

**Create:**
- `lib/features/onboarding/domain/onboarding_repository.dart` — abstract: saveProfile, markComplete
- `lib/features/onboarding/domain/home_creation_repository.dart` — abstract: createHome, joinHome
- `lib/features/onboarding/data/onboarding_repository_impl.dart` — writes `users/{uid}` + photo to Storage
- `lib/features/onboarding/data/home_creation_repository_impl.dart` — calls `createHome` CF + queries `homes/{homeId}/invitations`
- `lib/features/onboarding/application/onboarding_state.dart` — freezed `OnboardingState`
- `lib/features/onboarding/application/onboarding_provider.dart` — `OnboardingNotifier` (steps, persistence, save/create/join)
- `lib/features/onboarding/application/home_creation_provider.dart` — `homeCreationRepositoryProvider`
- `lib/features/onboarding/presentation/onboarding_flow_screen.dart` — PageView shell, checks completion on init
- `lib/features/onboarding/presentation/steps/welcome_step.dart`
- `lib/features/onboarding/presentation/steps/language_step.dart`
- `lib/features/onboarding/presentation/steps/profile_step.dart`
- `lib/features/onboarding/presentation/steps/home_choice_step.dart`
- `lib/features/onboarding/presentation/widgets/onboarding_progress_bar.dart`
- `lib/features/onboarding/presentation/widgets/home_join_form.dart`
- `test/unit/features/onboarding/onboarding_provider_test.dart`
- `test/unit/features/onboarding/home_creation_repository_test.dart`
- `test/integration/features/onboarding/home_creation_test.dart`
- `test/integration/features/onboarding/profile_save_test.dart`
- `test/ui/features/onboarding/onboarding_flow_test.dart`

**Modify:**
- `pubspec.yaml` — add `cloud_functions: ^5.1.3`
- `lib/core/errors/exceptions.dart` — add 3 onboarding exceptions
- `lib/l10n/app_es.arb` — add onboarding UI strings
- `lib/l10n/app_en.arb` — add onboarding UI strings
- `lib/l10n/app_ro.arb` — add onboarding UI strings
- `lib/app.dart` — replace `_OnboardingPlaceholder` with `OnboardingFlowScreen`

---

## Task 1: Add cloud_functions dependency + onboarding exceptions

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/core/errors/exceptions.dart`

- [ ] **Step 1: Add cloud_functions to pubspec.yaml**

In `pubspec.yaml`, under `dependencies` after `firebase_app_check`, add:
```yaml
  cloud_functions: ^5.1.3
```

- [ ] **Step 2: Add onboarding exceptions to exceptions.dart**

Append to `lib/core/errors/exceptions.dart`:
```dart
class InvalidInviteCodeException implements Exception {
  const InvalidInviteCodeException([this.message = 'Invalid invite code']);
  final String message;
  @override
  String toString() => 'InvalidInviteCodeException: $message';
}

class ExpiredInviteCodeException implements Exception {
  const ExpiredInviteCodeException([this.message = 'Invite code expired']);
  final String message;
  @override
  String toString() => 'ExpiredInviteCodeException: $message';
}

class NoHomeSlotsException implements Exception {
  const NoHomeSlotsException([this.message = 'No home slots available']);
  final String message;
  @override
  String toString() => 'NoHomeSlotsException: $message';
}
```

- [ ] **Step 3: Run flutter pub get**

```bash
flutter pub get
```
Expected: resolves packages without errors.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/core/errors/exceptions.dart
git commit -m "feat(onboarding): add cloud_functions dep and onboarding exceptions"
```

---

## Task 2: Add ARB strings (es, en, ro)

**Files:**
- Modify: `lib/l10n/app_es.arb`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_ro.arb`

- [ ] **Step 1: Add Spanish onboarding strings to app_es.arb**

In `lib/l10n/app_es.arb`, add before the closing `}`:
```json
  "onboarding_welcome_title": "Bienvenido a Toka",
  "@onboarding_welcome_title": { "description": "Onboarding step 1 title" },
  "onboarding_welcome_subtitle": "Tu app cooperativa de tareas del hogar",
  "@onboarding_welcome_subtitle": { "description": "Onboarding step 1 subtitle" },
  "onboarding_start": "Empezar",
  "@onboarding_start": { "description": "Onboarding start button" },
  "onboarding_language_title": "¿En qué idioma prefieres usar Toka?",
  "@onboarding_language_title": { "description": "Onboarding step 2 title" },
  "onboarding_profile_title": "Cuéntanos sobre ti",
  "@onboarding_profile_title": { "description": "Onboarding step 3 title" },
  "onboarding_nickname_label": "¿Cómo te llaman?",
  "@onboarding_nickname_label": { "description": "Nickname field label" },
  "onboarding_nickname_hint": "Tu apodo",
  "@onboarding_nickname_hint": { "description": "Nickname field hint" },
  "onboarding_nickname_required": "El apodo es obligatorio",
  "@onboarding_nickname_required": { "description": "Nickname required error" },
  "onboarding_nickname_max_length": "Máximo 30 caracteres",
  "@onboarding_nickname_max_length": { "description": "Nickname max length error" },
  "onboarding_phone_label": "Teléfono (opcional)",
  "@onboarding_phone_label": { "description": "Phone field label" },
  "onboarding_phone_visible_label": "Mostrar mi teléfono a miembros del hogar",
  "@onboarding_phone_visible_label": { "description": "Phone visibility toggle label" },
  "onboarding_home_choice_title": "¿Qué quieres hacer?",
  "@onboarding_home_choice_title": { "description": "Onboarding step 4 title" },
  "onboarding_create_home_description": "Crea tu hogar y añade a tus compañeros",
  "@onboarding_create_home_description": { "description": "Create home option description" },
  "onboarding_join_home_description": "Únete a un hogar con un código de invitación",
  "@onboarding_join_home_description": { "description": "Join home option description" },
  "onboarding_home_name_label": "Nombre del hogar",
  "@onboarding_home_name_label": { "description": "Home name field label" },
  "onboarding_home_name_hint": "Casa de los García",
  "@onboarding_home_name_hint": { "description": "Home name hint" },
  "onboarding_home_name_required": "El nombre del hogar es obligatorio",
  "@onboarding_home_name_required": { "description": "Home name required error" },
  "onboarding_home_name_max_length": "Máximo 40 caracteres",
  "@onboarding_home_name_max_length": { "description": "Home name max length error" },
  "onboarding_create_home_button": "Crear hogar",
  "@onboarding_create_home_button": { "description": "Create home button" },
  "onboarding_invite_code_label": "Código de invitación",
  "@onboarding_invite_code_label": { "description": "Invite code field label" },
  "onboarding_invite_code_hint": "6 caracteres",
  "@onboarding_invite_code_hint": { "description": "Invite code hint" },
  "onboarding_invite_code_length_error": "El código debe tener 6 caracteres",
  "@onboarding_invite_code_length_error": { "description": "Invite code length error" },
  "onboarding_join_home_button": "Unirme",
  "@onboarding_join_home_button": { "description": "Join home button" },
  "onboarding_error_invalid_invite": "Código de invitación inválido",
  "@onboarding_error_invalid_invite": { "description": "Invalid invite code error" },
  "onboarding_error_expired_invite": "El código de invitación ha expirado",
  "@onboarding_error_expired_invite": { "description": "Expired invite code error" },
  "onboarding_error_no_slots": "No tienes plazas disponibles para crear más hogares",
  "@onboarding_error_no_slots": { "description": "No home slots error" },
  "onboarding_add_photo": "Añadir foto",
  "@onboarding_add_photo": { "description": "Add photo button" },
  "onboarding_change_photo": "Cambiar foto",
  "@onboarding_change_photo": { "description": "Change photo button" }
```

- [ ] **Step 2: Add English onboarding strings to app_en.arb**

In `lib/l10n/app_en.arb`, add before the closing `}`:
```json
  "onboarding_welcome_title": "Welcome to Toka",
  "@onboarding_welcome_title": { "description": "Onboarding step 1 title" },
  "onboarding_welcome_subtitle": "Your cooperative household task app",
  "@onboarding_welcome_subtitle": { "description": "Onboarding step 1 subtitle" },
  "onboarding_start": "Get started",
  "@onboarding_start": { "description": "Onboarding start button" },
  "onboarding_language_title": "Which language do you prefer?",
  "@onboarding_language_title": { "description": "Onboarding step 2 title" },
  "onboarding_profile_title": "Tell us about you",
  "@onboarding_profile_title": { "description": "Onboarding step 3 title" },
  "onboarding_nickname_label": "What do people call you?",
  "@onboarding_nickname_label": { "description": "Nickname field label" },
  "onboarding_nickname_hint": "Your nickname",
  "@onboarding_nickname_hint": { "description": "Nickname field hint" },
  "onboarding_nickname_required": "Nickname is required",
  "@onboarding_nickname_required": { "description": "Nickname required error" },
  "onboarding_nickname_max_length": "Maximum 30 characters",
  "@onboarding_nickname_max_length": { "description": "Nickname max length error" },
  "onboarding_phone_label": "Phone (optional)",
  "@onboarding_phone_label": { "description": "Phone field label" },
  "onboarding_phone_visible_label": "Show my phone to household members",
  "@onboarding_phone_visible_label": { "description": "Phone visibility toggle label" },
  "onboarding_home_choice_title": "What would you like to do?",
  "@onboarding_home_choice_title": { "description": "Onboarding step 4 title" },
  "onboarding_create_home_description": "Create your home and add your housemates",
  "@onboarding_create_home_description": { "description": "Create home option description" },
  "onboarding_join_home_description": "Join a home with an invitation code",
  "@onboarding_join_home_description": { "description": "Join home option description" },
  "onboarding_home_name_label": "Home name",
  "@onboarding_home_name_label": { "description": "Home name field label" },
  "onboarding_home_name_hint": "The García Home",
  "@onboarding_home_name_hint": { "description": "Home name hint" },
  "onboarding_home_name_required": "Home name is required",
  "@onboarding_home_name_required": { "description": "Home name required error" },
  "onboarding_home_name_max_length": "Maximum 40 characters",
  "@onboarding_home_name_max_length": { "description": "Home name max length error" },
  "onboarding_create_home_button": "Create home",
  "@onboarding_create_home_button": { "description": "Create home button" },
  "onboarding_invite_code_label": "Invitation code",
  "@onboarding_invite_code_label": { "description": "Invite code field label" },
  "onboarding_invite_code_hint": "6 characters",
  "@onboarding_invite_code_hint": { "description": "Invite code hint" },
  "onboarding_invite_code_length_error": "Code must be 6 characters",
  "@onboarding_invite_code_length_error": { "description": "Invite code length error" },
  "onboarding_join_home_button": "Join",
  "@onboarding_join_home_button": { "description": "Join home button" },
  "onboarding_error_invalid_invite": "Invalid invitation code",
  "@onboarding_error_invalid_invite": { "description": "Invalid invite code error" },
  "onboarding_error_expired_invite": "Invitation code has expired",
  "@onboarding_error_expired_invite": { "description": "Expired invite code error" },
  "onboarding_error_no_slots": "No home slots available",
  "@onboarding_error_no_slots": { "description": "No home slots error" },
  "onboarding_add_photo": "Add photo",
  "@onboarding_add_photo": { "description": "Add photo button" },
  "onboarding_change_photo": "Change photo",
  "@onboarding_change_photo": { "description": "Change photo button" }
```

- [ ] **Step 3: Add Romanian onboarding strings to app_ro.arb**

In `lib/l10n/app_ro.arb`, add before the closing `}`:
```json
  "onboarding_welcome_title": "Bun venit la Toka",
  "@onboarding_welcome_title": { "description": "Onboarding step 1 title" },
  "onboarding_welcome_subtitle": "Aplicația ta cooperativă de gestionare a sarcinilor",
  "@onboarding_welcome_subtitle": { "description": "Onboarding step 1 subtitle" },
  "onboarding_start": "Începe",
  "@onboarding_start": { "description": "Onboarding start button" },
  "onboarding_language_title": "Ce limbă preferi?",
  "@onboarding_language_title": { "description": "Onboarding step 2 title" },
  "onboarding_profile_title": "Spune-ne despre tine",
  "@onboarding_profile_title": { "description": "Onboarding step 3 title" },
  "onboarding_nickname_label": "Cum te strigă lumea?",
  "@onboarding_nickname_label": { "description": "Nickname field label" },
  "onboarding_nickname_hint": "Porecla ta",
  "@onboarding_nickname_hint": { "description": "Nickname field hint" },
  "onboarding_nickname_required": "Porecla este obligatorie",
  "@onboarding_nickname_required": { "description": "Nickname required error" },
  "onboarding_nickname_max_length": "Maximum 30 de caractere",
  "@onboarding_nickname_max_length": { "description": "Nickname max length error" },
  "onboarding_phone_label": "Telefon (opțional)",
  "@onboarding_phone_label": { "description": "Phone field label" },
  "onboarding_phone_visible_label": "Arată numărul meu membrilor locuinței",
  "@onboarding_phone_visible_label": { "description": "Phone visibility toggle label" },
  "onboarding_home_choice_title": "Ce vrei să faci?",
  "@onboarding_home_choice_title": { "description": "Onboarding step 4 title" },
  "onboarding_create_home_description": "Creează-ți locuința și adaugă-ți colegii",
  "@onboarding_create_home_description": { "description": "Create home option description" },
  "onboarding_join_home_description": "Alătură-te unei locuințe cu un cod de invitație",
  "@onboarding_join_home_description": { "description": "Join home option description" },
  "onboarding_home_name_label": "Numele locuinței",
  "@onboarding_home_name_label": { "description": "Home name field label" },
  "onboarding_home_name_hint": "Locuința García",
  "@onboarding_home_name_hint": { "description": "Home name hint" },
  "onboarding_home_name_required": "Numele locuinței este obligatoriu",
  "@onboarding_home_name_required": { "description": "Home name required error" },
  "onboarding_home_name_max_length": "Maximum 40 de caractere",
  "@onboarding_home_name_max_length": { "description": "Home name max length error" },
  "onboarding_create_home_button": "Creează locuința",
  "@onboarding_create_home_button": { "description": "Create home button" },
  "onboarding_invite_code_label": "Cod de invitație",
  "@onboarding_invite_code_label": { "description": "Invite code field label" },
  "onboarding_invite_code_hint": "6 caractere",
  "@onboarding_invite_code_hint": { "description": "Invite code hint" },
  "onboarding_invite_code_length_error": "Codul trebuie să aibă 6 caractere",
  "@onboarding_invite_code_length_error": { "description": "Invite code length error" },
  "onboarding_join_home_button": "Alătură-te",
  "@onboarding_join_home_button": { "description": "Join home button" },
  "onboarding_error_invalid_invite": "Cod de invitație invalid",
  "@onboarding_error_invalid_invite": { "description": "Invalid invite code error" },
  "onboarding_error_expired_invite": "Codul de invitație a expirat",
  "@onboarding_error_expired_invite": { "description": "Expired invite code error" },
  "onboarding_error_no_slots": "Nu mai ai locuri disponibile pentru locuințe",
  "@onboarding_error_no_slots": { "description": "No home slots error" },
  "onboarding_add_photo": "Adaugă fotografie",
  "@onboarding_add_photo": { "description": "Add photo button" },
  "onboarding_change_photo": "Schimbă fotografia",
  "@onboarding_change_photo": { "description": "Change photo button" }
```

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/
git commit -m "feat(onboarding): add onboarding ARB strings (es, en, ro)"
```

---

## Task 3: Domain layer

**Files:**
- Create: `lib/features/onboarding/domain/onboarding_repository.dart`
- Create: `lib/features/onboarding/domain/home_creation_repository.dart`

- [ ] **Step 1: Create onboarding_repository.dart**

```dart
// lib/features/onboarding/domain/onboarding_repository.dart
abstract class OnboardingRepository {
  /// Saves the user profile to Firestore and optionally uploads a photo to Storage.
  /// Returns the final photoUrl (null if no photo was provided).
  Future<String?> saveProfile({
    required String uid,
    required String nickname,
    String? phoneNumber,
    required bool phoneVisible,
    String? photoLocalPath,
    required String locale,
  });
}
```

- [ ] **Step 2: Create home_creation_repository.dart**

```dart
// lib/features/onboarding/domain/home_creation_repository.dart

/// Thrown when the invite code does not match any invitation.
class InvalidInviteCodeException implements Exception {
  const InvalidInviteCodeException();
}

/// Thrown when a matching invitation has passed its expiry date.
class ExpiredInviteCodeException implements Exception {
  const ExpiredInviteCodeException();
}

/// Thrown when the user has no remaining home slots.
class NoHomeSlotsException implements Exception {
  const NoHomeSlotsException();
}

abstract class HomeCreationRepository {
  /// Calls the `createHome` Cloud Function.
  /// Returns the newly created homeId.
  /// Throws [NoHomeSlotsException] if the user has no slots.
  Future<String> createHome({required String name, String? emoji});

  /// Validates the invite code and, if valid, creates the membership.
  /// Returns the homeId.
  /// Throws [InvalidInviteCodeException] or [ExpiredInviteCodeException].
  Future<String> joinHome({required String code});
}
```

Note: We define the exceptions in the domain layer (near the repository interface) rather than duplicating them from `exceptions.dart`. The ones added in Task 1 to `exceptions.dart` are the data-layer internal exceptions; these domain-layer ones are what callers catch.

Actually, to avoid confusion, let's keep exceptions in `lib/core/errors/exceptions.dart` and just import them in the domain file:

```dart
// lib/features/onboarding/domain/home_creation_repository.dart
import '../../../core/errors/exceptions.dart';

export '../../../core/errors/exceptions.dart'
    show
        InvalidInviteCodeException,
        ExpiredInviteCodeException,
        NoHomeSlotsException;

abstract class HomeCreationRepository {
  /// Calls the `createHome` Cloud Function.
  /// Returns the newly created homeId.
  /// Throws [NoHomeSlotsException] if the user has no slots.
  Future<String> createHome({required String name, String? emoji});

  /// Validates the invite code and, if valid, creates the membership.
  /// Returns the homeId.
  /// Throws [InvalidInviteCodeException] or [ExpiredInviteCodeException].
  Future<String> joinHome({required String code});
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/onboarding/domain/
git commit -m "feat(onboarding): add domain repository interfaces"
```

---

## Task 4: OnboardingState (freezed) + build_runner

**Files:**
- Create: `lib/features/onboarding/application/onboarding_state.dart`
- Generated: `lib/features/onboarding/application/onboarding_state.freezed.dart`

- [ ] **Step 1: Create onboarding_state.dart**

```dart
// lib/features/onboarding/application/onboarding_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_state.freezed.dart';

@freezed
class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default(0) int currentStep,
    @Default(4) int totalSteps,
    String? selectedLocale,
    String? nickname,
    String? phoneNumber,
    @Default(false) bool phoneVisible,
    String? photoLocalPath,
    String? photoUrl,
    @Default(false) bool isLoading,
    String? error,
  }) = _OnboardingState;
}
```

- [ ] **Step 2: Run build_runner**

```bash
dart run build_runner build --delete-conflicting-outputs
```
Expected: generates `onboarding_state.freezed.dart` without errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/onboarding/application/
git commit -m "feat(onboarding): add OnboardingState freezed model"
```

---

## Task 5: OnboardingProvider + HomeCreationProvider

**Files:**
- Create: `lib/features/onboarding/application/onboarding_provider.dart`
- Create: `lib/features/onboarding/application/home_creation_provider.dart`
- Generated: `lib/features/onboarding/application/onboarding_provider.g.dart`
- Generated: `lib/features/onboarding/application/home_creation_provider.g.dart`

- [ ] **Step 1: Create home_creation_provider.dart**

```dart
// lib/features/onboarding/application/home_creation_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/home_creation_repository_impl.dart';
import '../domain/home_creation_repository.dart';

part 'home_creation_provider.g.dart';

@Riverpod(keepAlive: true)
HomeCreationRepository homeCreationRepository(HomeCreationRepositoryRef ref) {
  return HomeCreationRepositoryImpl(
    functions: FirebaseFunctions.instance,
    firestore: FirebaseFirestore.instance,
  );
}
```

- [ ] **Step 2: Create onboarding_provider.dart**

```dart
// lib/features/onboarding/application/onboarding_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/exceptions.dart';
import '../data/onboarding_repository_impl.dart';
import '../domain/home_creation_repository.dart';
import '../domain/onboarding_repository.dart';
import 'home_creation_provider.dart';
import 'onboarding_state.dart';

part 'onboarding_provider.g.dart';

// SharedPreferences keys
const _kStep = 'onboarding_step';
const _kLocale = 'onboarding_locale';
const _kNickname = 'onboarding_nickname';
const _kPhone = 'onboarding_phone';
const _kPhoneVisible = 'onboarding_phone_visible';
const _kCompleted = 'onboarding_completed';

@Riverpod(keepAlive: true)
OnboardingRepository onboardingRepository(OnboardingRepositoryRef ref) {
  return OnboardingRepositoryImpl(
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
  );
}

@Riverpod(keepAlive: true)
class OnboardingNotifier extends _$OnboardingNotifier {
  OnboardingRepository get _repo => ref.read(onboardingRepositoryProvider);
  HomeCreationRepository get _homeRepo =>
      ref.read(homeCreationRepositoryProvider);

  @override
  OnboardingState build() => const OnboardingState();

  /// Load persisted progress from SharedPreferences.
  Future<void> loadSavedProgress() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      currentStep: prefs.getInt(_kStep) ?? 0,
      selectedLocale: prefs.getString(_kLocale),
      nickname: prefs.getString(_kNickname),
      phoneNumber: prefs.getString(_kPhone),
      phoneVisible: prefs.getBool(_kPhoneVisible) ?? false,
    );
  }

  /// Returns true if onboarding was already completed.
  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kCompleted) ?? false;
  }

  void nextStep() {
    if (state.currentStep < state.totalSteps - 1) {
      final next = state.currentStep + 1;
      state = state.copyWith(currentStep: next, error: null);
      _persistStep(next);
    }
  }

  void prevStep() {
    if (state.currentStep > 0) {
      final prev = state.currentStep - 1;
      state = state.copyWith(currentStep: prev, error: null);
      _persistStep(prev);
    }
  }

  void setLocale(String code) {
    state = state.copyWith(selectedLocale: code);
    _persistLocale(code);
  }

  void setNickname(String name) {
    state = state.copyWith(nickname: name);
  }

  void setPhoneNumber(String? phone) {
    state = state.copyWith(phoneNumber: phone);
  }

  void setPhoneVisible(bool visible) {
    state = state.copyWith(phoneVisible: visible);
  }

  void setPhotoLocalPath(String? path) {
    state = state.copyWith(photoLocalPath: path);
  }

  /// Validates and saves profile data. Throws if nickname is empty.
  Future<void> saveProfileAndContinue() async {
    final nickname = state.nickname?.trim() ?? '';
    if (nickname.isEmpty) {
      state = state.copyWith(error: 'nickname_required');
      return;
    }
    if (nickname.length > 30) {
      state = state.copyWith(error: 'nickname_max_length');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw const AuthException('No authenticated user');

      final photoUrl = await _repo.saveProfile(
        uid: uid,
        nickname: nickname,
        phoneNumber: state.phoneNumber,
        phoneVisible: state.phoneVisible,
        photoLocalPath: state.photoLocalPath,
        locale: state.selectedLocale ?? 'es',
      );
      state = state.copyWith(
        isLoading: false,
        photoUrl: photoUrl,
        error: null,
      );
      await _persistNickname(nickname);
      nextStep();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Creates a new home via Cloud Function. Returns homeId on success.
  Future<String?> createHome(String name, String? emoji) async {
    if (name.trim().isEmpty) {
      state = state.copyWith(error: 'home_name_required');
      return null;
    }
    if (name.trim().length > 40) {
      state = state.copyWith(error: 'home_name_max_length');
      return null;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final homeId = await _homeRepo.createHome(
        name: name.trim(),
        emoji: emoji,
      );
      await _markCompleted();
      state = state.copyWith(isLoading: false, error: null);
      return homeId;
    } on NoHomeSlotsException {
      state = state.copyWith(isLoading: false, error: 'no_slots');
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Joins an existing home by invite code. Returns homeId on success.
  Future<String?> joinHome(String code) async {
    if (code.trim().length != 6) {
      state = state.copyWith(error: 'invite_code_length');
      return null;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final homeId = await _homeRepo.joinHome(code: code.trim().toUpperCase());
      await _markCompleted();
      state = state.copyWith(isLoading: false, error: null);
      return homeId;
    } on InvalidInviteCodeException {
      state = state.copyWith(isLoading: false, error: 'invalid_invite');
      return null;
    } on ExpiredInviteCodeException {
      state = state.copyWith(isLoading: false, error: 'expired_invite');
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<void> _persistStep(int step) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kStep, step);
  }

  Future<void> _persistLocale(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocale, code);
  }

  Future<void> _persistNickname(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNickname, name);
  }

  Future<void> _markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCompleted, true);
  }
}
```

- [ ] **Step 3: Run build_runner**

```bash
dart run build_runner build --delete-conflicting-outputs
```
Expected: generates `onboarding_provider.g.dart` and `home_creation_provider.g.dart`.

- [ ] **Step 4: Commit**

```bash
git add lib/features/onboarding/application/
git commit -m "feat(onboarding): add OnboardingNotifier and HomeCreationProvider"
```

---

## Task 6: Data layer — OnboardingRepositoryImpl

**Files:**
- Create: `lib/features/onboarding/data/onboarding_repository_impl.dart`

- [ ] **Step 1: Create onboarding_repository_impl.dart**

```dart
// lib/features/onboarding/data/onboarding_repository_impl.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../domain/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  @override
  Future<String?> saveProfile({
    required String uid,
    required String nickname,
    String? phoneNumber,
    required bool phoneVisible,
    String? photoLocalPath,
    required String locale,
  }) async {
    String? photoUrl;

    if (photoLocalPath != null) {
      final ref = _storage.ref('users/$uid/profile.jpg');
      await ref.putFile(File(photoLocalPath));
      photoUrl = await ref.getDownloadURL();
    }

    final data = <String, dynamic>{
      'nickname': nickname,
      'locale': locale,
      'phoneVisibility': phoneVisible ? 'members' : 'hidden',
    };
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      data['phoneNumber'] = phoneNumber;
    }
    if (photoUrl != null) {
      data['photoUrl'] = photoUrl;
    }

    await _firestore
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: true));

    return photoUrl;
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/onboarding/data/onboarding_repository_impl.dart
git commit -m "feat(onboarding): add OnboardingRepositoryImpl"
```

---

## Task 7: Data layer — HomeCreationRepositoryImpl

**Files:**
- Create: `lib/features/onboarding/data/home_creation_repository_impl.dart`

- [ ] **Step 1: Create home_creation_repository_impl.dart**

```dart
// lib/features/onboarding/data/home_creation_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/errors/exceptions.dart';
import '../domain/home_creation_repository.dart';

class HomeCreationRepositoryImpl implements HomeCreationRepository {
  HomeCreationRepositoryImpl({
    required FirebaseFunctions functions,
    required FirebaseFirestore firestore,
  })  : _functions = functions,
        _firestore = firestore;

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  @override
  Future<String> createHome({required String name, String? emoji}) async {
    try {
      final callable = _functions.httpsCallable('createHome');
      final result = await callable.call<Map<String, dynamic>>({
        'name': name,
        if (emoji != null) 'emoji': emoji,
      });
      final data = result.data;
      return data['homeId'] as String;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') throw const NoHomeSlotsException();
      rethrow;
    }
  }

  @override
  Future<String> joinHome({required String code}) async {
    // Find invitation across all homes
    final query = await _firestore
        .collectionGroup('invitations')
        .where('code', isEqualTo: code)
        .where('used', isEqualTo: false)
        .limit(1)
        .get();

    if (query.docs.isEmpty) throw const InvalidInviteCodeException();

    final doc = query.docs.first;
    final data = doc.data();

    final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
    if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
      throw const ExpiredInviteCodeException();
    }

    // Extract homeId from document path: homes/{homeId}/invitations/{invId}
    final homeId = doc.reference.parent.parent!.id;

    // Mark invitation as used and create membership via callable
    final callable = _functions.httpsCallable('joinHome');
    await callable.call<void>({'homeId': homeId, 'invitationId': doc.id});

    return homeId;
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/onboarding/data/home_creation_repository_impl.dart
git commit -m "feat(onboarding): add HomeCreationRepositoryImpl"
```

---

## Task 8: Presentation — progress bar + welcome step

**Files:**
- Create: `lib/features/onboarding/presentation/widgets/onboarding_progress_bar.dart`
- Create: `lib/features/onboarding/presentation/steps/welcome_step.dart`

- [ ] **Step 1: Create onboarding_progress_bar.dart**

```dart
// lib/features/onboarding/presentation/widgets/onboarding_progress_bar.dart
import 'package:flutter/material.dart';

class OnboardingProgressBar extends StatelessWidget {
  const OnboardingProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      key: const Key('onboarding_progress_bar'),
      value: totalSteps > 0 ? (currentStep + 1) / totalSteps : 0,
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      color: Theme.of(context).colorScheme.primary,
      minHeight: 4,
    );
  }
}
```

- [ ] **Step 2: Create welcome_step.dart**

```dart
// lib/features/onboarding/presentation/steps/welcome_step.dart
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.home_rounded, size: 96),
            const SizedBox(height: 32),
            Text(
              l10n.onboarding_welcome_title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.onboarding_welcome_subtitle,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            FilledButton(
              key: const Key('start_button'),
              onPressed: onStart,
              child: Text(l10n.onboarding_start),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/onboarding/presentation/
git commit -m "feat(onboarding): add progress bar and welcome step"
```

---

## Task 9: Presentation — language step

**Files:**
- Create: `lib/features/onboarding/presentation/steps/language_step.dart`

- [ ] **Step 1: Create language_step.dart**

```dart
// lib/features/onboarding/presentation/steps/language_step.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/i18n/application/language_provider.dart';
import '../../../../l10n/app_localizations.dart';

class LanguageStep extends ConsumerWidget {
  const LanguageStep({
    super.key,
    required this.selectedLocale,
    required this.onLocaleSelected,
    required this.onNext,
    required this.onPrev,
  });

  final String? selectedLocale;
  final ValueChanged<String> onLocaleSelected;
  final VoidCallback onNext;
  final VoidCallback onPrev;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final languagesAsync = ref.watch(availableLanguagesProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              l10n.onboarding_language_title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: languagesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(child: Text(l10n.error_generic)),
                data: (languages) => ListView.builder(
                  key: const Key('language_list'),
                  itemCount: languages.length,
                  itemBuilder: (context, i) {
                    final lang = languages[i];
                    return RadioListTile<String>(
                      key: Key('lang_${lang.code}'),
                      value: lang.code,
                      groupValue: selectedLocale,
                      onChanged: (v) => onLocaleSelected(v!),
                      title: Text('${lang.flag}  ${lang.name}'),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton(
                  key: const Key('prev_button'),
                  onPressed: onPrev,
                  child: Text(l10n.back),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const Key('next_button'),
                    onPressed: onNext,
                    child: Text(l10n.next),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/onboarding/presentation/steps/language_step.dart
git commit -m "feat(onboarding): add language step"
```

---

## Task 10: Presentation — profile step

**Files:**
- Create: `lib/features/onboarding/presentation/steps/profile_step.dart`

- [ ] **Step 1: Create profile_step.dart**

```dart
// lib/features/onboarding/presentation/steps/profile_step.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../l10n/app_localizations.dart';

class ProfileStep extends StatefulWidget {
  const ProfileStep({
    super.key,
    required this.nickname,
    required this.phoneNumber,
    required this.phoneVisible,
    required this.photoLocalPath,
    required this.isLoading,
    required this.error,
    required this.onNicknameChanged,
    required this.onPhoneChanged,
    required this.onPhoneVisibleChanged,
    required this.onPhotoChanged,
    required this.onNext,
    required this.onPrev,
  });

  final String? nickname;
  final String? phoneNumber;
  final bool phoneVisible;
  final String? photoLocalPath;
  final bool isLoading;
  final String? error;
  final ValueChanged<String> onNicknameChanged;
  final ValueChanged<String?> onPhoneChanged;
  final ValueChanged<bool> onPhoneVisibleChanged;
  final ValueChanged<String?> onPhotoChanged;
  final VoidCallback onNext;
  final VoidCallback onPrev;

  @override
  State<ProfileStep> createState() => _ProfileStepState();
}

class _ProfileStepState extends State<ProfileStep> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nicknameCtrl;
  late final TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    _nicknameCtrl = TextEditingController(text: widget.nickname ?? '');
    _phoneCtrl = TextEditingController(text: widget.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) widget.onPhotoChanged(picked.path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                l10n.onboarding_profile_title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  key: const Key('avatar_picker'),
                  onTap: _pickPhoto,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage: widget.photoLocalPath != null
                        ? FileImage(File(widget.photoLocalPath!))
                        : null,
                    child: widget.photoLocalPath == null
                        ? const Icon(Icons.add_a_photo, size: 32)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _pickPhoto,
                  child: Text(widget.photoLocalPath == null
                      ? l10n.onboarding_add_photo
                      : l10n.onboarding_change_photo),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('nickname_field'),
                controller: _nicknameCtrl,
                maxLength: 30,
                inputFormatters: [LengthLimitingTextInputFormatter(30)],
                decoration: InputDecoration(
                  labelText: l10n.onboarding_nickname_label,
                  hintText: l10n.onboarding_nickname_hint,
                ),
                onChanged: widget.onNicknameChanged,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return l10n.onboarding_nickname_required;
                  }
                  if (v.trim().length > 30) {
                    return l10n.onboarding_nickname_max_length;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('phone_field'),
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.onboarding_phone_label,
                ),
                onChanged: (v) =>
                    widget.onPhoneChanged(v.isEmpty ? null : v),
              ),
              SwitchListTile(
                key: const Key('phone_visible_toggle'),
                value: widget.phoneVisible,
                onChanged: widget.onPhoneVisibleChanged,
                title: Text(l10n.onboarding_phone_visible_label),
                contentPadding: EdgeInsets.zero,
              ),
              if (widget.error != null && widget.error == 'nickname_required')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.onboarding_nickname_required,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error),
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  OutlinedButton(
                    key: const Key('prev_button'),
                    onPressed: widget.isLoading ? null : widget.onPrev,
                    child: Text(l10n.back),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      key: const Key('next_button'),
                      onPressed: widget.isLoading
                          ? null
                          : () {
                              if (_formKey.currentState?.validate() ?? false) {
                                widget.onNext();
                              }
                            },
                      child: widget.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.next),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/onboarding/presentation/steps/profile_step.dart
git commit -m "feat(onboarding): add profile step with photo picker"
```

---

## Task 11: Presentation — home choice step + join form

**Files:**
- Create: `lib/features/onboarding/presentation/widgets/home_join_form.dart`
- Create: `lib/features/onboarding/presentation/steps/home_choice_step.dart`

- [ ] **Step 1: Create home_join_form.dart**

```dart
// lib/features/onboarding/presentation/widgets/home_join_form.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';

class HomeJoinForm extends StatefulWidget {
  const HomeJoinForm({
    super.key,
    required this.isLoading,
    required this.error,
    required this.onJoin,
    required this.onBack,
  });

  final bool isLoading;
  final String? error;
  final ValueChanged<String> onJoin;
  final VoidCallback onBack;

  @override
  State<HomeJoinForm> createState() => _HomeJoinFormState();
}

class _HomeJoinFormState extends State<HomeJoinForm> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('invite_code_field'),
            controller: _codeCtrl,
            maxLength: 6,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              LengthLimitingTextInputFormatter(6),
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
            ],
            decoration: InputDecoration(
              labelText: l10n.onboarding_invite_code_label,
              hintText: l10n.onboarding_invite_code_hint,
            ),
            validator: (v) {
              if (v == null || v.trim().length != 6) {
                return l10n.onboarding_invite_code_length_error;
              }
              return null;
            },
          ),
          if (widget.error == 'invalid_invite')
            Text(l10n.onboarding_error_invalid_invite,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.error)),
          if (widget.error == 'expired_invite')
            Text(l10n.onboarding_error_expired_invite,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton(
                key: const Key('join_back_button'),
                onPressed: widget.isLoading ? null : widget.onBack,
                child: Text(l10n.back),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  key: const Key('join_button'),
                  onPressed: widget.isLoading
                      ? null
                      : () {
                          if (_formKey.currentState?.validate() ?? false) {
                            widget.onJoin(_codeCtrl.text.trim().toUpperCase());
                          }
                        },
                  child: widget.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.onboarding_join_home_button),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Create home_choice_step.dart**

```dart
// lib/features/onboarding/presentation/steps/home_choice_step.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../widgets/home_join_form.dart';

enum _HomeChoice { none, create, join }

class HomeChoiceStep extends StatefulWidget {
  const HomeChoiceStep({
    super.key,
    required this.isLoading,
    required this.error,
    required this.onCreateHome,
    required this.onJoinHome,
    required this.onPrev,
  });

  final bool isLoading;
  final String? error;
  final Future<void> Function(String name, String? emoji) onCreateHome;
  final Future<void> Function(String code) onJoinHome;
  final VoidCallback onPrev;

  @override
  State<HomeChoiceStep> createState() => _HomeChoiceStepState();
}

class _HomeChoiceStepState extends State<HomeChoiceStep> {
  _HomeChoice _choice = _HomeChoice.none;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              l10n.onboarding_home_choice_title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_choice == _HomeChoice.none) ...[
              _ChoiceCard(
                key: const Key('create_home_card'),
                icon: Icons.home_rounded,
                title: l10n.onboarding_create_home,
                description: l10n.onboarding_create_home_description,
                onTap: () => setState(() => _choice = _HomeChoice.create),
              ),
              const SizedBox(height: 16),
              _ChoiceCard(
                key: const Key('join_home_card'),
                icon: Icons.group_rounded,
                title: l10n.onboarding_join_home,
                description: l10n.onboarding_join_home_description,
                onTap: () => setState(() => _choice = _HomeChoice.join),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                key: const Key('prev_button'),
                onPressed: widget.onPrev,
                child: Text(l10n.back),
              ),
            ] else if (_choice == _HomeChoice.create) ...[
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      key: const Key('home_name_field'),
                      controller: _nameCtrl,
                      maxLength: 40,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(40)
                      ],
                      decoration: InputDecoration(
                        labelText: l10n.onboarding_home_name_label,
                        hintText: l10n.onboarding_home_name_hint,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.onboarding_home_name_required;
                        }
                        if (v.trim().length > 40) {
                          return l10n.onboarding_home_name_max_length;
                        }
                        return null;
                      },
                    ),
                    if (widget.error == 'home_name_required')
                      Text(l10n.onboarding_home_name_required,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                    if (widget.error == 'no_slots')
                      Text(l10n.onboarding_error_no_slots,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        OutlinedButton(
                          key: const Key('create_back_button'),
                          onPressed: widget.isLoading
                              ? null
                              : () => setState(
                                  () => _choice = _HomeChoice.none),
                          child: Text(l10n.back),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            key: const Key('create_home_button'),
                            onPressed: widget.isLoading
                                ? null
                                : () {
                                    if (_formKey.currentState?.validate() ??
                                        false) {
                                      widget.onCreateHome(
                                          _nameCtrl.text.trim(), null);
                                    }
                                  },
                            child: widget.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Text(l10n.onboarding_create_home_button),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              HomeJoinForm(
                isLoading: widget.isLoading,
                error: widget.error,
                onJoin: widget.onJoinHome,
                onBack: () => setState(() => _choice = _HomeChoice.none),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(description,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/onboarding/presentation/widgets/ lib/features/onboarding/presentation/steps/home_choice_step.dart
git commit -m "feat(onboarding): add home choice step and join form widget"
```

---

## Task 12: Presentation — OnboardingFlowScreen

**Files:**
- Create: `lib/features/onboarding/presentation/onboarding_flow_screen.dart`

- [ ] **Step 1: Create onboarding_flow_screen.dart**

```dart
// lib/features/onboarding/presentation/onboarding_flow_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../features/i18n/application/locale_provider.dart';
import '../application/onboarding_provider.dart';
import 'steps/home_choice_step.dart';
import 'steps/language_step.dart';
import 'steps/profile_step.dart';
import 'steps/welcome_step.dart';
import 'widgets/onboarding_progress_bar.dart';

class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState
    extends ConsumerState<OnboardingFlowScreen> {
  final _pageController = PageController();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // If onboarding was already completed, skip to home
    final done = await OnboardingNotifier.isCompleted();
    if (done && mounted) {
      context.go(AppRoutes.home);
      return;
    }
    // Restore progress
    await ref.read(onboardingNotifierProvider.notifier).loadSavedProgress();
    if (mounted) {
      setState(() => _initialized = true);
      final step =
          ref.read(onboardingNotifierProvider).currentStep;
      if (step > 0) {
        _pageController.jumpToPage(step);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final state = ref.watch(onboardingNotifierProvider);
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    ref.listen<int>(
      onboardingNotifierProvider.select((s) => s.currentStep),
      (_, step) => _goToPage(step),
    );

    return Scaffold(
      body: Column(
        children: [
          OnboardingProgressBar(
            currentStep: state.currentStep,
            totalSteps: state.totalSteps,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // Step 0: Welcome
                WelcomeStep(onStart: notifier.nextStep),

                // Step 1: Language
                LanguageStep(
                  selectedLocale: state.selectedLocale,
                  onLocaleSelected: (code) {
                    notifier.setLocale(code);
                    ref
                        .read(localeNotifierProvider.notifier)
                        .setLocale(code, null);
                  },
                  onNext: notifier.nextStep,
                  onPrev: notifier.prevStep,
                ),

                // Step 2: Profile
                ProfileStep(
                  nickname: state.nickname,
                  phoneNumber: state.phoneNumber,
                  phoneVisible: state.phoneVisible,
                  photoLocalPath: state.photoLocalPath,
                  isLoading: state.isLoading,
                  error: state.error,
                  onNicknameChanged: notifier.setNickname,
                  onPhoneChanged: notifier.setPhoneNumber,
                  onPhoneVisibleChanged: notifier.setPhoneVisible,
                  onPhotoChanged: notifier.setPhotoLocalPath,
                  onNext: () async {
                    await notifier.saveProfileAndContinue();
                  },
                  onPrev: notifier.prevStep,
                ),

                // Step 3: Home choice
                HomeChoiceStep(
                  isLoading: state.isLoading,
                  error: state.error,
                  onCreateHome: (name, emoji) async {
                    final homeId = await notifier.createHome(name, emoji);
                    if (homeId != null && mounted) {
                      context.go(AppRoutes.home);
                    }
                  },
                  onJoinHome: (code) async {
                    final homeId = await notifier.joinHome(code);
                    if (homeId != null && mounted) {
                      context.go(AppRoutes.home);
                    }
                  },
                  onPrev: notifier.prevStep,
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

- [ ] **Step 2: Commit**

```bash
git add lib/features/onboarding/presentation/onboarding_flow_screen.dart
git commit -m "feat(onboarding): add OnboardingFlowScreen"
```

---

## Task 13: Wire up app.dart

**Files:**
- Modify: `lib/app.dart`

- [ ] **Step 1: Replace OnboardingPlaceholder in app.dart**

Remove the `_OnboardingPlaceholder` class and its GoRoute builder, replacing it with `OnboardingFlowScreen`.

Add import at the top of `lib/app.dart` (after existing imports):
```dart
import 'features/onboarding/presentation/onboarding_flow_screen.dart';
```

Change the onboarding GoRoute builder from:
```dart
GoRoute(
  path: AppRoutes.onboarding,
  builder: (_, __) => const _OnboardingPlaceholder(),
),
```
to:
```dart
GoRoute(
  path: AppRoutes.onboarding,
  builder: (_, __) => const OnboardingFlowScreen(),
),
```

Delete the `_OnboardingPlaceholder` class entirely.

- [ ] **Step 2: Run build_runner one more time to catch any new generated files**

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 3: Run flutter analyze**

```bash
flutter analyze
```
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/app.dart
git commit -m "feat(onboarding): wire OnboardingFlowScreen into app router"
```

---

## Task 14: Unit tests — OnboardingNotifier

**Files:**
- Create: `test/unit/features/onboarding/onboarding_provider_test.dart`

- [ ] **Step 1: Create onboarding_provider_test.dart**

```dart
// test/unit/features/onboarding/onboarding_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/features/onboarding/application/onboarding_provider.dart';
import 'package:toka/features/onboarding/application/onboarding_state.dart';
import 'package:toka/features/onboarding/domain/home_creation_repository.dart';
import 'package:toka/features/onboarding/domain/onboarding_repository.dart';
import 'package:toka/core/errors/exceptions.dart';

class _MockOnboardingRepo extends Mock implements OnboardingRepository {}
class _MockHomeCreationRepo extends Mock implements HomeCreationRepository {}

ProviderContainer _makeContainer({
  OnboardingRepository? onboardingRepo,
  HomeCreationRepository? homeRepo,
}) {
  return ProviderContainer(
    overrides: [
      if (onboardingRepo != null)
        onboardingRepositoryProvider.overrideWithValue(onboardingRepo),
      if (homeRepo != null)
        homeCreationRepositoryProvider.overrideWithValue(homeRepo),
    ],
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {});

  test('initial state is step 0', () {
    final c = _makeContainer();
    addTearDown(c.dispose);
    expect(c.read(onboardingNotifierProvider).currentStep, 0);
  });

  test('nextStep increments currentStep', () {
    final c = _makeContainer();
    addTearDown(c.dispose);
    c.read(onboardingNotifierProvider.notifier).nextStep();
    expect(c.read(onboardingNotifierProvider).currentStep, 1);
  });

  test('prevStep decrements currentStep', () {
    final c = _makeContainer();
    addTearDown(c.dispose);
    // Go to step 2 first
    c.read(onboardingNotifierProvider.notifier).nextStep();
    c.read(onboardingNotifierProvider.notifier).nextStep();
    c.read(onboardingNotifierProvider.notifier).prevStep();
    expect(c.read(onboardingNotifierProvider).currentStep, 1);
  });

  test('prevStep does not go below 0', () {
    final c = _makeContainer();
    addTearDown(c.dispose);
    c.read(onboardingNotifierProvider.notifier).prevStep();
    expect(c.read(onboardingNotifierProvider).currentStep, 0);
  });

  test('nextStep does not exceed totalSteps - 1', () {
    final c = _makeContainer();
    addTearDown(c.dispose);
    for (var i = 0; i < 10; i++) {
      c.read(onboardingNotifierProvider.notifier).nextStep();
    }
    expect(
      c.read(onboardingNotifierProvider).currentStep,
      c.read(onboardingNotifierProvider).totalSteps - 1,
    );
  });

  test('setLocale updates selectedLocale', () {
    final c = _makeContainer();
    addTearDown(c.dispose);
    c.read(onboardingNotifierProvider.notifier).setLocale('en');
    expect(c.read(onboardingNotifierProvider).selectedLocale, 'en');
  });

  test('saveProfileAndContinue with empty nickname sets error and does not advance', () async {
    final repo = _MockOnboardingRepo();
    final c = _makeContainer(onboardingRepo: repo);
    addTearDown(c.dispose);

    c.read(onboardingNotifierProvider.notifier).setNickname('');
    await c.read(onboardingNotifierProvider.notifier).saveProfileAndContinue();

    expect(c.read(onboardingNotifierProvider).error, 'nickname_required');
    expect(c.read(onboardingNotifierProvider).currentStep, 0);
    verifyNever(() => repo.saveProfile(
          uid: any(named: 'uid'),
          nickname: any(named: 'nickname'),
          phoneVisible: any(named: 'phoneVisible'),
          locale: any(named: 'locale'),
        ));
  });

  test('saveProfileAndContinue with nickname > 30 chars sets error', () async {
    final repo = _MockOnboardingRepo();
    final c = _makeContainer(onboardingRepo: repo);
    addTearDown(c.dispose);

    c
        .read(onboardingNotifierProvider.notifier)
        .setNickname('A' * 31);
    await c.read(onboardingNotifierProvider.notifier).saveProfileAndContinue();

    expect(c.read(onboardingNotifierProvider).error, 'nickname_max_length');
  });

  test('createHome with empty name sets error', () async {
    final homeRepo = _MockHomeCreationRepo();
    final c = _makeContainer(homeRepo: homeRepo);
    addTearDown(c.dispose);

    final result = await c
        .read(onboardingNotifierProvider.notifier)
        .createHome('', null);

    expect(result, isNull);
    expect(c.read(onboardingNotifierProvider).error, 'home_name_required');
    verifyNever(() => homeRepo.createHome(name: any(named: 'name')));
  });

  test('createHome with name > 40 chars sets error', () async {
    final homeRepo = _MockHomeCreationRepo();
    final c = _makeContainer(homeRepo: homeRepo);
    addTearDown(c.dispose);

    final result = await c
        .read(onboardingNotifierProvider.notifier)
        .createHome('A' * 41, null);

    expect(result, isNull);
    expect(c.read(onboardingNotifierProvider).error, 'home_name_max_length');
  });

  test('joinHome with code length != 6 sets error', () async {
    final homeRepo = _MockHomeCreationRepo();
    final c = _makeContainer(homeRepo: homeRepo);
    addTearDown(c.dispose);

    final result =
        await c.read(onboardingNotifierProvider.notifier).joinHome('AB12');

    expect(result, isNull);
    expect(c.read(onboardingNotifierProvider).error, 'invite_code_length');
    verifyNever(() => homeRepo.joinHome(code: any(named: 'code')));
  });

  test('createHome sets no_slots error on NoHomeSlotsException', () async {
    final homeRepo = _MockHomeCreationRepo();
    when(() => homeRepo.createHome(name: any(named: 'name'), emoji: any(named: 'emoji')))
        .thenThrow(const NoHomeSlotsException());

    final c = _makeContainer(homeRepo: homeRepo);
    addTearDown(c.dispose);

    final result = await c
        .read(onboardingNotifierProvider.notifier)
        .createHome('Mi Casa', null);

    expect(result, isNull);
    expect(c.read(onboardingNotifierProvider).error, 'no_slots');
  });

  test('joinHome sets invalid_invite on InvalidInviteCodeException', () async {
    final homeRepo = _MockHomeCreationRepo();
    when(() => homeRepo.joinHome(code: any(named: 'code')))
        .thenThrow(const InvalidInviteCodeException());

    final c = _makeContainer(homeRepo: homeRepo);
    addTearDown(c.dispose);

    final result =
        await c.read(onboardingNotifierProvider.notifier).joinHome('ABC123');

    expect(result, isNull);
    expect(c.read(onboardingNotifierProvider).error, 'invalid_invite');
  });

  test('joinHome sets expired_invite on ExpiredInviteCodeException', () async {
    final homeRepo = _MockHomeCreationRepo();
    when(() => homeRepo.joinHome(code: any(named: 'code')))
        .thenThrow(const ExpiredInviteCodeException());

    final c = _makeContainer(homeRepo: homeRepo);
    addTearDown(c.dispose);

    final result =
        await c.read(onboardingNotifierProvider.notifier).joinHome('XYZ789');

    expect(result, isNull);
    expect(c.read(onboardingNotifierProvider).error, 'expired_invite');
  });
}
```

- [ ] **Step 2: Run unit tests**

```bash
flutter test test/unit/features/onboarding/onboarding_provider_test.dart -v
```
Expected: all tests PASS.

- [ ] **Step 3: Commit**

```bash
git add test/unit/features/onboarding/
git commit -m "test(onboarding): add OnboardingNotifier unit tests"
```

---

## Task 15: Unit tests — HomeCreationRepository

**Files:**
- Create: `test/unit/features/onboarding/home_creation_repository_test.dart`

- [ ] **Step 1: Create home_creation_repository_test.dart**

```dart
// test/unit/features/onboarding/home_creation_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/onboarding/domain/home_creation_repository.dart';
import 'package:toka/core/errors/exceptions.dart';

class _FakeHomeCreationRepo extends Fake implements HomeCreationRepository {
  String? _homeId;
  Object? _error;

  _FakeHomeCreationRepo.returns(this._homeId);
  _FakeHomeCreationRepo.throws(this._error);

  @override
  Future<String> createHome({required String name, String? emoji}) async {
    if (_error != null) throw _error!;
    return _homeId!;
  }

  @override
  Future<String> joinHome({required String code}) async {
    if (_error != null) throw _error!;
    return _homeId!;
  }
}

void main() {
  test('createHome returns homeId', () async {
    final repo = _FakeHomeCreationRepo.returns('home-123');
    final result = await repo.createHome(name: 'Casa Test');
    expect(result, 'home-123');
  });

  test('createHome throws NoHomeSlotsException when no slots', () async {
    final repo = _FakeHomeCreationRepo.throws(const NoHomeSlotsException());
    await expectLater(
      () => repo.createHome(name: 'Casa'),
      throwsA(isA<NoHomeSlotsException>()),
    );
  });

  test('joinHome with invalid code throws InvalidInviteCodeException', () async {
    final repo =
        _FakeHomeCreationRepo.throws(const InvalidInviteCodeException());
    await expectLater(
      () => repo.joinHome(code: 'XXXXXX'),
      throwsA(isA<InvalidInviteCodeException>()),
    );
  });

  test('joinHome with expired code throws ExpiredInviteCodeException', () async {
    final repo =
        _FakeHomeCreationRepo.throws(const ExpiredInviteCodeException());
    await expectLater(
      () => repo.joinHome(code: 'EXPIRD'),
      throwsA(isA<ExpiredInviteCodeException>()),
    );
  });
}
```

- [ ] **Step 2: Run tests**

```bash
flutter test test/unit/features/onboarding/home_creation_repository_test.dart -v
```
Expected: all PASS.

- [ ] **Step 3: Commit**

```bash
git add test/unit/features/onboarding/home_creation_repository_test.dart
git commit -m "test(onboarding): add HomeCreationRepository unit tests"
```

---

## Task 16: Integration tests — home creation (fake_cloud_firestore)

**Files:**
- Create: `test/integration/features/onboarding/home_creation_test.dart`

- [ ] **Step 1: Create home_creation_test.dart**

Note: Because `HomeCreationRepositoryImpl` depends on `FirebaseFunctions` (which cannot be easily faked in unit tests), these integration tests use a mock/fake at the repository layer. The Firestore logic for `joinHome` (querying invitations) is tested with `fake_cloud_firestore`.

```dart
// test/integration/features/onboarding/home_creation_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:toka/features/onboarding/data/home_creation_repository_impl.dart';
import 'package:toka/core/errors/exceptions.dart';

class _MockFunctions extends Mock implements FirebaseFunctions {}
class _MockCallable extends Mock implements HttpsCallable {}
class _MockResult extends Mock implements HttpsCallableResult<Map<String, dynamic>> {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late _MockFunctions mockFunctions;
  late _MockCallable mockCallable;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockFunctions = _MockFunctions();
    mockCallable = _MockCallable();

    when(() => mockFunctions.httpsCallable(any())).thenReturn(mockCallable);
  });

  group('createHome', () {
    test('returns homeId from Cloud Function response', () async {
      final mockResult = _MockResult();
      when(() => mockResult.data).thenReturn({'homeId': 'new-home-id'});
      when(() => mockCallable.call<Map<String, dynamic>>(any()))
          .thenAnswer((_) async => mockResult);

      final repo = HomeCreationRepositoryImpl(
        functions: mockFunctions,
        firestore: fakeFirestore,
      );

      final homeId = await repo.createHome(name: 'Casa Test');
      expect(homeId, 'new-home-id');
    });

    test('throws NoHomeSlotsException on resource-exhausted', () async {
      when(() => mockCallable.call<Map<String, dynamic>>(any())).thenThrow(
        FirebaseFunctionsException(message: 'no slots', code: 'resource-exhausted'),
      );

      final repo = HomeCreationRepositoryImpl(
        functions: mockFunctions,
        firestore: fakeFirestore,
      );

      await expectLater(
        () => repo.createHome(name: 'Casa'),
        throwsA(isA<NoHomeSlotsException>()),
      );
    });
  });

  group('joinHome', () {
    test('throws InvalidInviteCodeException when no matching invitation', () async {
      final repo = HomeCreationRepositoryImpl(
        functions: mockFunctions,
        firestore: fakeFirestore,
      );

      await expectLater(
        () => repo.joinHome(code: 'XXXXXX'),
        throwsA(isA<InvalidInviteCodeException>()),
      );
    });

    test('throws ExpiredInviteCodeException when invitation is expired', () async {
      // Seed an expired invitation
      await fakeFirestore
          .collection('homes')
          .doc('home-1')
          .collection('invitations')
          .doc('inv-1')
          .set({
        'code': 'EXPIRD',
        'used': false,
        'expiresAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 1))),
      });

      final repo = HomeCreationRepositoryImpl(
        functions: mockFunctions,
        firestore: fakeFirestore,
      );

      await expectLater(
        () => repo.joinHome(code: 'EXPIRD'),
        throwsA(isA<ExpiredInviteCodeException>()),
      );
    });

    test('calls joinHome function and returns homeId on valid code', () async {
      // Seed a valid invitation
      await fakeFirestore
          .collection('homes')
          .doc('home-2')
          .collection('invitations')
          .doc('inv-2')
          .set({
        'code': 'VALID1',
        'used': false,
        'expiresAt': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 7))),
      });

      when(() => mockCallable.call<void>(any())).thenAnswer((_) async {});

      final repo = HomeCreationRepositoryImpl(
        functions: mockFunctions,
        firestore: fakeFirestore,
      );

      final homeId = await repo.joinHome(code: 'VALID1');
      expect(homeId, 'home-2');
    });
  });
}
```

Note: `fake_cloud_firestore` does not support `collectionGroup` queries natively in all versions. If `collectionGroup` is unsupported, the integration test for `joinHome` will use a direct collection path instead. Adjust if needed.

- [ ] **Step 2: Run integration tests**

```bash
flutter test test/integration/features/onboarding/home_creation_test.dart -v
```
Expected: all PASS. If `collectionGroup` is unsupported by `fake_cloud_firestore`, the valid-code test may fail — in that case, simplify `joinHome` to query `homes/{homeId}/invitations` directly (requires knowing homeId, which the invitation embed can supply).

- [ ] **Step 3: Commit**

```bash
git add test/integration/features/onboarding/
git commit -m "test(onboarding): add home_creation integration tests"
```

---

## Task 17: Integration tests — profile save

**Files:**
- Create: `test/integration/features/onboarding/profile_save_test.dart`

- [ ] **Step 1: Create profile_save_test.dart**

```dart
// test/integration/features/onboarding/profile_save_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/onboarding/data/onboarding_repository_impl.dart';

class _MockStorage extends Mock implements FirebaseStorage {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late _MockStorage mockStorage;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockStorage = _MockStorage();
  });

  test('saveProfile writes nickname to users/{uid}', () async {
    final repo = OnboardingRepositoryImpl(
      firestore: fakeFirestore,
      storage: mockStorage,
    );

    await repo.saveProfile(
      uid: 'test-uid',
      nickname: 'Carlos',
      phoneVisible: false,
      locale: 'es',
    );

    final doc = await fakeFirestore.collection('users').doc('test-uid').get();
    expect(doc.data()?['nickname'], 'Carlos');
  });

  test('saveProfile writes locale to users/{uid}', () async {
    final repo = OnboardingRepositoryImpl(
      firestore: fakeFirestore,
      storage: mockStorage,
    );

    await repo.saveProfile(
      uid: 'test-uid',
      nickname: 'Ana',
      phoneVisible: false,
      locale: 'en',
    );

    final doc = await fakeFirestore.collection('users').doc('test-uid').get();
    expect(doc.data()?['locale'], 'en');
  });

  test('saveProfile with phoneVisible=true stores members visibility', () async {
    final repo = OnboardingRepositoryImpl(
      firestore: fakeFirestore,
      storage: mockStorage,
    );

    await repo.saveProfile(
      uid: 'uid-2',
      nickname: 'María',
      phoneNumber: '+34600000000',
      phoneVisible: true,
      locale: 'es',
    );

    final doc = await fakeFirestore.collection('users').doc('uid-2').get();
    expect(doc.data()?['phoneVisibility'], 'members');
    expect(doc.data()?['phoneNumber'], '+34600000000');
  });

  test('saveProfile without photo returns null photoUrl', () async {
    final repo = OnboardingRepositoryImpl(
      firestore: fakeFirestore,
      storage: mockStorage,
    );

    final photoUrl = await repo.saveProfile(
      uid: 'uid-3',
      nickname: 'Test',
      phoneVisible: false,
      locale: 'es',
    );

    expect(photoUrl, isNull);
  });
}
```

- [ ] **Step 2: Run tests**

```bash
flutter test test/integration/features/onboarding/profile_save_test.dart -v
```
Expected: all PASS.

- [ ] **Step 3: Commit**

```bash
git add test/integration/features/onboarding/profile_save_test.dart
git commit -m "test(onboarding): add profile_save integration tests"
```

---

## Task 18: UI tests — OnboardingFlowScreen

**Files:**
- Create: `test/ui/features/onboarding/onboarding_flow_test.dart`

- [ ] **Step 1: Create onboarding_flow_test.dart**

```dart
// test/ui/features/onboarding/onboarding_flow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/features/i18n/application/language_provider.dart';
import 'package:toka/features/i18n/domain/language.dart';
import 'package:toka/features/onboarding/application/onboarding_provider.dart';
import 'package:toka/features/onboarding/application/onboarding_state.dart';
import 'package:toka/features/onboarding/presentation/onboarding_flow_screen.dart';
import 'package:toka/l10n/app_localizations.dart';

GoRouter _fakeRouter() => GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
            path: '/onboarding',
            builder: (_, __) => const OnboardingFlowScreen()),
        GoRoute(path: '/home', builder: (_, __) => const Scaffold()),
      ],
    );

/// A fake OnboardingNotifier that starts at a fixed step.
class _FakeOnboardingNotifier extends OnboardingNotifier {
  _FakeOnboardingNotifier(this._initial);
  final OnboardingState _initial;

  @override
  OnboardingState build() => _initial;

  @override
  Future<void> loadSavedProgress() async {}
}

Widget _wrap({
  OnboardingState? state,
  List<Language> languages = const [],
}) {
  SharedPreferences.setMockInitialValues({'onboarding_completed': false});
  return ProviderScope(
    overrides: [
      onboardingNotifierProvider.overrideWith(
        () => _FakeOnboardingNotifier(
          state ?? const OnboardingState(),
        ),
      ),
      availableLanguagesProvider.overrideWith(
          (ref) => Future.value(languages)),
    ],
    child: MaterialApp.router(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      routerConfig: _fakeRouter(),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'onboarding_completed': false});
  });

  testWidgets('step 0 shows logo and start button', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('start_button')), findsOneWidget);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
  });

  testWidgets('step 1 shows language list (mocked)', (tester) async {
    const languages = [
      Language(
          code: 'es',
          name: 'Español',
          flag: '🇪🇸',
          arbKey: 'app_es',
          enabled: true,
          sortOrder: 1),
      Language(
          code: 'en',
          name: 'English',
          flag: '🇬🇧',
          arbKey: 'app_en',
          enabled: true,
          sortOrder: 2),
    ];
    await tester.pumpWidget(
      _wrap(state: const OnboardingState(currentStep: 1), languages: languages),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('language_list')), findsOneWidget);
    expect(find.text('🇪🇸  Español'), findsOneWidget);
  });

  testWidgets('step 2 shows profile form', (tester) async {
    await tester.pumpWidget(
      _wrap(state: const OnboardingState(currentStep: 2)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('nickname_field')), findsOneWidget);
    expect(find.byKey(const Key('phone_field')), findsOneWidget);
    expect(find.byKey(const Key('phone_visible_toggle')), findsOneWidget);
  });

  testWidgets('step 3 shows create and join options', (tester) async {
    await tester.pumpWidget(
      _wrap(state: const OnboardingState(currentStep: 3)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('create_home_card')), findsOneWidget);
    expect(find.byKey(const Key('join_home_card')), findsOneWidget);
  });

  testWidgets('progress bar reflects current step', (tester) async {
    await tester.pumpWidget(
      _wrap(state: const OnboardingState(currentStep: 2, totalSteps: 4)),
    );
    await tester.pumpAndSettle();

    final bar = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('onboarding_progress_bar')));
    expect(bar.value, closeTo(3 / 4, 0.01));
  });

  testWidgets('step 3 profile validates empty nickname', (tester) async {
    await tester.pumpWidget(
      _wrap(state: const OnboardingState(currentStep: 2)),
    );
    await tester.pumpAndSettle();

    // Tap next without filling nickname
    await tester.tap(find.byKey(const Key('next_button')));
    await tester.pumpAndSettle();

    expect(find.text('El apodo es obligatorio'), findsOneWidget);
  });

  testWidgets('golden: step 0 welcome', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(OnboardingFlowScreen),
      matchesGoldenFile('goldens/onboarding_step0_welcome.png'),
    );
  });

  testWidgets('golden: step 3 home choice', (tester) async {
    await tester.pumpWidget(
      _wrap(state: const OnboardingState(currentStep: 3)),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(OnboardingFlowScreen),
      matchesGoldenFile('goldens/onboarding_step3_home_choice.png'),
    );
  });
}
```

- [ ] **Step 2: Run UI tests (update goldens on first run)**

```bash
flutter test test/ui/features/onboarding/onboarding_flow_test.dart -v --update-goldens
```
Expected: all PASS, goldens created.

- [ ] **Step 3: Commit**

```bash
git add test/ui/features/onboarding/
git commit -m "test(onboarding): add OnboardingFlowScreen UI tests and goldens"
```

---

## Task 19: Run all tests + flutter analyze

- [ ] **Step 1: Run flutter analyze**

```bash
flutter analyze
```
Expected: no errors.

- [ ] **Step 2: Run all unit tests**

```bash
flutter test test/unit/ -v
```
Expected: all PASS.

- [ ] **Step 3: Run all integration tests**

```bash
flutter test test/integration/ -v
```
Expected: all PASS.

- [ ] **Step 4: Run all UI tests**

```bash
flutter test test/ui/ -v
```
Expected: all PASS.

- [ ] **Step 5: Final commit**

```bash
git add .
git commit -m "feat(spec-03): complete onboarding implementation — all tests passing"
```

---

## Pruebas manuales requeridas al terminar

1. **Flujo completo — crear hogar:**
   - Registrar cuenta nueva.
   - Completar 4 pasos del onboarding.
   - Paso 2: seleccionar "English" → verificar que el resto del onboarding continúa en inglés.
   - Paso 3: apodo "Carlos", sin foto.
   - Paso 4: "Crear un hogar" → nombre "Casa de prueba".
   - → Redirige a la pantalla principal del hogar.
   - Verificar en Firestore Emulator: `homes/` con el documento, `members/{uid}` con role `owner`.

2. **Flujo completo — unirse a hogar:**
   - Cuenta A crea hogar y genera código de invitación.
   - Cuenta B → onboarding → "Unirme a un hogar" → código → accede al hogar.

3. **Código de invitación inválido:**
   - Paso 4 → "Unirme" → código "XXXXXX" → mensaje de error visible.

4. **Reanudar onboarding:**
   - Completar pasos 0 y 1.
   - Cerrar la app.
   - Reabrir → debe continuar en el paso 2 con los datos guardados.

5. **Verificar foto de perfil:**
   - Paso 3: tocar avatar → seleccionar foto → aparece en el avatar.
   - Al completar, verificar en Firebase Storage: `users/{uid}/profile.jpg`.

6. **Límite de plazas:**
   - Crear hogar 1 → completar.
   - Crear hogar 2 desde ajustes.
   - Intentar hogar 3 → mensaje "sin plazas disponibles".
