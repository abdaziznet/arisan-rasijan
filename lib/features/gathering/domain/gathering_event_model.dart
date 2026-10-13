import 'package:freezed_annotation/freezed_annotation.dart';

part 'gathering_event_model.freezed.dart';
part 'gathering_event_model.g.dart';

@freezed
class GatheringEventModel with _$GatheringEventModel {
  const factory GatheringEventModel({
    required String id,
    required String title,
    @Default('voting') String status,
    @JsonKey(name: 'winning_option_id') String? winningOptionId,
    @JsonKey(name: 'event_date') DateTime? eventDate,
    @JsonKey(name: 'fund_used') @Default(0) double fundUsed,
    @JsonKey(name: 'created_by') required String createdBy,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'closed_at') DateTime? closedAt,
  }) = _GatheringEventModel;

  factory GatheringEventModel.fromJson(Map<String, dynamic> json) =>
      _$GatheringEventModelFromJson(json);
}
