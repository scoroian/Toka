import 'package:freezed_annotation/freezed_annotation.dart';

part 'language.freezed.dart';

@freezed
class Language with _$Language {
  const Language._();

  const factory Language({
    required String code,
    required String name,
    required String flag,
    required String arbKey,
    required bool enabled,
    required int sortOrder,
  }) = _Language;

  factory Language.fromFirestore(Map<String, dynamic> data) => Language(
        code: data['code'] as String,
        name: data['name'] as String,
        flag: data['flag'] as String,
        arbKey: data['arb_key'] as String,
        enabled: data['enabled'] as bool? ?? true,
        sortOrder: data['sort_order'] as int? ?? 99,
      );

  /// Idiomas base de Toka (es/en/ro). Se usan cuando la colección remota
  /// `languages` está vacía o cuando la lectura falla (sin red): el onboarding
  /// nunca debe quedarse sin idiomas que ofrecer.
  static const List<Language> defaults = [
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
    Language(
        code: 'ro',
        name: 'Română',
        flag: '🇷🇴',
        arbKey: 'app_ro',
        enabled: true,
        sortOrder: 3),
  ];
}
