import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
const _kCompleted = 'onboarding_completed';

@Riverpod(keepAlive: true)
OnboardingRepository onboardingRepository(Ref ref) {
  return OnboardingRepositoryImpl(
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
  );
}

/// True if the user has already completed the onboarding flow.
/// Checks SharedPreferences first (fast path), then Firestore as fallback so
/// the flag survives app reinstalls and works across devices (Bug #onboarding-reinstall).
@Riverpod(keepAlive: true)
Future<bool> onboardingCompleted(Ref ref) async {
  // Fast path: SharedPreferences (works within the same install)
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_kCompleted) ?? false) return true;

  // Fallback: Firestore (survives reinstalls and works across devices)
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return false;

  final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  if (!doc.exists) return false;

  final data = doc.data()!;

  // Check explicit flag (written since this version)
  final flagSet = (data['onboardingCompleted'] as bool?) ?? false;
  if (flagSet) {
    await prefs.setBool(_kCompleted, true);
    return true;
  }

  // Proxy for users who completed onboarding before this flag was added:
  // a non-empty nickname means they went through the profile step.
  final nickname = (data['nickname'] as String?)?.trim() ?? '';
  if (nickname.isNotEmpty) {
    await prefs.setBool(_kCompleted, true);
    return true;
  }

  return false;
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

  /// Validates and saves profile data. Does not advance if nickname is empty.
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
      final homeId =
          await _homeRepo.joinHome(code: code.trim().toUpperCase());
      await _markCompleted();
      state = state.copyWith(isLoading: false, error: null);
      return homeId;
    } on InvalidInviteCodeException {
      state = state.copyWith(isLoading: false, error: 'invalid_invite');
      return null;
    } on ExpiredInviteCodeException {
      state = state.copyWith(isLoading: false, error: 'expired_invite');
      return null;
    } on FirebaseException catch (e) {
      final errorCode = switch (e.code) {
        'permission-denied' => 'permission_denied',
        'not-found' => 'invalid_invite',
        _ => 'unexpected_error',
      };
      state = state.copyWith(isLoading: false, error: errorCode);
      return null;
    } on SocketException {
      state = state.copyWith(isLoading: false, error: 'network_error');
      return null;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'unexpected_error');
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
    // Also persist in Firestore so the flag survives reinstalls and device changes
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'onboardingCompleted': true});
      } catch (_) {
        // Non-critical: SharedPreferences covers the current session;
        // the nickname proxy in onboardingCompleted() acts as backup.
      }
    }
  }
}
