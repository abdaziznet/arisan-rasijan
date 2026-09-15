import 'package:freezed_annotation/freezed_annotation.dart';

part 'fund_ledger_model.freezed.dart';
part 'fund_ledger_model.g.dart';

@freezed
class FundLedgerModel with _$FundLedgerModel {
  const factory FundLedgerModel({
    required String id,
    required String type,
    required double amount,
    @JsonKey(name: 'period_id') String? periodId,
    @JsonKey(name: 'gathering_event_id') String? gatheringEventId,
    String? description,
    @JsonKey(name: 'created_by') required String createdBy,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _FundLedgerModel;

  factory FundLedgerModel.fromJson(Map<String, dynamic> json) =>
      _$FundLedgerModelFromJson({
        ...json,
        // Supabase returns PostgreSQL column names in snake_case, while the
        // generated model currently expects Dart field names in camelCase.
        'periodId': json['period_id'],
        'gatheringEventId': json['gathering_event_id'],
        'createdBy': json['created_by'],
      });
}
