import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/language_repository_impl.dart';
import '../domain/language_repository.dart';
import '../domain/languages_result.dart';

part 'language_provider.g.dart';

@riverpod
LanguageRepository languageRepository(Ref ref) {
  return LanguageRepositoryImpl(firestore: FirebaseFirestore.instance);
}

@riverpod
Future<LanguagesResult> availableLanguages(Ref ref) {
  return ref.watch(languageRepositoryProvider).fetchAvailableLanguages();
}
