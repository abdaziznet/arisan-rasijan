// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gathering_vote_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GatheringVoteModelImpl _$$GatheringVoteModelImplFromJson(
        Map<String, dynamic> json) =>
    _$GatheringVoteModelImpl(
      id: json['id'] as String,
      gatheringEventId: json['gathering_event_id'] as String,
      optionId: json['option_id'] as String,
      memberId: json['member_id'] as String,
      votedAt: DateTime.parse(json['voted_at'] as String),
    );

Map<String, dynamic> _$$GatheringVoteModelImplToJson(
        _$GatheringVoteModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'gathering_event_id': instance.gatheringEventId,
      'option_id': instance.optionId,
      'member_id': instance.memberId,
      'voted_at': instance.votedAt.toIso8601String(),
    };
