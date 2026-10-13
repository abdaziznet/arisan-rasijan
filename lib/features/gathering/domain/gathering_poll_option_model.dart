import 'package:freezed_annotation/freezed_annotation.dart';

part 'gathering_poll_option_model.freezed.dart';
part 'gathering_poll_option_model.g.dart';

@freezed
class GatheringPollOptionModel with _$GatheringPollOptionModel {
  const factory GatheringPollOptionModel({
    required String id,
    @JsonKey(name: 'gathering_event_id') required String gatheringEventId,
    @JsonKey(name: 'option_label') required String optionLabel,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(0)
    int voteCount,
  }) = _GatheringPollOptionModel;

  factory GatheringPollOptionModel.fromJson(Map<String, dynamic> json) =>
      _$GatheringPollOptionModelFromJson(json);
}
