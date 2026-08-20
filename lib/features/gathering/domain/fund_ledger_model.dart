import 'package:freezed_annotation/freezed_annotation.dart';

part 'fund_ledger_model.freezed.dart';
part 'fund_ledger_model.g.dart';

@freezed
class FundLedgerModel with _$FundLedgerModel {
  const factory FundLedgerModel({
    required String id,
    required String type,
    required double amount,
    String? periodId,
    String? gatheringEventId,
    String? description,
    required String createdBy,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _FundLedgerModel;

  factory FundLedgerModel.fromJson(Map<String, dynamic> json) =>
      _$FundLedgerModelFromJson(json);
}