import 'package:freezed_annotation/freezed_annotation.dart';

part 'gathering_vote_model.freezed.dart';
part 'gathering_vote_model.g.dart';

@freezed
class GatheringVoteModel with _$GatheringVoteModel {
  const factory GatheringVoteModel({
    required String id,
    @JsonKey(name: 'gathering_event_id') required String gatheringEventId,
    @JsonKey(name: 'option_id') required String optionId,
    @JsonKey(name: 'member_id') required String memberId,
    @JsonKey(name: 'voted_at') required DateTime votedAt,
  }) = _GatheringVoteModel;

  factory GatheringVoteModel.fromJson(Map<String, dynamic> json) =>
      _$GatheringVoteModelFromJson(json);
}
