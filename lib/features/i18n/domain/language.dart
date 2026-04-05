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
}
