import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_limits.freezed.dart';

@freezed
class HomeLimits with _$HomeLimits {
  const factory HomeLimits({
    required int maxMembers,
  }) = _HomeLimits;
}
