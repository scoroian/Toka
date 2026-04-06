import 'package:freezed_annotation/freezed_annotation.dart';

part 'purchase_result.freezed.dart';

@freezed
class PurchaseResult with _$PurchaseResult {
  const factory PurchaseResult.success({required String chargeId}) = PurchaseResultSuccess;
  const factory PurchaseResult.alreadyOwned() = PurchaseResultAlreadyOwned;
  const factory PurchaseResult.cancelled() = PurchaseResultCancelled;
  const factory PurchaseResult.error({required String message}) = PurchaseResultError;
}
