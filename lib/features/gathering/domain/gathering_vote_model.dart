import 'package:freezed_annotation/freezed_annotation.dart';

part 'gathering_vote_model.freezed.dart';
part 'gathering_vote_model.g.dart';

@freezed
class GatheringVoteModel with _$GatheringVoteModel {
  const factory GatheringVoteModel({
    required String id,
    required String gatheringEventId,
    required String optionId,
    required String memberId,
    @JsonKey(name: 'voted_at') required DateTime votedAt,
  }) = _GatheringVoteModel;

  factory GatheringVoteModel.fromJson(Map<String, dynamic> json) =>
      _$GatheringVoteModelFromJson(json);
}